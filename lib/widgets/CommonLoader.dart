import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../utils/color_constants.dart';

// Reusable Dotted Progress Widget with Logo
class DottedProgressWithLogo extends StatefulWidget {
  final double size; // Overall size of the widget
  final double logoSize; // Size of the logo
  final String logoPath; // Path to the logo asset
  final Color dotColor; // Color of the dots
  final int dotCount; // Number of dots
  final double dotRadius; // Size of each dot
  final Duration animationDuration; // Speed of the animation

  const DottedProgressWithLogo({
    Key? key,
    this.size = 60.0,
    this.logoSize = 45.0,
    this.logoPath = "assets/images/logo.png",
    this.dotColor = primarycolor,
    this.dotCount = 12,
    this.dotRadius = 3.0,
    this.animationDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  _DottedProgressWithLogoState createState() => _DottedProgressWithLogoState();
}

class _DottedProgressWithLogoState extends State<DottedProgressWithLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: DottedCircularProgressPainter(
                  _controller.value,
                  dotColor: widget.dotColor,
                  dotCount: widget.dotCount,
                  dotRadius: widget.dotRadius,
                ),
                size: Size(widget.size, widget.size),
              );
            },
          ),
          Image.asset(
            widget.logoPath,
            width: widget.logoSize,
            height: widget.logoSize,
          ),
        ],
      ),
    );
  }
}


class DottedCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color dotColor;
  final int dotCount;
  final double dotRadius;

  DottedCircularProgressPainter(
      this.progress, {
        this.dotColor = primarycolor,
        this.dotCount = 12,
        this.dotRadius = 3.0,
      });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final gapAngle = 2 * math.pi / dotCount;

    for (int i = 0; i < dotCount; i++) {
      final angle = gapAngle * i + (2 * math.pi * progress);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}