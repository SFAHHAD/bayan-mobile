import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';

class SpeakingAvatar extends StatefulWidget {
  final String initial;
  final double size;
  final bool isSpeaking;
  final bool isMuted;
  final bool isHost;
  final Color glowColor;

  const SpeakingAvatar({
    super.key,
    required this.initial,
    this.size = 72,
    this.isSpeaking = false,
    this.isMuted = false,
    this.isHost = false,
    this.glowColor = BayanColors.accent,
  });

  @override
  State<SpeakingAvatar> createState() => _SpeakingAvatarState();
}

class _SpeakingAvatarState extends State<SpeakingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isSpeaking) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SpeakingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _controller.animateTo(0.0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size + 16,
          height: widget.size + 16,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse = widget.isSpeaking ? _controller.value : 0.0;
              return CustomPaint(
                painter: _GlowRingPainter(
                  progress: pulse,
                  color: widget.isMuted ? Colors.redAccent : widget.glowColor,
                  isSpeaking: widget.isSpeaking,
                ),
                child: child,
              );
            },
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.glowColor.withValues(alpha: 0.25),
                          BayanColors.surface,
                        ],
                      ),
                      border: Border.all(
                        color: BayanColors.glassBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.initial,
                        style: GoogleFonts.cairo(
                          fontSize: widget.size * 0.36,
                          fontWeight: FontWeight.w800,
                          color: BayanColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (widget.isMuted)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withValues(alpha: 0.9),
                          border: Border.all(
                            color: BayanColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mic_off_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (widget.isHost)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BayanColors.accent,
                          border: Border.all(
                            color: BayanColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: BayanColors.background,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isSpeaking;

  _GlowRingPainter({
    required this.progress,
    required this.color,
    required this.isSpeaking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isSpeaking) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final outerPaint = Paint()
      ..color = color.withValues(alpha: 0.15 + progress * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + progress * 2
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + progress * 6);

    canvas.drawCircle(center, radius - 1, outerPaint);

    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.3 + progress * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius - 3, innerPaint);
  }

  @override
  bool shouldRepaint(_GlowRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isSpeaking != isSpeaking;
}
