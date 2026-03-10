import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'data/models/milk_entry.dart';
import 'data/models/expense_entry.dart';
import 'logic/providers/dairy_provider.dart';
import 'logic/providers/theme_provider.dart';
import 'features/expense/expense_provider.dart';
import 'logic/services/auth_service.dart';
import 'ui/screens/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logic/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();
  Hive.registerAdapter(MilkEntryAdapter());
  Hive.registerAdapter(ExpenseEntryAdapter());
  Hive.registerAdapter(ExpenseCategoryAdapter());

  final authService = AuthService();
  await authService.init();

  await BackgroundService.initialize();

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
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
