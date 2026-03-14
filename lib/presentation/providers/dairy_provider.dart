import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/milk_entry.dart';
import '../../data/repositories/milk_repository.dart';
import '../services/background_service.dart';

class DairyProvider extends ChangeNotifier {
  final MilkRepository _repository = MilkRepository();

  // Master list of all records
  List<MilkEntry> _allRecords = [];
  List<MilkEntry> get allRecords => _allRecords;

  // Filtered list displayed in UI
  List<MilkEntry> _filteredRecords = [];
  List<MilkEntry> get records => _filteredRecords;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Price per liter (manual set) – persisted to SharedPreferences
  double _pricePerLiter = 30.0;
  double get pricePerLiter => _pricePerLiter;

  Future<void> _loadPrice() async {
    final prefs = await SharedPreferences.getInstance();
    _pricePerLiter = prefs.getDouble('price_per_liter') ?? 30.0;
    notifyListeners();
  }

  Future<void> setPricePerLiter(double newPrice) async {
    final now = DateTime.now();
    // The "boundary" is the first day of the current month.
    // Records BEFORE this month → keep their price (or lock 0-price records to old price).
    // Records IN this month or later → get the new price.
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);

    bool anyUpdated = false;
    for (int i = 0; i < _allRecords.length; i++) {
      final r = _allRecords[i];
      final recordFirstOfMonth = DateTime(r.date.year, r.date.month, 1);

      if (recordFirstOfMonth.isBefore(firstDayOfCurrentMonth)) {
        // Historical month: lock to old price if it was 0 (never explicitly set)
        if (r.pricePerLiter == 0) {
          await _repository.updateRecordPrice(r, _pricePerLiter);
          anyUpdated = true;
        }
        // Otherwise leave historical prices untouched
      } else {
        // Current month or future: apply new price
        if (r.pricePerLiter != newPrice) {
          await _repository.updateRecordPrice(r, newPrice);
          anyUpdated = true;
        }
      }
    }

    _pricePerLiter = newPrice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('price_per_liter', newPrice);

    if (anyUpdated) {
      await loadRecords(); // Reload to reflect updated prices everywhere
    } else {
      notifyListeners();
    }
  }

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await _repository.init();
    await _loadPrice();
    await loadRecords();
    _isInitialized = true;
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
    _updateReminders();
  }

  void _updateReminders() {
    final now = DateTime.now();
    bool hasToday = _allRecords.any(
      (r) =>
          r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day,
    );
    BackgroundService.scheduleMilkReminders(hasToday);
  }

  // Returns true if it was an UPDATE, false if NEW
  Future<bool> addOrUpdateRecord(
    DateTime date,
    double morning,
    double evening,
    String notes,
  ) async {
    // Determine the correct price for this record's month.
    // If there are already records in that month with an explicit price, use that price.
    // Otherwise fall back to the current global price.
    final double priceForMonth = _resolvePriceForMonth(date);

    final newRecord = MilkEntry(
      date: date,
      morningMilk: morning,
      eveningMilk: evening,
      createdAt: DateTime.now(),
      notes: notes,
      pricePerLiter: priceForMonth,
    );

    final isUpdate = await _repository.saveRecord(newRecord);
    await loadRecords();
    return isUpdate;
  }

  /// Returns the price that should be used for records in the same month as [date].
  /// Checks existing records for that month first, then falls back to current price.
  double _resolvePriceForMonth(DateTime date) {
    final sameMonthRecords = _allRecords.where(
      (r) => r.date.year == date.year && r.date.month == date.month && r.pricePerLiter > 0,
    );
    if (sameMonthRecords.isNotEmpty) {
      return sameMonthRecords.first.pricePerLiter;
    }
    return _pricePerLiter;
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

  /// Calculates Total Income using pricePerLiter stored in each record.
  /// If a record has pricePerLiter == 0 (old records), fallback to current price.
  double calculateTotalIncome(double fallbackPricePerLiter) {
    return _filteredRecords.fold(0.0, (sum, r) {
      final price = r.pricePerLiter > 0
          ? r.pricePerLiter
          : fallbackPricePerLiter;
      return sum + r.totalYield * price;
    });
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

  /// Calculates total milk for a specific month using ALL records (ignoring current filter).
  double getMonthlyTotal(DateTime date) {
    return _allRecords
        .where((r) => r.date.year == date.year && r.date.month == date.month)
        .fold(0.0, (sum, r) => sum + r.totalYield);
  }

  /// Calculates total income for a month using per-record price (fallback to current price for old records).
  double getMonthlyIncome(DateTime date) {
    return _allRecords
        .where((r) => r.date.year == date.year && r.date.month == date.month)
        .fold(0.0, (sum, r) {
          final price = r.pricePerLiter > 0 ? r.pricePerLiter : _pricePerLiter;
          return sum + r.totalYield * price;
        });
  }
}
