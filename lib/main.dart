import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
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

  // Must load .env first — AuthService constructor reads GOOGLE_CLIENT_ID from it
  await dotenv.load(fileName: ".env");

  // Init Hive and register adapters
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MilkEntryAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ExpenseEntryAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ExpenseCategoryAdapter());

  // Now safe to create AuthService (needs dotenv)
  final authService = AuthService();

  runApp(MyApp(authService: authService));
}


class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DairyProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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

