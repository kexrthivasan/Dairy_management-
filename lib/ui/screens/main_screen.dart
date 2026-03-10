import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_dairy_manager/ui/screens/home_screen.dart';
import 'package:home_dairy_manager/ui/screens/expense_screen.dart';
import 'package:home_dairy_manager/features/analytics/screens/analytics_screen.dart';
import 'package:home_dairy_manager/ui/screens/monthly_summary_screen.dart';
import 'package:home_dairy_manager/ui/screens/settings_screen.dart';
import 'package:home_dairy_manager/logic/services/drive_service.dart';
import 'package:home_dairy_manager/logic/services/auth_service.dart';
import 'package:home_dairy_manager/logic/services/backup_scheduler.dart';

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
    _initBackupScheduler();
  }

  void _initBackupScheduler() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final driveService = DriveService(authService);
    _backupScheduler = BackupScheduler(driveService, authService);
    _backupScheduler!.start();
  }

  @override
  void dispose() {
    _backupScheduler?.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExpenseScreen(),
    const AnalyticsScreen(),
    const MonthlySummaryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            selectedItemColor: primary,
            unselectedItemColor: isDark ? Colors.white38 : Colors.grey,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 28),
                activeIcon: Icon(Icons.home, size: 28),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined, size: 28),
                activeIcon: Icon(Icons.account_balance_wallet, size: 28),
                label: 'Expense',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined, size: 28),
                activeIcon: Icon(Icons.bar_chart, size: 28),
                label: 'Charts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined, size: 28),
                activeIcon: Icon(Icons.calendar_month, size: 28),
                label: 'Summary',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined, size: 28),
                activeIcon: Icon(Icons.settings, size: 28),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
