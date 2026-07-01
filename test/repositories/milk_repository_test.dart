import 'package:flutter_test/flutter_test.dart';
import 'package:home_dairy_manager/data/repositories/milk_repository.dart';
import 'package:home_dairy_manager/data/models/milk_entry.dart';

void main() {
  group('MilkRepository Test Templates', () {
    test('Generate key mapping matches standard date keys', () {
      final date = DateTime(2026, 6, 1);
      final key = MilkEntry.getDateKey(date);
      expect(key, '2026-06-01');
    });

    test('Verify repository boxName config matches database definition', () {
      expect(MilkRepository.boxName, 'milk_records');
    });
  });
}
