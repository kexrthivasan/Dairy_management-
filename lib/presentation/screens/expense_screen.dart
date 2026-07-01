import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../features/expense/expense_provider.dart';
import '../../data/models/expense_entry.dart';
import 'add_expense_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: Column(
        children: [
          // Redesigned Filters Bar
          _buildFilterBar(),

          // Summary Expense Period Card
          Consumer<ExpenseProvider>(
            builder: (context, provider, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF3E0A0A), const Color(0xFF6B1111)]
                        : [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(isDark ? 0.2 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expenses ($_selectedFilter)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${provider.totalExpense.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.red.shade700).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.trending_down,
                        size: 32,
                        color: isDark ? Colors.white : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Redesigned List
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.money_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No expenses found.",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: provider.entries.length,
                  itemBuilder: (context, index) {
                    final entry = provider.entries[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.05 : 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(entry.category),
                            color: Colors.redAccent,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          _getCategoryName(entry.category),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          "${DateFormat('MMM dd, yyyy').format(entry.date)}${entry.notes != null && entry.notes!.isNotEmpty ? ' — ${entry.notes}' : ''}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "- ₹${entry.amount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _confirmDelete(context, provider, entry),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddExpenseScreen(expenseToEdit: entry),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddExpenseScreen(),
            ),
          );
        },
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: "All",
            isSelected: _selectedFilter == 'All',
            onTap: () {
              setState(() => _selectedFilter = 'All');
              Provider.of<ExpenseProvider>(context, listen: false).resetFilter();
            },
          ),
          _FilterChip(
            label: "This Week",
            isSelected: _selectedFilter == 'This Week',
            onTap: () {
              setState(() => _selectedFilter = 'This Week');
              Provider.of<ExpenseProvider>(context, listen: false).filterByWeek(DateTime.now());
            },
          ),
          _FilterChip(
            label: "This Month",
            isSelected: _selectedFilter == 'This Month',
            onTap: () {
              setState(() => _selectedFilter = 'This Month');
              Provider.of<ExpenseProvider>(context, listen: false).filterByMonth(DateTime.now());
            },
          ),
        ],
      ),
    );
  }

  IconData _getIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.feed:
        return Icons.grass;
      case ExpenseCategory.medical:
        return Icons.medical_services;
      case ExpenseCategory.rice:
        return Icons.rice_bowl;
      case ExpenseCategory.others:
        return Icons.category;
    }
  }

  String _getCategoryName(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.feed:
        return 'Feed';
      case ExpenseCategory.medical:
        return 'Medical';
      case ExpenseCategory.rice:
        return 'Rice';
      case ExpenseCategory.others:
        return 'Other';
    }
  }

  void _confirmDelete(
    BuildContext context,
    ExpenseProvider provider,
    ExpenseEntry entry,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Expense?"),
        content: const Text("Are you sure you want to delete this expense record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              provider.deleteExpense(entry);
              Navigator.pop(ctx);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.redAccent,
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade800),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Colors.redAccent
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}
