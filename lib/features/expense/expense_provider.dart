import 'package:flutter/material.dart';
import '../../data/models/expense_entry.dart';
import '../../data/repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();

  // All loaded entries (unsorted or raw)
  List<ExpenseEntry> _allEntries = [];

  // Currently visible entries (filtered & sorted)
  List<ExpenseEntry> _filteredEntries = [];
  List<ExpenseEntry> get entries => _filteredEntries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await _repository.init();
    await loadEntries();
    _isInitialized = true;
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    _allEntries = await _repository.getAllEntries();

    // Default: Show all, Sorted DESC
    _applyFilter((_) => true);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(
    DateTime date,
    ExpenseCategory category,
    double amount,
    String? notes,
  ) async {
    final newEntry = ExpenseEntry(
      date: date,
      category: category,
      amount: amount,
      notes: notes,
    );
    await _repository.addEntry(newEntry);
    await loadEntries();
  }

  Future<void> updateExpense(
    ExpenseEntry entry,
    DateTime date,
    ExpenseCategory category,
    double amount,
    String? notes,
  ) async {
    entry.date = date;
    entry.category = category;
    entry.amount = amount;
    entry.notes = notes;
    await entry.save();
    await loadEntries();
  }

  Future<void> deleteExpense(ExpenseEntry entry) async {
    await _repository.deleteEntry(entry);
    await loadEntries(); // Refresh list
  }

  // --- Filtering Logic ---

  // Helper to apply filter and sort
  void _applyFilter(bool Function(ExpenseEntry) filterFn) {
    _filteredEntries = _allEntries.where(filterFn).toList();
    _sortEntries();
  }

  void _sortEntries() {
    // Sort by Date DESCENDING
    _filteredEntries.sort((a, b) => b.date.compareTo(a.date));
  }

  void resetFilter() {
    _applyFilter((_) => true);
    notifyListeners();
  }

  void filterBySingleDate(DateTime date) {
    _applyFilter(
      (e) =>
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day,
    );
    notifyListeners();
  }

  void filterByDateRange(DateTime start, DateTime end) {
    // Ensure "start" is generated_at_beginning_of_day and "end" is generated_at_end_of_day logic if needed.
    // Assuming inputs are clear dates.
    // Start <= date <= End
    _applyFilter((e) {
      return e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(end.add(const Duration(seconds: 1)));
    });
    notifyListeners();
  }

  void filterByWeek(DateTime anyDateInWeek) {
    // Find start of week (e.g., Monday)
    // Subtract weekday-1
    final startOfWeek = anyDateInWeek.subtract(
      Duration(days: anyDateInWeek.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Normalize to dates only to avoid time issues?
    // Usually DateTime compare handles it, but let's be safe visually.
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = DateTime(
      endOfWeek.year,
      endOfWeek.month,
      endOfWeek.day,
      23,
      59,
      59,
    );

    filterByDateRange(start, end);
  }

  void filterByMonth(DateTime anyDateInMonth) {
    final start = DateTime(anyDateInMonth.year, anyDateInMonth.month, 1);
    final lastDay = DateTime(
      anyDateInMonth.year,
      anyDateInMonth.month + 1,
      0,
    ); // Day 0 of next month = last day of current
    final end = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);

    filterByDateRange(start, end);
  }

  double get totalExpense {
    return _filteredEntries.fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<ExpenseCategory, double> get totalByCategory {
    final Map<ExpenseCategory, double> totals = {};
    for (var entry in _filteredEntries) {
      totals.update(
        entry.category,
        (value) => value + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }
    return totals;
  }

  void filterByCategory(ExpenseCategory category) {
    _applyFilter((e) => e.category == category);
    notifyListeners();
  }

  /// Returns a list of records for the given range without modifying the provider state.
  Future<List<ExpenseEntry>> getRecordsForRange(
    DateTime start,
    DateTime end,
  ) async {
    // Start <= date <= End
    final filtered = _allEntries.where((e) {
      return e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }
}
