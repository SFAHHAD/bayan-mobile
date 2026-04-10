import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/audio_waveform_painter.dart';

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
  late final List<double> _waveAmplitudes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.isSpeaking) _controller.repeat();

    final rng = math.Random(widget.initial.hashCode);
    _waveAmplitudes = List.generate(24, (_) => 0.3 + rng.nextDouble() * 0.7);
  }

  @override
  void didUpdateWidget(SpeakingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _controller.repeat();
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
    final outerSize = widget.size + 28;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: outerSize,
          height: outerSize,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: CircularWaveformPainter(
                  amplitudes: _waveAmplitudes,
                  animationValue: widget.isSpeaking ? _controller.value : 0.0,
                  color: widget.isMuted ? Colors.redAccent : widget.glowColor,
                  isActive: widget.isSpeaking,
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
