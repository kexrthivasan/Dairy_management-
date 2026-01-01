import 'package:flutter/material.dart';

class CashAnimation extends StatefulWidget {
  const CashAnimation({super.key});

  @override
  State<CashAnimation> createState() => _CashAnimationState();
}

class _CashAnimationState extends State<CashAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _dropAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _dropAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _dropAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: const Icon(Icons.monetization_on, size: 40, color: Colors.amber),
      ),
    );
  }
}
