import 'package:flutter/material.dart';

class CowReactionAnimation extends StatefulWidget {
  final double dailyTotal;
  final double average;

  const CowReactionAnimation({
    super.key,
    required this.dailyTotal,
    required this.average,
  });

  @override
  State<CowReactionAnimation> createState() => _CowReactionAnimationState();
}

class _CowReactionAnimationState extends State<CowReactionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Logic for mood
    IconData icon;
    Color color;
    String text;

    if (widget.dailyTotal > widget.average * 1.1) {
      icon = Icons.sentiment_very_satisfied_outlined;
      color = Colors.green;
      text = "Excellent Yield!";
    } else if (widget.dailyTotal < widget.average * 0.9) {
      icon = Icons.sentiment_dissatisfied_outlined;
      color = Colors.orange;
      text = "Low Yield Today";
    } else {
      icon = Icons.sentiment_satisfied_outlined;
      color = Colors.blue;
      text = "Good Job!";
    }

    // Handle edge case of 0 average (new user)
    if (widget.average == 0) {
      text = "Great Start!";
      color = Colors.green;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(icon, size: 80, color: color),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          text,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
