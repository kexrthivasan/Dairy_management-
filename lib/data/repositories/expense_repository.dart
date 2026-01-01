import 'package:hive/hive.dart';
import '../models/expense_entry.dart';

class ExpenseRepository {
  static const String boxName = 'expense_entries';

  Future<Box<ExpenseEntry>> get _box async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<ExpenseEntry>(boxName);
    }
    return await Hive.openBox<ExpenseEntry>(boxName);
  }

  Future<void> init() async {
    await _box;
  }

  Future<List<ExpenseEntry>> getAllEntries() async {
    final box = await _box;
    return box.values.toList();
  }

  Future<void> addEntry(ExpenseEntry entry) async {
    final box = await _box;
    await box.add(entry);
  }

  Future<void> deleteEntry(ExpenseEntry entry) async {
    // Since ExpenseEntry extends HiveObject, we can call delete on it directly
    // if it's in a box.
    if (entry.isInBox) {
      await entry.delete();
    }
  }

  Future<void> updateEntry(ExpenseEntry entry) async {
    if (entry.isInBox) {
      await entry.save();
    }
  }
}
