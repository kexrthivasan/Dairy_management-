import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_dairy_manager/presentation/screens/home_screen.dart';
import 'package:home_dairy_manager/presentation/screens/reports_screen.dart';
import 'package:home_dairy_manager/features/analytics/screens/analytics_screen.dart';
import 'package:home_dairy_manager/presentation/screens/monthly_summary_screen.dart';
import 'package:home_dairy_manager/presentation/screens/settings_screen.dart';
import 'package:home_dairy_manager/services/drive_service.dart';
import 'package:home_dairy_manager/services/auth_service.dart';
import 'package:home_dairy_manager/services/backup_scheduler.dart';
import 'package:home_dairy_manager/presentation/screens/lazy_indexed_stack.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  BackupScheduler? _backupScheduler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBackupScheduler();
    });
  }

  void _initBackupScheduler() {
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final driveService = DriveService(authService);
    _backupScheduler = BackupScheduler(driveService, authService);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _backupScheduler!.start();
    });
  }

  @override
  void dispose() {
    _backupScheduler?.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const ReportsScreen(),
    const AnalyticsScreen(),
    const MonthlySummaryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return Scaffold(
      body: LazyIndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1D1B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            backgroundColor: isDark ? const Color(0xFF1B1D1B) : Colors.white,
            indicatorColor: primary.withOpacity(0.12),
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
                selectedIcon: Icon(Icons.home, color: primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.assessment_outlined,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
                selectedIcon: Icon(Icons.assessment, color: primary),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.bar_chart_outlined,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
                selectedIcon: Icon(Icons.bar_chart, color: primary),
                label: 'Charts',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
                selectedIcon: Icon(Icons.calendar_month, color: primary),
                label: 'Summary',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.settings_outlined,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
                selectedIcon: Icon(Icons.settings, color: primary),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
