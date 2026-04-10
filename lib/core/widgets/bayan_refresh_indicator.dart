import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bayan/core/theme/theme.dart';

class BayanRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const BayanRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: BayanColors.surface,
      color: BayanColors.accent,
      displacement: 50,
      strokeWidth: 2.5,
      child: child,
    );
  }
}

class FeatherSpinner extends StatefulWidget {
  final double size;
  final Color color;

  const FeatherSpinner({
    super.key,
    this.size = 32,
    this.color = BayanColors.accent,
  });

  @override
  State<FeatherSpinner> createState() => _FeatherSpinnerState();
}

class _FeatherSpinnerState extends State<FeatherSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: CustomPaint(
        painter: _FeatherPainter(color: widget.color),
        size: Size(widget.size, widget.size),
      ),
    );
  }
}

class _FeatherPainter extends CustomPainter {
  final Color color;
  _FeatherPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);

    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx, cy - r * 0.8),
      Offset(cx, cy + r * 0.8),
      stemPaint,
    );

    final leftVane = Path()
      ..moveTo(cx, cy - r * 0.6)
      ..quadraticBezierTo(
        cx - r * 0.7,
        cy - r * 0.2,
        cx - r * 0.3,
        cy + r * 0.3,
      )
      ..quadraticBezierTo(cx - r * 0.1, cy, cx, cy + r * 0.1);

    final vanePaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftVane, vanePaint);

    final rightVane = Path()
      ..moveTo(cx, cy - r * 0.6)
      ..quadraticBezierTo(
        cx + r * 0.7,
        cy - r * 0.2,
        cx + r * 0.3,
        cy + r * 0.3,
      )
      ..quadraticBezierTo(cx + r * 0.1, cy, cx, cy + r * 0.1);
    canvas.drawPath(rightVane, vanePaint);

    final edgePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(leftVane, edgePaint);
    canvas.drawPath(rightVane, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
