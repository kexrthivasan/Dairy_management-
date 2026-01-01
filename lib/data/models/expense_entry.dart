import 'package:hive/hive.dart';

part 'expense_entry.g.dart';

@HiveType(typeId: 2)
enum ExpenseCategory {
  @HiveField(0)
  feed,
  @HiveField(1)
  medical,
  @HiveField(2)
  rice,
  @HiveField(3)
  others,
}

@HiveType(typeId: 1)
class ExpenseEntry extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  ExpenseCategory category;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String? notes;

  ExpenseEntry({
    required this.date,
    required this.category,
    required this.amount,
    this.notes,
  });
}
