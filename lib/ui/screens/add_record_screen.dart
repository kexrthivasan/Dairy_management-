import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/milk_entry.dart';
import '../../logic/providers/dairy_provider.dart';

class AddRecordScreen extends StatefulWidget {
  final MilkEntry? recordToEdit;

  const AddRecordScreen({super.key, this.recordToEdit});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TextEditingController _morningController;
  late TextEditingController _eveningController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing, otherwise default to today
    final record = widget.recordToEdit;
    _selectedDate = record?.date ?? DateTime.now();
    _morningController = TextEditingController(
      text: record?.morningMilk.toString() ?? '',
    );
    _eveningController = TextEditingController(
      text: record?.eveningMilk.toString() ?? '',
    );
    _notesController = TextEditingController(text: record?.notes ?? '');
  }

  @override
  void dispose() {
    _morningController.dispose();
    _eveningController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Use standard current time
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
      final morning = double.tryParse(_morningController.text) ?? 0.0;
      final evening = double.tryParse(_eveningController.text) ?? 0.0;
      final notes = _notesController.text;

      final provider = Provider.of<DairyProvider>(context, listen: false);

      // Save logic
      bool isUpdate = await provider.addOrUpdateRecord(
        _selectedDate,
        morning,
        evening,
        notes,
      );

      if (!mounted) return;

      Navigator.pop(context);

      String message = "Record added successfully!";
      if (isUpdate) {
        message =
            "Entry for this date already exists. Data updated successfully.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontSize: 16)),
          backgroundColor: isUpdate ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recordToEdit != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Milk Record' : 'Add Milk Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: theme.textTheme.headlineSmall,
                      ),
                      const Icon(Icons.calendar_today, size: 30),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Inputs
              _buildLargeInput(
                controller: _morningController,
                label: 'Morning Milk (Liters)',
                icon: Icons.wb_sunny_outlined,
              ),
              const SizedBox(height: 16),
              _buildLargeInput(
                controller: _eveningController,
                label: 'Evening Milk (Liters)',
                icon: Icons.nightlight_round,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text('SAVE RECORD'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 18),
        prefixIcon: Icon(icon, size: 30),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          // Allow 0 handling? Maybe warning?
          // Requirement doesn't strictly say it's required, but implies entry.
          // We can assume 0 is valid, but empty might mean "forgot".
          // Let's allow empty to mean 0.0 effectively in code, but here we can just pass.
          return null;
        }
        if (double.tryParse(value) == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }
}
