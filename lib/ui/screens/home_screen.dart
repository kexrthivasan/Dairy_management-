import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/dairy_provider.dart';
import '../widgets/milk_entry_card.dart';
import '../widgets/footer_widget.dart';
import '../widgets/animated_cow_header.dart';

import '../../features/expense/expense_provider.dart';
import 'add_record_screen.dart';
import 'expense_screen.dart';

import 'full_report_screen.dart';

import '../../features/analytics/screens/analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();
    // Problem 2: Move Hive.openBox() calls to splash/home screen using async microtask
    // Also init() makes sure we don't double-init if not needed.
    Future.microtask(() {
      if (mounted) {
        context.read<DairyProvider>().init();
        context.read<ExpenseProvider>().init();
      }
    });

    // Delay animation/heavy widget loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showAnimation = true;
        });
      }
    });
  }

  void _showPriceDialog(BuildContext context) {
    final dairyProvider = Provider.of<DairyProvider>(context, listen: false);
    final TextEditingController priceController = TextEditingController(
      text: dairyProvider.pricePerLiter.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Set Price per Liter'),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price',
              hintText: 'Enter price per liter',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final newPrice = double.tryParse(priceController.text);
                if (newPrice != null && newPrice >= 0) {
                  dairyProvider.setPricePerLiter(newPrice);
                  Navigator.of(dialogContext).pop();
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid price.'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Dairy Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money, size: 32),
            tooltip: 'Set Price per Liter',
            onPressed: () => _showPriceDialog(context),
          ),
        ],
      ),
      body: Consumer<DairyProvider>(
        builder: (context, provider, child) {
          final expenseProvider = Provider.of<ExpenseProvider>(context);

          // We don't block the WHOLE UI if loading, just maybe Show loading if empty?
          // Requirement: "App must show first screen immediately"
          // So even if loading, show structure.

          // Calculate Monthly Totals via Providers (ensures we check ALL records, ignoring filters)
          final now = DateTime.now();
          final totalLiters = provider.getMonthlyTotal(now);
          final totalIncome = totalLiters * provider.pricePerLiter;
          final totalExpense = expenseProvider.getMonthlyTotal(now);

          return ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              // 1. Animated Cow Header (Lazy Loaded)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_showAnimation)
                      const AnimatedCowHeader()
                    else
                      const SizedBox(height: 150, width: 150),
                    const SizedBox(height: 10),
                    const Text(
                      "Welcome!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Summary Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          const BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.green.shade100,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: _SummaryItem(
                              label: "Milk (L)",
                              value: totalLiters.toStringAsFixed(3),
                              icon: Icons.water_drop,
                              color: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: "Income",
                              value: "₹${totalIncome.toStringAsFixed(0)}",
                              icon: Icons.currency_rupee,
                              color: Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: "Expense",
                              value: "₹${totalExpense.toStringAsFixed(0)}",
                              icon: Icons.money_off,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Quick Actions (Grid of 4 Buttons)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _BigButton(
                            icon: Icons.water_drop,
                            label: "Add Milk",
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddRecordScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _BigButton(
                            icon: Icons.money_off,
                            label: "Expenses",
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _BigButton(
                            icon: Icons.analytics,
                            label: "Analytics",
                            color: Colors.purple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnalyticsScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _BigButton(
                            icon: Icons.picture_as_pdf,
                            label: "Report",
                            color: Colors.green,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FullReportScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Recent Records Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Recent Records",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              // 4. List
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.records.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      "No records found.",
                      style: TextStyle(color: Colors.grey),
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

              const SizedBox(height: 20),
              const AppFooter(),
            ],
          );
        },
      ),
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
        title: const Text('Delete Record?'),
        content: const Text(
          'Are you sure you want to delete this record?',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRecord(date);
              Navigator.pop(ctx);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color.withOpacity(0.8),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
