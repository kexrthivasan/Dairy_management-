import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../features/expense/expense_provider.dart';
import '../../data/models/expense_entry.dart';
import '../widgets/footer_widget.dart';

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Column(
        children: [
          // Filters
          _FilterBar(),
          // List
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading)
                  return const Center(child: CircularProgressIndicator());

                if (provider.entries.isEmpty) {
                  return const Center(
                    child: Text(
                      "No expenses found.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.entries.length,
                  itemBuilder: (context, index) {
                    final entry = provider.entries[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: Icon(
                            _getIcon(entry.category),
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          entry.category.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${DateFormat('MMM dd').format(entry.date)} - ${entry.notes ?? ''}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          "- Rs.${entry.amount.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        onTap: () => _showEditDialog(context, entry),
                        onLongPress: () =>
                            _confirmDelete(context, provider, entry),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const AppFooter(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        label: const Text('Add Expense'),
        icon: const Icon(Icons.money_off),
        backgroundColor: Colors.redAccent,
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
        return Icons.rice_bowl; // Use a suitable icon
      case ExpenseCategory.others:
        return Icons.category;
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              provider.deleteExpense(entry);
              Navigator.pop(ctx);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ExpenseEntry entry) {
    final amountCtrl = TextEditingController(text: entry.amount.toString());
    final notesCtrl = TextEditingController(text: entry.notes);
    ExpenseCategory selectedCat = entry.category;
    DateTime selectedDate = entry.date;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Expense"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount (Rs)",
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ExpenseCategory>(
                      value: selectedCat,
                      items: ExpenseCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedCat = v!),
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        "Date: ${DateFormat('dd MMM').format(selectedDate)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => selectedDate = d);
                      },
                    ),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: "Notes"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text);
                    if (amt == null) return;

                    Provider.of<ExpenseProvider>(
                      context,
                      listen: false,
                    ).updateExpense(
                      entry,
                      selectedDate,
                      selectedCat,
                      amt,
                      notesCtrl.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("UPDATE"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    ExpenseCategory selectedCat = ExpenseCategory.feed;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("New Expense"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount (Rs)",
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ExpenseCategory>(
                      value: selectedCat,
                      items: ExpenseCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedCat = v!),
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        "Date: ${DateFormat('dd MMM').format(selectedDate)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => selectedDate = d);
                      },
                    ),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: "Notes"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text);
                    if (amt == null) return;

                    Provider.of<ExpenseProvider>(
                      context,
                      listen: false,
                    ).addExpense(
                      selectedDate,
                      selectedCat,
                      amt,
                      notesCtrl.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("SAVE"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simple filter buttons
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: "All",
              onTap: () => Provider.of<ExpenseProvider>(
                context,
                listen: false,
              ).resetFilter(),
            ),
            _FilterChip(
              label: "This Week",
              onTap: () => Provider.of<ExpenseProvider>(
                context,
                listen: false,
              ).filterByWeek(DateTime.now()),
            ),
            _FilterChip(
              label: "This Month",
              onTap: () => Provider.of<ExpenseProvider>(
                context,
                listen: false,
              ).filterByMonth(DateTime.now()),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }
}
