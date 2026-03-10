import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.grey.shade100,
      width: double.infinity,
      child: const Text(
        "© Keerthivasan – All rights reserved",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
