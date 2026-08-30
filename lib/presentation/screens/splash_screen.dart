import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'main_screen.dart';

/// Splash screen shown immediately on app launch.
/// Dotenv + Hive are already initialized in main() before this widget loads,
/// so we navigate to MainScreen right away with no blocking work here.
class SplashScreen extends StatefulWidget {
  final AuthService? authService;
  final bool isLoading;

  const SplashScreen({super.key, this.authService, this.isLoading = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.isLoading) {
      _initializeApp();
    }
  }

  @override
  void didUpdateWidget(covariant SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    // Navigate immediately — all heavy setup (Hive, dotenv) is done in main()
    if (!isTest && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      });
    }

    // Auth (signInSilently = network call) run
    // completely in background AFTER navigation — never blocks UI
    if (!isTest && widget.authService != null) {
      Future.delayed(const Duration(milliseconds: 250), () {
        widget.authService!.init();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen is visible only for a fraction of a second
    return const Scaffold(
      backgroundColor: Color(0xFF1565C0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop_rounded, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Dairy Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
