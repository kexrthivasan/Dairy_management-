import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../logic/services/drive_service.dart';
import '../../logic/services/auth_service.dart';
import '../../logic/providers/dairy_provider.dart';
import '../../features/expense/expense_provider.dart';
import '../../logic/services/background_service.dart';
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
    // Only fetch daily since we just use that for 'last backup time'
    final lastManual = await _driveService.getLastBackupTime(
      BackupFrequency.daily,
    );

    // We get the stored frequency from a custom pref or deduce it.
    // For simplicity, we assume if daily is enabled, frequency was daily.
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
    });
  }

  String _formatBackupTime(DateTime? time) {
    if (time == null) return 'Never';
    return DateFormat('MMM dd yyyy, h:mm a').format(time);
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
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome, ${authService.userName ?? authService.userEmail}!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login cancelled or failed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
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
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? Cloud backup will be disabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      if (result == 'Success' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual backup successful!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBackupSettings();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red),
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
    if (_autoBackupEnabled) {
      await _handleAutoBackupToggle(true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildAccountCard(authService),
              const SizedBox(height: 32),

              // ─── Chat Backup Section ───
              _buildSectionHeader('Chat Backup', Icons.cloud_sync),
              const SizedBox(height: 12),

              // Manual Backup Card
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manual Backup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last backup: ${_lastManualBackupTime ?? 'Never'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleManualBackup,
                          icon: _loadingAction == 'backup_manual'
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: const Text(
                            'Backup Now',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Automatic Backup Card
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        value: _autoBackupEnabled,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: _handleAutoBackupToggle,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: _autoBackupEnabled
                            ? Column(
                                children: [
                                  const Divider(height: 1),
                                  RadioListTile<BackupFrequency>(
                                    title: const Text(
                                      'Daily',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    value: BackupFrequency.daily,
                                    groupValue: _selectedFrequency,
                                    onChanged: _handleFrequencyChange,
                                  ),
                                  RadioListTile<BackupFrequency>(
                                    title: const Text(
                                      'Weekly',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    value: BackupFrequency.weekly,
                                    groupValue: _selectedFrequency,
                                    onChanged: _handleFrequencyChange,
                                  ),
                                  RadioListTile<BackupFrequency>(
                                    title: const Text(
                                      'Monthly',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    value: BackupFrequency.monthly,
                                    groupValue: _selectedFrequency,
                                    onChanged: _handleFrequencyChange,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ─── App Info ───
              Center(
                child: Column(
                  children: [
                    const Text(
                      'App Version',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _appVersion,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AuthService authService) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black12,
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authService.userEmail ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
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
