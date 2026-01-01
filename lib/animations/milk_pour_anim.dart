import 'package:flutter/material.dart';

class MilkPourAnimation extends StatefulWidget {
  final VoidCallback? onCompleted;
  const MilkPourAnimation({super.key, this.onCompleted});

  @override
  State<MilkPourAnimation> createState() => _MilkPourAnimationState();
}

class _MilkPourAnimationState extends State<MilkPourAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      if (widget.onCompleted != null) widget.onCompleted!();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(100, 100),
          painter: MilkBucketPainter(_fillAnimation.value),
        );
      },
    );
  }
}

class MilkBucketPainter extends CustomPainter {
  final double fillLevel;

  MilkBucketPainter(this.fillLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Bucket Shape
    final path = Path();
    path.moveTo(size.width * 0.2, size.height);
    path.lineTo(size.width * 0.8, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    // Clip for filling
    canvas.save();
    canvas.clipPath(path);

    // Fill liquid
    final fillHeight = size.height * fillLevel;
    canvas.drawRect(
      Rect.fromLTRB(0, size.height - fillHeight, size.width, size.height),
      fillPaint,
    );

    canvas.restore();

    // Draw Bucket Outline
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MilkBucketPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel;
  }
}
