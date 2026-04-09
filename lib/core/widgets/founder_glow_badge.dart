import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';

class FounderGlowBadge extends StatefulWidget {
  const FounderGlowBadge({super.key});

  @override
  State<FounderGlowBadge> createState() => _FounderGlowBadgeState();
}

class _FounderGlowBadgeState extends State<FounderGlowBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return CustomPaint(
            painter: _GlowPainter(
              progress: _glowController.value,
              glowColor: BayanColors.accent,
            ),
            child: child,
          );
        },
        child: GlassmorphicContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _buildPremiumIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'عضوية مؤسس',
                          style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildEliteChip(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'عضو منذ أبريل ٢٠٢٦',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: BayanColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumIcon() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = (math.sin(_glowController.value * 2 * math.pi) + 1) / 2;
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BayanColors.accent,
                BayanColors.accent.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: BayanColors.accent.withValues(alpha: 0.3 + glow * 0.3),
                blurRadius: 12 + glow * 8,
                spreadRadius: -2 + glow * 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: BayanColors.background,
            size: 28,
          ),
        );
      },
    );
  }

  Widget _buildEliteChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BayanColors.accent.withValues(alpha: 0.25),
            const Color(0xFF6C3FA0).withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'ELITE',
        style: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: BayanColors.accentLight,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final pulse = (math.sin(_glowController.value * 2 * math.pi) + 1) / 2;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: BayanColors.accent.withValues(alpha: 0.1 + pulse * 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BayanColors.accent.withValues(alpha: 0.2 + pulse * 0.15),
            ),
          ),
          child: child,
        );
      },
      child: Text(
        'فعّالة',
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: BayanColors.accent,
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double progress;
  final Color glowColor;

  _GlowPainter({required this.progress, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(22));

    final sweepAngle = progress * 2 * math.pi;

    final glowPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle,
        endAngle: sweepAngle + math.pi * 0.6,
        colors: [
          glowColor.withValues(alpha: 0.0),
          glowColor.withValues(alpha: 0.15),
          glowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path()..addRRect(rrect);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
