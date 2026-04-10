import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/audio_waveform_painter.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/report_modal.dart';

class VoiceCardData {
  final String id;
  final String speakerName;
  final String speakerInitial;
  final String title;
  final String duration;
  final int likeCount;
  final List<double> waveform;

  const VoiceCardData({
    required this.id,
    required this.speakerName,
    required this.speakerInitial,
    required this.title,
    required this.duration,
    required this.likeCount,
    required this.waveform,
  });
}

class VoiceCard extends StatefulWidget {
  final VoiceCardData data;
  final VoidCallback? onTapProfile;

  const VoiceCard({super.key, required this.data, this.onTapProfile});

  @override
  State<VoiceCard> createState() => _VoiceCardState();
}

class _VoiceCardState extends State<VoiceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _playController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() => _isPlaying = false);
              _playController.reset();
            }
          });
  }

  @override
  void dispose() {
    _playController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.mediumImpact();
    if (_isPlaying) {
      _playController.stop();
    } else {
      _playController.forward();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BayanColors.glassBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BayanColors.glassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSpeakerRow(),
              const SizedBox(height: 12),
              Text(
                widget.data.title,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              _buildWaveformRow(),
              const SizedBox(height: 12),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakerRow() {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: widget.onTapProfile,
      child: Row(
        children: [
          Hero(
            tag: 'voice-speaker-${widget.data.id}',
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    BayanColors.accent.withValues(alpha: 0.3),
                    BayanColors.surface,
                  ],
                ),
                border: Border.all(color: BayanColors.glassBorder, width: 1),
              ),
              child: Center(
                child: Text(
                  widget.data.speakerInitial,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.data.speakerName,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BayanColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformRow() {
    return Row(
      children: [
        _buildPlayButton(),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 36,
            child: AnimatedBuilder(
              animation: _playController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AudioWaveformPainter(
                    amplitudes: widget.data.waveform,
                    progress: _playController.value,
                    activeColor: BayanColors.accent,
                    inactiveColor: BayanColors.textSecondary.withValues(
                      alpha: 0.25,
                    ),
                    barWidth: 2.5,
                    gap: 2.0,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _togglePlay,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _playController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: _playController.value,
                    color: BayanColors.accent,
                    trackColor: BayanColors.glassBorder,
                  ),
                  size: const Size(40, 40),
                );
              },
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(_isPlaying),
                color: BayanColors.accent,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 13,
          color: BayanColors.textSecondary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          widget.data.duration,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: BayanColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => showReportModal(context, targetName: widget.data.title),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 18,
            color: BayanColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.favorite_rounded,
          size: 14,
          color: BayanColors.accent.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.data.likeCount}',
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: BayanColors.textSecondary.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
