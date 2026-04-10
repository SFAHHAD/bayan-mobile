import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/audio_waveform_painter.dart';

class SpatialSpeakingAvatar extends StatefulWidget {
  final String initial;
  final double size;
  final bool isSpeaking;
  final bool isMuted;
  final bool isHost;
  final bool isHiFi;
  final Color glowColor;
  final double spatialAngle;

  const SpatialSpeakingAvatar({
    super.key,
    required this.initial,
    this.size = 72,
    this.isSpeaking = false,
    this.isMuted = false,
    this.isHost = false,
    this.isHiFi = false,
    this.glowColor = BayanColors.accent,
    this.spatialAngle = 0.0,
  });

  @override
  State<SpatialSpeakingAvatar> createState() => _SpatialSpeakingAvatarState();
}

class _SpatialSpeakingAvatarState extends State<SpatialSpeakingAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _spatialController;
  late final List<double> _waveAmplitudes;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _spatialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    if (widget.isSpeaking) {
      _waveController.repeat();
      _spatialController.repeat();
    }

    final rng = math.Random(widget.initial.hashCode);
    _waveAmplitudes = List.generate(24, (_) => 0.3 + rng.nextDouble() * 0.7);
  }

  @override
  void didUpdateWidget(SpatialSpeakingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _waveController.repeat();
      _spatialController.repeat();
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _waveController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
      );
      _spatialController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _spatialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outerSize = widget.size + 28;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: outerSize,
          height: outerSize,
          child: AnimatedBuilder(
            animation: Listenable.merge([_waveController, _spatialController]),
            builder: (context, child) {
              return CustomPaint(
                painter: CircularWaveformPainter(
                  amplitudes: _waveAmplitudes,
                  animationValue: widget.isSpeaking
                      ? _waveController.value
                      : 0.0,
                  color: widget.isMuted ? Colors.redAccent : widget.glowColor,
                  isActive: widget.isSpeaking,
                ),
                foregroundPainter: widget.isSpeaking
                    ? _SpatialGlowPainter(
                        progress: _spatialController.value,
                        color: widget.glowColor,
                        angle: widget.spatialAngle,
                      )
                    : null,
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
                  if (widget.isHiFi)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFD4AF37),
                          border: Border.all(
                            color: BayanColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          size: 11,
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

class _SpatialGlowPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double angle;

  _SpatialGlowPainter({
    required this.progress,
    required this.color,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final glowAngle = angle + progress * math.pi * 2;
    final glowCenter = Offset(
      center.dx + math.cos(glowAngle) * radius * 0.75,
      center.dy + math.sin(glowAngle) * radius * 0.75,
    );

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: radius * 0.6))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(glowCenter, radius * 0.5, paint);
  }

  @override
  bool shouldRepaint(_SpatialGlowPainter old) =>
      old.progress != progress || old.angle != angle;
}

class HiFiBadge extends StatelessWidget {
  const HiFiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.graphic_eq_rounded,
            color: Color(0xFFD4AF37),
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            'Hi-Fi',
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
    );
  }
}
