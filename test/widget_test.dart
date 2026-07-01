import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:home_dairy_manager/main.dart';
import 'package:home_dairy_manager/services/auth_service.dart';
import 'package:home_dairy_manager/data/models/milk_entry.dart';
import 'package:home_dairy_manager/data/models/expense_entry.dart';

void main() {
  setUpAll(() async {
    // Load standard dotenv file from the root directory
    await dotenv.load(fileName: '.env');

    // Initialize Hive in a temp directory
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MilkEntryAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(ExpenseEntryAdapter());
    if (!Hive.isAdapterRegistered(2))
      Hive.registerAdapter(ExpenseCategoryAdapter());
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    final authService = AuthService();
    await tester.pumpWidget(
      MyApp(authService: authService, isDarkModeSync: false),
    );

    // Verify the app loads with the title on the Splash Screen
    expect(find.text('Dairy Manager'), findsOneWidget);
  });
}
