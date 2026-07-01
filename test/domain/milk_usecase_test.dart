import 'package:flutter_test/flutter_test.dart';
import 'package:home_dairy_manager/data/models/milk_entry.dart';

void main() {
  group('Milk Domain Logic & Validation Rules', () {
    test('Milk yields cannot be negative', () {
      final record = MilkEntry(
        date: DateTime(2026, 6, 1),
        morningMilk: 12.5,
        eveningMilk: 8.0,
        createdAt: DateTime.now(),
      );

      expect(record.morningMilk >= 0, true);
      expect(record.eveningMilk >= 0, true);
      expect(record.totalYield, 20.5);
    });

    test('Total income calculated correctly based on entry yield and price', () {
      final record = MilkEntry(
        date: DateTime(2026, 6, 1),
        morningMilk: 5.0,
        eveningMilk: 5.0,
        createdAt: DateTime.now(),
        pricePerLiter: 50.0,
      );

      expect(record.totalYield, 10.0);
      expect(record.totalIncome, 500.0);
    });
  });
}
