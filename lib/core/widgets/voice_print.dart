import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';

class VoicePrint extends StatefulWidget {
  final List<double> amplitudes;
  final double height;

  const VoicePrint({super.key, required this.amplitudes, this.height = 120});

  @override
  State<VoicePrint> createState() => _VoicePrintState();
}

class _VoicePrintState extends State<VoicePrint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: BayanColors.glassBackground,
            border: Border.all(color: BayanColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fingerprint_rounded,
                    color: BayanColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'البصمة الصوتية',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: BayanColors.accent.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      'فريدة',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: BayanColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _VoicePrintPainter(
                      amplitudes: widget.amplitudes,
                      progress: CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeOutCubic,
                      ).value,
                    ),
                    size: Size(double.infinity, widget.height),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoicePrintPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;

  _VoicePrintPainter({required this.amplitudes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final barCount = amplitudes.length;
    final totalWidth = size.width;
    final barWidth = (totalWidth / barCount) * 0.55;
    final gap = (totalWidth - barWidth * barCount) / (barCount - 1);
    final center = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final visibleIndex = (barCount * progress).floor();
      if (i > visibleIndex) continue;

      final amp = amplitudes[i];
      final barHeight = amp * size.height * 0.85;
      final x = i * (barWidth + gap);
      final top = center - barHeight / 2;

      final t = i / barCount;
      final color = Color.lerp(BayanColors.accent, const Color(0xFFD4AF37), t)!;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.3)],
        ).createShader(Rect.fromLTWH(x, top, barWidth, barHeight))
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rrect, paint);

      final glowPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(x + barWidth / 2, center),
                radius: barHeight * 0.4,
              ),
            )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x + barWidth / 2, center),
        barHeight * 0.3,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoicePrintPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
