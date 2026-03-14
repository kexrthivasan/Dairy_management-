import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/drive_service.dart';
import '../../services/auth_service.dart';
import '../../presentation/providers/theme_provider.dart';
import '../../services/background_service.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late DriveService _driveService;

  bool _autoBackupEnabled = false;
  BackupFrequency _selectedFrequency = BackupFrequency.daily;
  String? _lastManualBackupTime;
  String? _lastRestoreTime;
  String _appVersion = 'v1.0.0';

  bool _isLoading = false;
  String? _loadingAction;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _driveService = DriveService(authService);
    _loadBackupSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final config = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${config.version}';
      });
    } catch (e) {
      debugPrint('Error loading app version: $e');
    }
  }

  Future<void> _loadBackupSettings() async {
    final lastManual = await _driveService.getLastBackupTime(
      BackupFrequency.daily,
    );
    final daily = await _driveService.isBackupEnabled(BackupFrequency.daily);
    final weekly = await _driveService.isBackupEnabled(BackupFrequency.weekly);
    final monthly = await _driveService.isBackupEnabled(
      BackupFrequency.monthly,
    );

    BackupFrequency freq = BackupFrequency.daily;
    if (monthly) freq = BackupFrequency.monthly;
    if (weekly) freq = BackupFrequency.weekly;
    if (daily) freq = BackupFrequency.daily;

    final isAutoEnabled = daily || weekly || monthly;

    if (!mounted) return;
    setState(() {
      _autoBackupEnabled = isAutoEnabled;
      _selectedFrequency = freq;
      _lastManualBackupTime = _formatBackupTime(lastManual);
      _lastRestoreTime = null; // will be loaded below
    });

    final lastRestore = await _driveService.getLastRestoreTime();
    if (!mounted) return;
    setState(() {
      _lastRestoreTime = _formatBackupTime(lastRestore);
    });
  }

  String _formatBackupTime(DateTime? time) {
    if (time == null) return 'Never';
    return DateFormat('dd MMMM yyyy — h:mm a').format(time);
  }

  Future<void> _handleLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _isLoading = true;
      _loadingAction = 'login';
    });
    try {
      final success = await authService.signIn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Welcome, ${authService.userName ?? authService.userEmail}!'
                  : 'Login cancelled or failed.',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
          _loadingAction = null;
        });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? Cloud backup will be disabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _isLoading = true;
      _loadingAction = 'logout';
    });
    try {
      await authService.signOut();
      await BackgroundService.updateBackupTask(false, null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingAction = null;
        });
        _loadBackupSettings();
      }
    }
  }

  Future<void> _handleManualBackup() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first to backup.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _loadingAction = 'backup_manual';
    });
    try {
      final result = await _driveService.backupHive(
        frequency: BackupFrequency.daily,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'Success' ? 'Manual backup successful!' : result,
          ),
          backgroundColor: result == 'Success' ? Colors.green : Colors.red,
        ),
      );
      if (result == 'Success') _loadBackupSettings();
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
          _loadingAction = null;
        });
    }
  }

  Future<void> _handleRestoreBackup() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first to restore.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Restore Backup'),
        content: const Text(
          'This will overwrite your current local data with the latest backup from Google Drive.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _loadingAction = 'restore';
    });
    try {
      final result = await _driveService.restoreHive(
        frequency: BackupFrequency.daily,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'Success'
                ? 'Restore successful! Please restart the app.'
                : result,
          ),
          backgroundColor: result == 'Success' ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      if (result == 'Success') _loadBackupSettings();
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
          _loadingAction = null;
        });
    }
  }

  Future<void> _handleAutoBackupToggle(bool enabled) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (enabled && !authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first to enable automatic backups.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _autoBackupEnabled = enabled;
    });
    await _driveService.setBackupEnabled(
      BackupFrequency.daily,
      enabled && _selectedFrequency == BackupFrequency.daily,
    );
    await _driveService.setBackupEnabled(
      BackupFrequency.weekly,
      enabled && _selectedFrequency == BackupFrequency.weekly,
    );
    await _driveService.setBackupEnabled(
      BackupFrequency.monthly,
      enabled && _selectedFrequency == BackupFrequency.monthly,
    );
    await BackgroundService.updateBackupTask(enabled, _selectedFrequency);
  }

  Future<void> _handleFrequencyChange(BackupFrequency? frequency) async {
    if (frequency == null) return;
    setState(() {
      _selectedFrequency = frequency;
    });
    if (_autoBackupEnabled) await _handleAutoBackupToggle(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // ─── Account Section ───
              _buildSectionHeader('Account', Icons.person),
              const SizedBox(height: 12),
              _buildAccountCard(authService, isDark),
              const SizedBox(height: 28),

              // ─── Theme Section ───
              _buildSectionHeader('Appearance', Icons.palette_outlined),
              const SizedBox(height: 12),
              _buildSettingsCard(
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      secondary: Icon(
                        themeProvider.isDark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: theme.primaryColor,
                        size: 28,
                      ),
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        themeProvider.isDark
                            ? 'Switch to Light Mode'
                            : 'Switch to Dark Mode',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      value: themeProvider.isDark,
                      onChanged: themeProvider.toggleTheme,
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // ─── Chat Backup Section ───
              _buildSectionHeader('Cloud Backup', Icons.cloud_sync),
              const SizedBox(height: 12),

              // Manual Backup + Restore Card
              _buildSettingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Backup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last Automatic Backup\n${_lastManualBackupTime ?? 'Never'}',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last Restore\n${_lastRestoreTime ?? 'Never'}',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _loadingButton(
                              onPressed: _isLoading
                                  ? null
                                  : _handleManualBackup,
                              isLoading: _loadingAction == 'backup_manual',
                              icon: Icons.cloud_upload,
                              label: 'Backup Now',
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _loadingButton(
                              onPressed: _isLoading
                                  ? null
                                  : _handleRestoreBackup,
                              isLoading: _loadingAction == 'restore',
                              icon: Icons.cloud_download,
                              label: 'Restore',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Automatic Backup Card
              _buildSettingsCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: const Text(
                        'Enable Automatic Backup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Backs up automatically when connected to internet',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      value: _autoBackupEnabled,
                      onChanged: _handleAutoBackupToggle,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: _autoBackupEnabled
                          ? Column(
                              children: [
                                const Divider(height: 1),
                                _frequencyRadio('Daily', BackupFrequency.daily),
                                _frequencyRadio(
                                  'Weekly',
                                  BackupFrequency.weekly,
                                ),
                                _frequencyRadio(
                                  'Monthly',
                                  BackupFrequency.monthly,
                                ),
                                const SizedBox(height: 8),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ─── App Version ───
              Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[400], size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'App Version',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _appVersion,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _frequencyRadio(String label, BackupFrequency value) {
    return RadioListTile<BackupFrequency>(
      title: Text(label, style: const TextStyle(fontSize: 16)),
      value: value,
      groupValue: _selectedFrequency,
      onChanged: _handleFrequencyChange,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Widget _loadingButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 26, color: Theme.of(context).primaryColor),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }

  Widget _buildAccountCard(AuthService authService, bool isDark) {
    return _buildSettingsCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: authService.isLoggedIn
            ? Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: authService.userPhotoUrl != null
                        ? NetworkImage(authService.userPhotoUrl!)
                        : null,
                    child: authService.userPhotoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.green.shade700,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authService.userName ?? 'User',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authService.userEmail ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 28,
                    icon: _loadingAction == 'logout'
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.logout, color: Colors.red.shade400),
                    tooltip: 'Logout',
                    onPressed: _isLoading ? null : _handleLogout,
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(Icons.account_circle, size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to enable cloud backup',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: _loadingAction == 'login'
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
