import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/themes/app_theme.dart';
import 'presentation/providers/dairy_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'features/expense/expense_provider.dart';
import 'services/auth_service.dart';
import 'presentation/screens/splash_screen.dart';
import 'data/models/milk_entry.dart';
import 'data/models/expense_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load dotenv
  await dotenv.load(fileName: ".env");

  // Init Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MilkEntryAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ExpenseEntryAdapter());
  if (!Hive.isAdapterRegistered(2))
    Hive.registerAdapter(ExpenseCategoryAdapter());

  // Pre-open Hive boxes and SharedPreferences concurrently
  final Future<void> hiveMilkFuture = Hive.openBox<MilkEntry>('milk_records')
      .then((_) {})
      .catchError((e) {
        debugPrint('Hive preload error: $e');
      });
  final Future<void> hiveExpenseFuture =
      Hive.openBox<ExpenseEntry>('expense_entries').then((_) {}).catchError((
        e,
      ) {
        debugPrint('Hive preload error: $e');
      });

  final prefs = await SharedPreferences.getInstance();
  final isDarkModeSync = prefs.getBool('is_dark_mode') ?? false;

  await Future.wait([hiveMilkFuture, hiveExpenseFuture]);

  final authService = AuthService();

  runApp(MyApp(authService: authService, isDarkModeSync: isDarkModeSync));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final bool isDarkModeSync;

  const MyApp({
    super.key,
    required this.authService,
    required this.isDarkModeSync,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DairyProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initialDark: isDarkModeSync),
        ),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Dairy Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: SplashScreen(authService: authService),
          );
        },
      ),
    );
  }
}
