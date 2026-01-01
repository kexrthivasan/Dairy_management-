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
  // createdAt is used for stable ordering when dates match (though rare/disallowed by logic),
  // and preserves the original insertion time for audit purposes.

  @HiveField(4)
  final String notes;

  MilkEntry({
    required this.date,
    required this.morningMilk,
    required this.eveningMilk,
    required this.createdAt,
    this.notes = '',
  });

  double get totalYield => morningMilk + eveningMilk;

  static String getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
