import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/dairy_provider.dart';
import '../../logic/services/auth_service.dart';
import '../widgets/milk_entry_card.dart';
import '../widgets/footer_widget.dart';

import '../../features/expense/expense_provider.dart';
import 'add_record_screen.dart';
import 'expense_screen.dart';
import 'full_report_screen.dart';
import 'monthly_summary_screen.dart';
import 'settings_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAnimation = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<DairyProvider>().init();
        context.read<ExpenseProvider>().init();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showAnimation = true);
    });
  }

  void _showPriceDialog(BuildContext context) {
    final dairyProvider = Provider.of<DairyProvider>(context, listen: false);
    final controller = TextEditingController(
      text: dairyProvider.pricePerLiter.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.currency_rupee,
                  color: Colors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Set Milk Price'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Price per Litre (₹)',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'New milk price will apply to future milk entries only. Existing records will not be changed.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Update Price'),
              onPressed: () {
                final newPrice = double.tryParse(controller.text);
                if (newPrice != null && newPrice >= 0) {
                  dairyProvider.setPricePerLiter(newPrice);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Price updated to ₹ ${newPrice.toStringAsFixed(2)} / Litre',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid price.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      drawer: _buildDrawer(context, isDark, theme),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Dairy Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.currency_rupee, size: 26),
            tooltip: 'Set Price per Liter',
            onPressed: () => _showPriceDialog(context),
          ),
        ],
      ),
      body: Consumer<DairyProvider>(
        builder: (context, provider, child) {
          final expenseProvider = Provider.of<ExpenseProvider>(context);
          final now = DateTime.now();
          final totalLiters = provider.getMonthlyTotal(now);
          final totalIncome = provider.getMonthlyIncome(now);
          final totalExpense = expenseProvider.getMonthlyTotal(now);

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // ─── Header Banner ───
              Stack(
                children: [
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          authService.isLoggedIn
                              ? (authService.userName ?? 'Farmer')
                              : 'Farmer',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Summary Card
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: _showAnimation ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _SummaryItem(
                                  label: 'Milk (L)',
                                  value: totalLiters.toStringAsFixed(1),
                                  icon: Icons.water_drop_rounded,
                                  color: Colors.blueAccent,
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                ),
                                _SummaryItem(
                                  label: 'Income',
                                  value: '₹${totalIncome.toStringAsFixed(0)}',
                                  icon: Icons.account_balance_wallet_rounded,
                                  color: Colors.green,
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                ),
                                _SummaryItem(
                                  label: 'Expense',
                                  value: '₹${totalExpense.toStringAsFixed(0)}',
                                  icon: Icons.money_off_rounded,
                                  color: Colors.redAccent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ─── Quick Actions ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.add_circle,
                            label: 'Add Milk',
                            subtitle: 'New entry',
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddRecordScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.receipt_long,
                            label: 'Expenses',
                            subtitle: 'Track costs',
                            color: Colors.redAccent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExpenseScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.insights_rounded,
                            label: 'Analytics',
                            subtitle: 'View charts',
                            color: Colors.purple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnalyticsScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.picture_as_pdf_rounded,
                            label: 'Reports',
                            subtitle: 'Export data',
                            color: Colors.green,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FullReportScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ─── Recent Records ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Records',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (provider.records.isNotEmpty)
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FullReportScreen(),
                          ),
                        ),
                        child: const Text('View All'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.records.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No milk records yet.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddRecordScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Your First Entry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...provider.records.take(5).map((record) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: MilkEntryCard(
                      record: record,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddRecordScreen(recordToEdit: record),
                        ),
                      ),
                      onDelete: () =>
                          _confirmDelete(context, provider, record.date),
                    ),
                  );
                }),

              const SizedBox(height: 40),
              const AppFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark, ThemeData theme) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              color: theme.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage:
                        authService.isLoggedIn &&
                            authService.userPhotoUrl != null
                        ? NetworkImage(authService.userPhotoUrl!)
                        : null,
                    child:
                        (!authService.isLoggedIn ||
                            authService.userPhotoUrl == null)
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    authService.isLoggedIn
                        ? (authService.userName ?? 'Farmer')
                        : 'Farmer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (authService.isLoggedIn && authService.userEmail != null)
                    Text(
                      authService.userEmail!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    context,
                    Icons.home,
                    'Home',
                    () => Navigator.pop(context),
                  ),
                  _drawerItem(context, Icons.receipt_long, 'Expenses', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExpenseScreen()),
                    );
                  }),
                  _drawerItem(
                    context,
                    Icons.picture_as_pdf_rounded,
                    'Reports',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FullReportScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.calendar_month,
                    'Monthly Summary',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MonthlySummaryScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(context, Icons.insights_rounded, 'Analytics', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnalyticsScreen(),
                      ),
                    );
                  }),
                  const Divider(),
                  _drawerItem(context, Icons.settings, 'Settings', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  }),
                  _drawerItem(context, Icons.info_outline, 'About App', () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'Dairy Manager',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          '© Keerthivasan – All rights reserved',
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  void _confirmDelete(
    BuildContext context,
    DairyProvider provider,
    DateTime date,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record?'),
        content: const Text(
          'Are you sure you want to delete this record?\nThis action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              provider.deleteRecord(date);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shadowColor: Colors.black.withOpacity(0.05),
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
