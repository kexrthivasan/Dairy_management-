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
import 'services/background_service.dart';
import 'presentation/screens/splash_screen.dart';
import 'data/models/milk_entry.dart';
import 'data/models/expense_entry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Start initialization in background asynchronously
  final initFuture = _initApp();

  runApp(MyApp(initFuture: initFuture));
}

Future<Map<String, dynamic>> _initApp() async {
  // Start loading dotenv and SharedPreferences in parallel
  final dotenvFuture = dotenv.load(fileName: ".env");
  final prefsFuture = SharedPreferences.getInstance();

  // Init Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MilkEntryAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ExpenseEntryAdapter());
  if (!Hive.isAdapterRegistered(2))
    Hive.registerAdapter(ExpenseCategoryAdapter());

  // Pre-open Hive boxes concurrently
  final milkOpenFuture = Hive.openBox<MilkEntry>('milk_records');
  final expenseOpenFuture = Hive.openBox<ExpenseEntry>('expense_entries');

  // Await everything at the end
  await Future.wait([
    dotenvFuture,
    prefsFuture,
    milkOpenFuture,
    expenseOpenFuture,
    BackgroundService.initialize(),
  ]);

  final prefs = await prefsFuture;
  final isDarkModeSync = prefs.getBool('is_dark_mode') ?? false;

  final authService = AuthService();

  return {'authService': authService, 'isDarkModeSync': isDarkModeSync};
}

class MyApp extends StatelessWidget {
  final Future<Map<String, dynamic>>? initFuture;
  final AuthService? authService;
  final bool? isDarkModeSync;

  const MyApp({
    super.key,
    this.initFuture,
    this.authService,
    this.isDarkModeSync,
  });

  @override
  Widget build(BuildContext context) {
    if (initFuture == null) {
      // Legacy code path / testing fallback
      final activeAuth = authService ?? AuthService();
      final activeDark = isDarkModeSync ?? false;
      return _buildAppContent(activeAuth, activeDark);
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Show splash or loading screen immediately
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(isLoading: true),
          );
        }

        final data = snapshot.data!;
        final activeAuth = data['authService'] as AuthService;
        final activeDark = data['isDarkModeSync'] as bool;

        return _buildAppContent(activeAuth, activeDark);
      },
    );
  }

  Widget _buildAppContent(AuthService auth, bool isDark) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DairyProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initialDark: isDark),
        ),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Dairy Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: SplashScreen(authService: auth),
          );
        },
      ),
    );
  }
}
