import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bayan/core/theme/theme.dart';

class EliteAvatarBadge extends StatefulWidget {
  final Widget child;
  final int voiceCount;
  final double size;

  const EliteAvatarBadge({
    super.key,
    required this.child,
    required this.voiceCount,
    this.size = 96,
  });

  @override
  State<EliteAvatarBadge> createState() => _EliteAvatarBadgeState();
}

class _EliteAvatarBadgeState extends State<EliteAvatarBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  bool get _isElite => widget.voiceCount >= 20;
  bool get _isGold => widget.voiceCount >= 50;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    if (_isElite) _glowController.repeat();
  }

  @override
  void didUpdateWidget(EliteAvatarBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isElite && !_glowController.isAnimating) {
      _glowController.repeat();
    } else if (!_isElite && _glowController.isAnimating) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Color get _glowColor =>
      _isGold ? const Color(0xFFD4AF37) : BayanColors.accent;

  @override
  Widget build(BuildContext context) {
    if (!_isElite) return widget.child;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return CustomPaint(
              painter: _EliteGlowPainter(
                progress: _glowController.value,
                color: _glowColor,
                size: widget.size,
              ),
              child: child,
            );
          },
          child: SizedBox(
            width: widget.size + 8,
            height: widget.size + 8,
            child: Center(child: widget.child),
          ),
        ),
        Positioned(top: -4, right: -4, child: _buildFeatherBadge()),
      ],
    );
  }

  Widget _buildFeatherBadge() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final pulse = (math.sin(_glowController.value * 2 * math.pi) + 1) / 2;
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isGold
                  ? [const Color(0xFFD4AF37), const Color(0xFFB8860B)]
                  : [BayanColors.accent, BayanColors.accentLight],
            ),
            border: Border.all(color: BayanColors.background, width: 2),
            boxShadow: [
              BoxShadow(
                color: _glowColor.withValues(alpha: 0.3 + pulse * 0.2),
                blurRadius: 6 + pulse * 4,
              ),
            ],
          ),
          child: Icon(
            _isGold ? Icons.auto_awesome_rounded : Icons.verified_rounded,
            size: 14,
            color: _isGold ? BayanColors.background : BayanColors.background,
          ),
        );
      },
    );
  }
}

class _EliteGlowPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double size;

  _EliteGlowPainter({
    required this.progress,
    required this.color,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = size / 2 + 3;

    final sweepAngle = progress * 2 * math.pi;

    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle,
        endAngle: sweepAngle + math.pi * 0.5,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_EliteGlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
