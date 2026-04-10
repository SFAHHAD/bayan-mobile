import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _UpcomingItem {
  final String title;
  final String host;
  final String time;
  final String reason;
  final IconData icon;
  final Color accentColor;
  final bool isLive;

  const _UpcomingItem({
    required this.title,
    required this.host,
    required this.time,
    required this.reason,
    required this.icon,
    required this.accentColor,
    this.isLive = false,
  });
}

const _upcomingItems = [
  _UpcomingItem(
    title: 'مجلس الشعر الأسبوعي',
    host: 'عبدالله المطيري',
    time: 'الآن · مباشر',
    reason: 'لأنك تتابع الأدب',
    icon: Icons.auto_stories_rounded,
    accentColor: BayanColors.accent,
    isLive: true,
  ),
  _UpcomingItem(
    title: 'نقاش تقني: مستقبل Flutter',
    host: 'سارة الفهد',
    time: 'خلال ٣٠ دقيقة',
    reason: 'بناءً على اهتماماتك',
    icon: Icons.memory_rounded,
    accentColor: Color(0xFF6C3FA0),
  ),
  _UpcomingItem(
    title: 'حوار ريادة الأعمال',
    host: 'فهد العنزي',
    time: 'خلال ساعة',
    reason: 'رائج في منطقتك',
    icon: Icons.rocket_launch_rounded,
    accentColor: Color(0xFFD4AF37),
  ),
  _UpcomingItem(
    title: 'ديوان الفكر العربي',
    host: 'نورة الصباح',
    time: 'خلال ساعتين',
    reason: 'مقترح بواسطة الذكاء الاصطناعي',
    icon: Icons.psychology_rounded,
    accentColor: Color(0xFF2A6F97),
  ),
];

class PredictiveFeedSection extends StatefulWidget {
  const PredictiveFeedSection({super.key});

  @override
  State<PredictiveFeedSection> createState() => _PredictiveFeedSectionState();
}

class _PredictiveFeedSectionState extends State<PredictiveFeedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 14),
          ..._upcomingItems.asMap().entries.map((e) {
            return _buildTimelineItem(e.key, e.value);
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [BayanColors.accent, Color(0xFF6C3FA0)],
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: BayanColors.background,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'قادم لأجلك',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BayanColors.textPrimary,
                ),
              ),
              Text(
                'بناءً على اهتماماتك وتوقيتك',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: BayanColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(int index, _UpcomingItem item) {
    final interval = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(
        (index * 0.15).clamp(0.0, 0.7),
        ((index * 0.15) + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    final isLast = index == _upcomingItems.length - 1;

    return AnimatedBuilder(
      animation: interval,
      builder: (context, child) {
        return Opacity(
          opacity: interval.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - interval.value)),
            child: child,
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isLive
                          ? item.accentColor
                          : item.accentColor.withValues(alpha: 0.4),
                      boxShadow: item.isLive
                          ? [
                              BoxShadow(
                                color: item.accentColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              item.accentColor.withValues(alpha: 0.3),
                              BayanColors.glassBorder.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HapticButton(
                  hapticType: HapticFeedbackType.selection,
                  onTap: () => HapticFeedback.mediumImpact(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: BayanColors.glassBackground,
                          border: Border.all(
                            color: item.isLive
                                ? item.accentColor.withValues(alpha: 0.25)
                                : BayanColors.glassBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: item.accentColor.withValues(alpha: 0.12),
                              ),
                              child: Icon(
                                item.icon,
                                color: item.accentColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: BayanColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (item.isLive) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            color: Colors.redAccent.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                          child: Text(
                                            'مباشر',
                                            style: GoogleFonts.cairo(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.host,
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: BayanColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item.time,
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: item.isLive
                                        ? item.accentColor
                                        : BayanColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: item.accentColor.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 8,
                                        color: item.accentColor,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        item.reason,
                                        style: GoogleFonts.cairo(
                                          fontSize: 8,
                                          color: item.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
