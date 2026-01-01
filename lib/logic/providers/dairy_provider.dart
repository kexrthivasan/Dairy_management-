import 'package:flutter/material.dart';
import '../../data/models/milk_entry.dart';
import '../../data/repositories/milk_repository.dart';

class DairyProvider extends ChangeNotifier {
  final MilkRepository _repository = MilkRepository();

  // Master list of all records
  List<MilkEntry> _allRecords = [];

  // Filtered list displayed in UI
  List<MilkEntry> _filteredRecords = [];
  List<MilkEntry> get records => _filteredRecords;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Price per liter (manual set)
  double _pricePerLiter = 30.0;
  double get pricePerLiter => _pricePerLiter;
  void setPricePerLiter(double price) {
    _pricePerLiter = price;
    notifyListeners();
  }

  Future<void> init() async {
    await _repository.init();
    await loadRecords();
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    _allRecords = await _repository.getAllRecords();

    // UI Requirement: Sort by DATE DESCENDING
    _allRecords.sort((a, b) => b.date.compareTo(a.date));

    // Initially show all
    _applyFilter((_) => true);

    _isLoading = false;
    notifyListeners();
  }

  // Returns true if it was an UPDATE, false if NEW
  Future<bool> addOrUpdateRecord(
    DateTime date,
    double morning,
    double evening,
    String notes,
  ) async {
    final newRecord = MilkEntry(
      date: date,
      morningMilk: morning,
      eveningMilk: evening,
      createdAt: DateTime.now(),
      notes: notes,
    );

    final isUpdate = await _repository.saveRecord(newRecord);

    await loadRecords(); // Reload to refresh UI and re-apply default filter (all)
    return isUpdate;
  }

  Future<void> deleteRecord(DateTime date) async {
    await _repository.deleteRecord(date);
    await loadRecords();
  }

  // --- Filtering Logic ---

  void _applyFilter(bool Function(MilkEntry) filterFn) {
    _filteredRecords = _allRecords.where(filterFn).toList();
    // Maintain DESC sort
    _filteredRecords.sort((a, b) => b.date.compareTo(a.date));
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
    // Start <= date <= End
    // Adjust start to beginning of day and end to end of day if raw dates passed
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);

    _applyFilter((r) {
      return r.date.isAfter(s.subtract(const Duration(seconds: 1))) &&
          r.date.isBefore(e.add(const Duration(seconds: 1)));
    });
    notifyListeners();
  }

  void filterByWeek(DateTime anyDateInWeek) {
    // Determine the start of the week (e.g., Monday)
    // weekday 1 = Mon, 7 = Sun
    final startOfWeek = anyDateInWeek.subtract(
      Duration(days: anyDateInWeek.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    filterByDateRange(startOfWeek, endOfWeek);
  }

  void filterByMonth(DateTime anyDateInMonth) {
    final start = DateTime(anyDateInMonth.year, anyDateInMonth.month, 1);
    final lastDay = DateTime(anyDateInMonth.year, anyDateInMonth.month + 1, 0);
    filterByDateRange(start, lastDay);
  }

  // --- Calculations ---

  /// Calculates total milk volume for the currently filtered list.
  /// Iterates through filtered records and sums up totalYield.
  double get totalMilkVolume {
    return _filteredRecords.fold(0.0, (sum, record) => sum + record.totalYield);
  }

  /// Calculates Average Milk Per Day
  /// Formula: Total Milk / Number of Days with Records
  /// Note: This is based on *recorded* days, not calendar days in range,
  /// because 0 entries usually mean "no data" rather than "0 liters" in this context unless explicit 0 is entered.
  double get averageMilkPerDay {
    if (_filteredRecords.isEmpty) return 0.0;
    return totalMilkVolume / _filteredRecords.length;
  }

  /// Calculates Total Income based on dynamic price.
  /// Price is ephemeral (passed by user in UI) and not stored.
  /// Formula: Total Milk Volume * Price Per Liter
  double calculateTotalIncome(double pricePerLiter) {
    return totalMilkVolume * pricePerLiter;
  }

  // --- Exports ---

  // For PDF: Sorted ASCENDING
  List<MilkEntry> get recordsForPdf {
    final list = List<MilkEntry>.from(
      _filteredRecords,
    ); // Export currently filtered view? Or all? Usually filtered.
    // Making it filtered allows users to print "Monthly Reports".
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Returns a list of records for the given range without modifying the provider state.
  Future<List<MilkEntry>> getRecordsForRange(
    DateTime start,
    DateTime end,
  ) async {
    // Start <= date <= End
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final filtered = _allRecords.where((r) {
      return r.date.isAfter(s.subtract(const Duration(seconds: 1))) &&
          r.date.isBefore(e.add(const Duration(seconds: 1)));
    }).toList();

    filtered.sort((a, b) => a.date.compareTo(b.date)); // Ascending for report?
    return filtered;
  }
}
