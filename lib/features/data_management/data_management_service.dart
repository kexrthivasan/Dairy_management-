import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/milk_entry.dart';
import '../../data/models/expense_entry.dart';

class DataManagementService {
  /// Export Milk Data to CSV
  Future<void> exportMilkData(List<MilkEntry> records) async {
    List<List<dynamic>> rows = [
      ["Date", "Morning (L)", "Evening (L)", "Notes"],
    ];

    for (var r in records) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(r.date),
        r.morningMilk,
        r.eveningMilk,
        r.notes ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    await _saveAndShareFile(csv, "milk_data.csv");
  }

  /// Export Expense Data to CSV
  Future<void> exportExpenseData(List<ExpenseEntry> records) async {
    List<List<dynamic>> rows = [
      ["Date", "Category", "Amount (Rs)", "Notes"],
    ];

    for (var r in records) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(r.date),
        r.category.name,
        r.amount,
        r.notes ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    await _saveAndShareFile(csv, "expense_data.csv");
  }

  Future<void> _saveAndShareFile(String content, String fileName) async {
    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'text/csv',
        name: fileName,
      );
      await Share.shareXFiles([xFile], text: 'Exported Data: $fileName');
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    await file.writeAsString(content);

    await Share.shareXFiles([
      XFile(path),
    ], text: 'Here is your exported data: $fileName');
  }

  /// Helper to clean string values (remove currency symbols like ₹, Rs, commas)
  double _cleanNumber(String value) {
    // Remove non-numeric characters except dot
    // Also remove common currency symbols specifically if needed, but regex [^0-9.] matches too much?
    // User might validly have negative numbers? Yes.
    // Allow 0-9, ., -
    String cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Import Milk Data from CSV
  /// Returns a list of entries to be UPSERTED into the database.
  Future<List<MilkEntry>> pickAndParseMilk() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, // Important for Web
    );

    if (result != null) {
      String csvContent;
      if (kIsWeb) {
        csvContent = utf8.decode(result.files.single.bytes!);
      } else {
        final file = File(result.files.single.path!);
        csvContent = await file.readAsString();
      }

      List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
      // Remove Header
      if (rows.isNotEmpty) rows.removeAt(0);

      List<MilkEntry> entries = [];
      for (var row in rows) {
        // Expected: Date (yyyy-MM-dd), Morning, Evening, Notes
        try {
          // Row might have less columns or empty strings
          if (row.length < 3) continue;

          final dateStr = row[0].toString();
          final morning = _cleanNumber(row[1].toString());
          final evening = _cleanNumber(row[2].toString());
          String? notes = row.length > 3 ? row[3].toString() : null;

          final date = DateFormat('yyyy-MM-dd').parse(dateStr);

          entries.add(
            MilkEntry(
              date: date,
              morningMilk: morning,
              eveningMilk: evening,
              createdAt: DateTime.now(),
              notes: notes ?? '',
            ),
          );
        } catch (e) {
          debugPrint("Error parsing row: $row -> $e");
        }
      }
      return entries;
    }
    return [];
  }

  /// Import Expense Data from CSV
  Future<List<ExpenseEntry>> pickAndParseExpenses() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null) {
      String csvContent;
      if (kIsWeb) {
        csvContent = utf8.decode(result.files.single.bytes!);
      } else {
        final file = File(result.files.single.path!);
        csvContent = await file.readAsString();
      }

      List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
      if (rows.isNotEmpty) rows.removeAt(0);

      List<ExpenseEntry> entries = [];
      for (var row in rows) {
        // Expected: Date, Category, Amount, Notes
        try {
          if (row.length < 3) continue;

          final dateStr = row[0].toString();
          final catStr = row[1].toString().toLowerCase();
          final amount = _cleanNumber(row[2].toString());
          String? notes = row.length > 3 ? row[3].toString() : null;

          final date = DateFormat('yyyy-MM-dd').parse(dateStr);

          // Map Category
          ExpenseCategory cat = ExpenseCategory.others; // Default
          if (catStr.contains('feed'))
            cat = ExpenseCategory.feed;
          else if (catStr.contains('medic') || catStr.contains('doct'))
            cat = ExpenseCategory.medical;
          else if (catStr.contains('rice'))
            cat = ExpenseCategory.rice;

          entries.add(
            ExpenseEntry(
              date: date,
              category: cat,
              amount: amount,
              notes: notes,
            ),
          );
        } catch (e) {
          debugPrint("Error parsing expense row: $row -> $e");
        }
      }
      return entries;
    }
    return [];
  }
}
