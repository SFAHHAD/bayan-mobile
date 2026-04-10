import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bayan/core/theme/theme.dart';

/// Static or animated horizontal waveform bars used in VoiceCards.
class AudioWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final double barWidth;
  final double gap;
  final double cornerRadius;

  AudioWaveformPainter({
    required this.amplitudes,
    this.progress = 0.0,
    this.activeColor = BayanColors.accent,
    this.inactiveColor = const Color(0x33FFFFFF),
    this.barWidth = 3.0,
    this.gap = 2.5,
    this.cornerRadius = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final barCount = amplitudes.length;
    final totalWidth = barCount * barWidth + (barCount - 1) * gap;
    final startX = (size.width - totalWidth) / 2;
    final midY = size.height / 2;

    final playedIndex = (progress * barCount).floor();

    for (var i = 0; i < barCount; i++) {
      final amp = amplitudes[i].clamp(0.1, 1.0);
      final barHeight = amp * size.height * 0.85;
      final x = startX + i * (barWidth + gap);
      final top = midY - barHeight / 2;

      final isPlayed = i <= playedIndex;

      final paint = Paint()
        ..color = isPlayed ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        Radius.circular(cornerRadius),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(AudioWaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.amplitudes != amplitudes;
}

/// Circular waveform visualizer radiating outward from an avatar.
class CircularWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double animationValue;
  final Color color;
  final bool isActive;

  CircularWaveformPainter({
    required this.amplitudes,
    required this.animationValue,
    required this.color,
    this.isActive = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive || amplitudes.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = math.min(size.width, size.height) / 2 - 8;
    final maxBarLength = 14.0;
    final barCount = amplitudes.length;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < barCount; i++) {
      final angle = (2 * math.pi / barCount) * i - math.pi / 2;

      final phaseShift = math.sin(animationValue * 2 * math.pi + i * 0.5);
      final amp = (amplitudes[i] * 0.6 + 0.4 * phaseShift.abs()).clamp(
        0.15,
        1.0,
      );

      final barLen = amp * maxBarLength;
      final startR = innerRadius + 2;
      final endR = startR + barLen;

      final start = Offset(
        center.dx + startR * math.cos(angle),
        center.dy + startR * math.sin(angle),
      );
      final end = Offset(
        center.dx + endR * math.cos(angle),
        center.dy + endR * math.sin(angle),
      );

      final opacity = (0.4 + amp * 0.6).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: opacity);

      canvas.drawLine(start, end, paint);
    }

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.08 + animationValue * 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + animationValue * 4);
    canvas.drawCircle(center, innerRadius + 1, glowPaint);
  }

  @override
  bool shouldRepaint(CircularWaveformPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.isActive != isActive ||
      oldDelegate.amplitudes != amplitudes;
}
