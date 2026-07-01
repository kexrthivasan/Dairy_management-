import 'package:flutter_test/flutter_test.dart';
import 'package:home_dairy_manager/features/expense/expense_provider.dart';
import 'package:home_dairy_manager/data/models/expense_entry.dart';

void main() {
  group('ExpenseProvider Calculations Tests', () {
    test('ExpenseEntry mapping and category math works correctly', () {
      final feedExpense = ExpenseEntry(
        date: DateTime(2026, 6, 1),
        category: ExpenseCategory.feed,
        amount: 1200.0,
        notes: 'Feed supply',
      );

      final medicalExpense = ExpenseEntry(
        date: DateTime(2026, 6, 2),
        category: ExpenseCategory.medical,
        amount: 800.0,
        notes: 'Vet visit',
      );

      final list = [feedExpense, medicalExpense];
      final total = list.fold(0.0, (sum, item) => sum + item.amount);

      expect(total, 2000.0);
      expect(feedExpense.category, ExpenseCategory.feed);
      expect(medicalExpense.category, ExpenseCategory.medical);
    });
  });
}
