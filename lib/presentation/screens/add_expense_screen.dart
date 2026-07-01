import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_entry.dart';
import '../../features/expense/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseEntry? expenseToEdit;

  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  ExpenseCategory? _selectedCategory;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final expense = widget.expenseToEdit;
    _selectedDate = expense?.date ?? DateTime.now();
    _selectedCategory = expense?.category ?? ExpenseCategory.feed;
    _amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    _notesController = TextEditingController(text: expense?.notes ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an expense category.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final notes = _notesController.text.trim();

      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      final isEditing = widget.expenseToEdit != null;

      if (isEditing) {
        await provider.updateExpense(
          widget.expenseToEdit!,
          _selectedDate,
          _selectedCategory!,
          amount,
          notes.isEmpty ? null : notes,
        );
      } else {
        await provider.addExpense(
          _selectedDate,
          _selectedCategory!,
          amount,
          notes.isEmpty ? null : notes,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);

      final message = isEditing
          ? "Expense updated successfully!"
          : "Expense added successfully!";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontSize: 16)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expenseToEdit != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Picker Box
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF151815) : Colors.grey.shade50,
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date of Expense',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(_selectedDate),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.calendar_today, size: 24, color: theme.primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              DropdownButtonFormField<ExpenseCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Expense Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ExpenseCategory.values.map((cat) {
                  String display;
                  switch (cat) {
                    case ExpenseCategory.feed:
                      display = 'Feed';
                      break;
                    case ExpenseCategory.medical:
                      display = 'Medical';
                      break;
                    case ExpenseCategory.rice:
                      display = 'Rice';
                      break;
                    case ExpenseCategory.others:
                      display = 'Other';
                      break;
                  }
                  return DropdownMenuItem<ExpenseCategory>(
                    value: cat,
                    child: Text(display),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
                validator: (val) => val == null ? 'Category is required' : null,
              ),
              const SizedBox(height: 20),

              // Amount Input (Large visual style like Add Milk)
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: const TextStyle(fontSize: 16),
                  prefixIcon: const Icon(Icons.currency_rupee, size: 28),
                  hintText: '0.00',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  final amt = double.tryParse(value);
                  if (amt == null) {
                    return 'Invalid amount';
                  }
                  if (amt <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Notes Input (Optional)
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 40),

              // Buttons: Save & Cancel
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: theme.primaryColor),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saveForm,
                      child: const Text(
                        'SAVE EXPENSE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
