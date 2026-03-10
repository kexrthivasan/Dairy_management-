import 'package:hive/hive.dart';

part 'milk_entry.g.dart';

@HiveType(typeId: 0)
class MilkEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double morningMilk;

  @HiveField(2)
  final double eveningMilk;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String notes;

  /// Price per liter at the time of entry.
  /// Defaults to 0.0 for old records (backward compatible).
  @HiveField(5)
  final double pricePerLiter;

  MilkEntry({
    required this.date,
    required this.morningMilk,
    required this.eveningMilk,
    required this.createdAt,
    this.notes = '',
    this.pricePerLiter = 0.0,
  });

  double get totalYield => morningMilk + eveningMilk;

  double get totalIncome => totalYield * pricePerLiter;

  static String getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
