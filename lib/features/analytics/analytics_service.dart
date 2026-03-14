import 'package:flutter/material.dart';
import '../../../data/models/milk_entry.dart';
import '../../../data/models/expense_entry.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  // 1. Daily Milk Trend (Last N days)
  // Ordered by Date ASC
  List<MilkEntry> getDailyTrend(List<MilkEntry> allRecords, {int days = 30}) {
    // Sort by date descending first to get latest
    final sorted = List<MilkEntry>.from(allRecords)
      ..sort((a, b) => b.date.compareTo(a.date));
    final taken = sorted.take(days).toList();
    // Return ASC for chart
    taken.sort((a, b) => a.date.compareTo(b.date));
    return taken;
  }

  // 2. Monthly Total Milk
  // Returns Map<String, double> where Key is "MMM" or "MMM-YY"
  Map<String, double> getMonthlyTotalMilk(List<MilkEntry> allRecords) {
    // Sort ASC
    final sorted = List<MilkEntry>.from(allRecords)
      ..sort((a, b) => a.date.compareTo(b.date));

    final Map<String, double> map = {};
    for (var r in sorted) {
      final key = DateFormat('MMM').format(r.date); // e.g., Jan
      // Simple aggregation by month name. For multi-year, use MMM-yy
      // User likely uses this year data mostly. Let's use MMM for simplicity or MMM-yy if needed.
      // Let's use MMM-yy to be safe.
      final keyFull = DateFormat('MMM yy').format(r.date);
      map[keyFull] = (map[keyFull] ?? 0) + r.totalYield;
    }
    return map;
  }

  // 3. Morning vs Evening (Total for all time or filtered)
  Map<String, double> getMorningVsEvening(List<MilkEntry> records) {
    double morning = 0;
    double evening = 0;
    for (var r in records) {
      morning += r.morningMilk;
      evening += r.eveningMilk;
    }
    return {'Morning': morning, 'Evening': evening};
  }

  // 4. Income vs Expense
  // Needs ephemeral price.
  // Map<Month, {Income, Expense}>
  // This is complex because we need to group both by month.
  Map<String, Map<String, double>> getIncomeVsExpenseMonthly(
    List<MilkEntry> milkRecords,
    List<ExpenseEntry> expenseRecords,
    double pricePerLiter,
  ) {
    // Keys: "MMM yy"
    // Values: {"Income": 100.0, "Expense": 50.0}

    final Map<String, Map<String, double>> result = {};

    // Process Milk
    for (var r in milkRecords) {
      final key = DateFormat('MMM yy').format(r.date);
      if (!result.containsKey(key)) {
        result[key] = {"Income": 0.0, "Expense": 0.0};
      }

      final actualPrice = r.pricePerLiter > 0 ? r.pricePerLiter : pricePerLiter;
      result[key]!['Income'] =
          (result[key]!['Income']!) + (r.totalYield * actualPrice);
    }

    // Process Expense
    for (var e in expenseRecords) {
      final key = DateFormat('MMM yy').format(e.date);
      if (!result.containsKey(key)) {
        result[key] = {"Income": 0.0, "Expense": 0.0};
      }

      result[key]!['Expense'] = (result[key]!['Expense']!) + e.amount;
    }

    return result;
  }
}
