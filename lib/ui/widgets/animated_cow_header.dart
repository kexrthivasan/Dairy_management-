import 'package:flutter/material.dart';

class AnimatedCowHeader extends StatefulWidget {
  const AnimatedCowHeader({super.key});

  @override
  State<AnimatedCowHeader> createState() => _AnimatedCowHeaderState();
}

class _AnimatedCowHeaderState extends State<AnimatedCowHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _controller.value,
      child: Container(
        width: 150,
        height: 150,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Image.asset(
          'assets/images/cow_mascot.gif', // Try GIF first
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to PNG
            return Image.asset(
              'assets/images/cow_mascot.png',
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) {
                // Fallback to Icon
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200, width: 4),
                    boxShadow: [
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cruelty_free,
                    size: 80,
                    color: Colors.brown,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
