import 'package:hive/hive.dart';
import '../models/milk_entry.dart';

class MilkRepository {
  static const String boxName = 'milk_records';

  Future<Box<MilkEntry>> get _box async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<MilkEntry>(boxName);
    }
    return await Hive.openBox<MilkEntry>(boxName);
  }

  Future<void> init() async {
    await _box;
  }

  Future<List<MilkEntry>> getAllRecords() async {
    final box = await _box;
    return box.values.toList();
  }

  // Returns true if updated
  Future<bool> saveRecord(MilkEntry entry) async {
    final box = await _box;
    final key = MilkEntry.getDateKey(entry.date);
    final exists = box.containsKey(key);
    if (exists) {
      // Merge with existing entry
      final old = box.get(key) as MilkEntry;
      final merged = MilkEntry(
        date: entry.date,
        morningMilk: entry.morningMilk != 0
            ? entry.morningMilk
            : old.morningMilk,
        eveningMilk: entry.eveningMilk != 0
            ? entry.eveningMilk
            : old.eveningMilk,
        createdAt: old.createdAt,
        notes: entry.notes.isNotEmpty ? entry.notes : old.notes,
        pricePerLiter: old.pricePerLiter > 0 ? old.pricePerLiter : entry.pricePerLiter,
      );
      await box.put(key, merged);
    } else {
      await box.put(key, entry);
    }
    return exists; // true if it was an update
  }

  Future<void> updateRecordPrice(MilkEntry old, double newPrice) async {
    final box = await _box;
    final key = MilkEntry.getDateKey(old.date);
    if (!box.containsKey(key)) return;
    final merged = MilkEntry(
      date: old.date,
      morningMilk: old.morningMilk,
      eveningMilk: old.eveningMilk,
      createdAt: old.createdAt,
      notes: old.notes,
      pricePerLiter: newPrice,
    );
    await box.put(key, merged);
  }

  Future<void> deleteRecord(DateTime date) async {
    final box = await _box;
    final key = MilkEntry.getDateKey(date);
    await box.delete(key);
  }
}
