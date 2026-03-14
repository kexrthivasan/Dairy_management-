import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/auth_service.dart';
import '../../services/background_service.dart';
import '../../data/models/milk_entry.dart';
import '../../data/models/expense_entry.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  final AuthService authService;

  const SplashScreen({super.key, required this.authService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Perform minimal startup tasks that don't block UI immediately
    await Future.wait([
      dotenv.load(fileName: ".env"),
      Hive.initFlutter(),
    ]);
    
    // Register adapters
    Hive.registerAdapter(MilkEntryAdapter());
    Hive.registerAdapter(ExpenseEntryAdapter());
    Hive.registerAdapter(ExpenseCategoryAdapter());
    
    // Auth init
    await widget.authService.init();

    // Background service (fire and forget after minimal init)
    BackgroundService.initialize();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 80, color: Colors.blue), // Placeholder icon
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Starting Dairy Manager...'),
          ],
        ),
      ),
    );
  }
}
