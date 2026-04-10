import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class AiSummaryData {
  final String diwanName;
  final String hostName;
  final String summary;
  final List<String> topics;
  final String duration;
  final int listenerCount;

  const AiSummaryData({
    required this.diwanName,
    required this.hostName,
    required this.summary,
    required this.topics,
    required this.duration,
    required this.listenerCount,
  });
}

class AiSummaryCard extends StatefulWidget {
  final AiSummaryData data;
  const AiSummaryCard({super.key, required this.data});

  @override
  State<AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends State<AiSummaryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _borderController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _borderController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: SweepGradient(
              center: Alignment.center,
              colors: [
                BayanColors.accent.withValues(alpha: 0.4),
                const Color(0xFFD4AF37).withValues(alpha: 0.3),
                const Color(0xFF6C3FA0).withValues(alpha: 0.3),
                BayanColors.accent.withValues(alpha: 0.4),
              ],
              transform: GradientRotation(
                _borderController.value * 2 * math.pi,
              ),
            ),
          ),
          padding: const EdgeInsets.all(1.5),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BayanColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildSummaryText(),
                if (_isExpanded) ...[
                  const SizedBox(height: 14),
                  _buildTopics(),
                ],
                const SizedBox(height: 12),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                BayanColors.accent.withValues(alpha: 0.2),
                const Color(0xFFD4AF37).withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFD4AF37),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ملخص بَيَان الذكي',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.accent,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BayanColors.accent.withValues(alpha: 0.2),
                        const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AI',
                    style: GoogleFonts.cairo(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              widget.data.diwanName,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          widget.data.duration,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: BayanColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryText() {
    return Text(
      widget.data.summary,
      style: GoogleFonts.cairo(
        fontSize: 13,
        color: BayanColors.textPrimary.withValues(alpha: 0.85),
        height: 1.6,
      ),
      maxLines: _isExpanded ? null : 3,
      overflow: _isExpanded ? null : TextOverflow.ellipsis,
    );
  }

  Widget _buildTopics() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.data.topics.map((topic) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: BayanColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: BayanColors.accent.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            topic,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: BayanColors.accent,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(
          Icons.person_outline_rounded,
          size: 14,
          color: BayanColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          widget.data.hostName,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: BayanColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.headphones_rounded,
          size: 14,
          color: BayanColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.data.listenerCount}',
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: BayanColors.textSecondary,
          ),
        ),
        const Spacer(),
        HapticButton(
          hapticType: HapticFeedbackType.selection,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isExpanded ? 'أقل' : 'المزيد',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BayanColors.accent,
                ),
              ),
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(
                  Icons.expand_more_rounded,
                  color: BayanColors.accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
