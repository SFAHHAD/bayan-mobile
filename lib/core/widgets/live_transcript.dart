import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _TranscriptWord {
  final String text;
  final double startTime;
  final double endTime;

  const _TranscriptWord({
    required this.text,
    required this.startTime,
    required this.endTime,
  });
}

const _sampleTranscript = [
  _TranscriptWord(text: 'بسم', startTime: 0.0, endTime: 0.4),
  _TranscriptWord(text: 'الله', startTime: 0.4, endTime: 0.8),
  _TranscriptWord(text: 'الرحمن', startTime: 0.8, endTime: 1.3),
  _TranscriptWord(text: 'الرحيم', startTime: 1.3, endTime: 1.8),
  _TranscriptWord(text: '،', startTime: 1.8, endTime: 1.9),
  _TranscriptWord(text: 'أهلاً', startTime: 1.9, endTime: 2.3),
  _TranscriptWord(text: 'وسهلاً', startTime: 2.3, endTime: 2.7),
  _TranscriptWord(text: 'بالجميع', startTime: 2.7, endTime: 3.2),
  _TranscriptWord(text: 'في', startTime: 3.2, endTime: 3.4),
  _TranscriptWord(text: 'ديوانيّة', startTime: 3.4, endTime: 4.0),
  _TranscriptWord(text: 'الشعر', startTime: 4.0, endTime: 4.5),
  _TranscriptWord(text: 'الحديث', startTime: 4.5, endTime: 5.0),
  _TranscriptWord(text: '.', startTime: 5.0, endTime: 5.1),
  _TranscriptWord(text: 'اليوم', startTime: 5.3, endTime: 5.7),
  _TranscriptWord(text: 'سنتحدث', startTime: 5.7, endTime: 6.2),
  _TranscriptWord(text: 'عن', startTime: 6.2, endTime: 6.4),
  _TranscriptWord(text: 'أهمية', startTime: 6.4, endTime: 6.9),
  _TranscriptWord(text: 'الكلمة', startTime: 6.9, endTime: 7.4),
  _TranscriptWord(text: 'في', startTime: 7.4, endTime: 7.6),
  _TranscriptWord(text: 'بناء', startTime: 7.6, endTime: 8.0),
  _TranscriptWord(text: 'الحضارات', startTime: 8.0, endTime: 8.7),
  _TranscriptWord(text: 'وتشكيل', startTime: 8.7, endTime: 9.3),
  _TranscriptWord(text: 'الوعي', startTime: 9.3, endTime: 9.8),
  _TranscriptWord(text: 'الجمعي', startTime: 9.8, endTime: 10.3),
  _TranscriptWord(text: '.', startTime: 10.3, endTime: 10.4),
];

class LiveTranscriptView extends StatefulWidget {
  final String speakerName;
  final String duration;

  const LiveTranscriptView({
    super.key,
    this.speakerName = 'عبدالله المطيري',
    this.duration = '١٠:٢٤',
  });

  @override
  State<LiveTranscriptView> createState() => _LiveTranscriptViewState();
}

class _LiveTranscriptViewState extends State<LiveTranscriptView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _playController;
  bool _isPlaying = false;

  static const _totalDuration = 10.5;

  @override
  void initState() {
    super.initState();
    _playController =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: (_totalDuration * 1000).round()),
        )..addStatusListener((status) {
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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: BayanColors.glassBackground,
            border: Border.all(color: BayanColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTranscriptBody(),
              const SizedBox(height: 16),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Semantics(
          label: 'النص التفريغي',
          child: const Icon(
            Icons.subtitles_rounded,
            color: BayanColors.accent,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'النص التفريغي',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: BayanColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          widget.speakerName,
          style: GoogleFonts.cairo(fontSize: 11, color: BayanColors.accent),
        ),
      ],
    );
  }

  Widget _buildTranscriptBody() {
    return AnimatedBuilder(
      animation: _playController,
      builder: (context, _) {
        final currentTime = _playController.value * _totalDuration;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 4,
            runSpacing: 6,
            children: _sampleTranscript.map((word) {
              final isPast = currentTime >= word.endTime;
              final isCurrent =
                  currentTime >= word.startTime && currentTime < word.endTime;
              final isUpcoming = currentTime < word.startTime;
              final fadeProgress = isUpcoming
                  ? ((currentTime - (word.startTime - 0.6)) / 0.6).clamp(
                      0.0,
                      1.0,
                    )
                  : 1.0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: isCurrent
                    ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                    : EdgeInsets.zero,
                decoration: isCurrent
                    ? BoxDecoration(
                        color: BayanColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent
                        ? BayanColors.accent
                        : isPast
                        ? BayanColors.textPrimary
                        : BayanColors.textSecondary.withValues(
                            alpha: 0.15 + fadeProgress * 0.35,
                          ),
                    height: 1.8,
                  ),
                  child: Transform.translate(
                    offset: Offset(0, isUpcoming ? 2 * (1 - fadeProgress) : 0),
                    child: Text(word.text),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return AnimatedBuilder(
      animation: _playController,
      builder: (context, _) {
        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: BayanColors.accent,
                inactiveTrackColor: BayanColors.glassBorder,
                thumbColor: BayanColors.accent,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 3,
                overlayColor: BayanColors.accent.withValues(alpha: 0.1),
              ),
              child: Slider(
                value: _playController.value,
                onChanged: (v) {
                  _playController.value = v;
                },
              ),
            ),
            Row(
              children: [
                Text(
                  _formatTime(_playController.value * _totalDuration),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: BayanColors.textSecondary,
                  ),
                ),
                const Spacer(),
                HapticButton(
                  hapticType: HapticFeedbackType.medium,
                  onTap: _togglePlay,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BayanColors.accent,
                      boxShadow: [
                        BoxShadow(
                          color: BayanColors.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: BayanColors.background,
                      size: 24,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  widget.duration,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatTime(double seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).round();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
