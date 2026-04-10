import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _SeriesData {
  final String title;
  final int episodeCount;
  final int totalListeners;
  final List<Color> gradient;
  final IconData icon;
  final bool isActive;

  const _SeriesData({
    required this.title,
    required this.episodeCount,
    required this.totalListeners,
    required this.gradient,
    required this.icon,
    this.isActive = true,
  });
}

const _series = [
  _SeriesData(
    title: 'مجلس الشعر الأسبوعي',
    episodeCount: 12,
    totalListeners: 2340,
    gradient: [Color(0xFF5CBFAD), Color(0xFF2A6F97)],
    icon: Icons.auto_stories_rounded,
  ),
  _SeriesData(
    title: 'نقاشات تقنية حيّة',
    episodeCount: 8,
    totalListeners: 1850,
    gradient: [Color(0xFF6C3FA0), Color(0xFF2E1A3E)],
    icon: Icons.memory_rounded,
  ),
  _SeriesData(
    title: 'صالون ريادة الأعمال',
    episodeCount: 5,
    totalListeners: 960,
    gradient: [Color(0xFFD4AF37), Color(0xFF8B5E3C)],
    icon: Icons.rocket_launch_rounded,
    isActive: false,
  ),
];

class _ScheduledEvent {
  final String title;
  final String date;
  final String time;
  final int rsvpCount;

  const _ScheduledEvent({
    required this.title,
    required this.date,
    required this.time,
    required this.rsvpCount,
  });
}

const _events = [
  _ScheduledEvent(
    title: 'الحلقة ١٣: شعراء الخليج',
    date: 'الخميس',
    time: '٩:٠٠ م',
    rsvpCount: 45,
  ),
  _ScheduledEvent(
    title: 'حوار تقني: Flutter vs React',
    date: 'السبت',
    time: '١٠:٠٠ م',
    rsvpCount: 72,
  ),
];

class CreatorStudioScreen extends StatefulWidget {
  const CreatorStudioScreen({super.key});

  @override
  State<CreatorStudioScreen> createState() => _CreatorStudioScreenState();
}

class _CreatorStudioScreenState extends State<CreatorStudioScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildQuickActions()),
            SliverToBoxAdapter(child: _buildAudienceGrowth()),
            SliverToBoxAdapter(child: _buildSeriesSection()),
            SliverToBoxAdapter(child: _buildScheduledEvents()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          HapticButton(
            onTap: () => Navigator.of(context).pop(),
            child: GlassmorphicContainer(
              borderRadius: 14,
              padding: const EdgeInsets.all(10),
              blur: 10,
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: BayanColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مركز المبدعين',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
                Text(
                  'أدر محتواك الحصري',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFD4AF37),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.play_circle_rounded,
              label: 'بث مباشر',
              color: BayanColors.accent,
              onTap: () => HapticFeedback.heavyImpact(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.calendar_month_rounded,
              label: 'جدولة',
              color: const Color(0xFF6C3FA0),
              onTap: () => HapticFeedback.mediumImpact(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.library_add_rounded,
              label: 'سلسلة جديدة',
              color: const Color(0xFFD4AF37),
              onTap: () => HapticFeedback.mediumImpact(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceGrowth() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF3A2050), Color(0xFF1E1035)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: BayanColors.accent.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: BayanColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'نمو الجمهور',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
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
                        color: BayanColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+١٨٪ هذا الأسبوع',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: CustomPaint(
                    painter: _MiniGrowthPainter(),
                    size: Size.infinite,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _GrowthStat(
                      label: 'إجمالي المتابعين',
                      value: '٥,١٤٠',
                      icon: Icons.people_rounded,
                    ),
                    const SizedBox(width: 16),
                    _GrowthStat(
                      label: 'متابعون جدد',
                      value: '+٨٤',
                      icon: Icons.person_add_rounded,
                    ),
                    const SizedBox(width: 16),
                    _GrowthStat(
                      label: 'ساعات البث',
                      value: '٣٢',
                      icon: Icons.mic_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
          child: Row(
            children: [
              const Icon(
                Icons.playlist_play_rounded,
                color: BayanColors.accent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'السلاسل النشطة',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 185,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _series.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _SeriesCard(series: _series[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
          child: Row(
            children: [
              const Icon(
                Icons.event_rounded,
                color: Color(0xFFD4AF37),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'الأحداث القادمة',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ...List.generate(_events.length, (i) {
          final e = _events[i];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: GlassmorphicContainer(
              borderRadius: 18,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          e.date,
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: BayanColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${e.time} · ${e.rsvpCount} حجز',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: BayanColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HapticButton(
                    hapticType: HapticFeedbackType.selection,
                    onTap: () => HapticFeedback.selectionClick(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: BayanColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: BayanColors.accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'تعديل',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.heavy,
      onTap: onTap,
      child: GlassmorphicContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BayanColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  final _SeriesData series;

  const _SeriesCard({required this.series});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  series.gradient[0].withValues(alpha: 0.3),
                  series.gradient[1].withValues(alpha: 0.15),
                ],
              ),
              border: Border.all(color: BayanColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: series.gradient[0].withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        series.icon,
                        color: BayanColors.textPrimary,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    if (series.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: BayanColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'نشطة',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  series.title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniStat(
                      Icons.play_circle_outline_rounded,
                      '${series.episodeCount} حلقة',
                    ),
                    const SizedBox(width: 12),
                    _miniStat(
                      Icons.headphones_rounded,
                      '${series.totalListeners}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: BayanColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: BayanColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GrowthStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _GrowthStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: BayanColors.accent.withValues(alpha: 0.6),
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 9,
              color: BayanColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniGrowthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final data = [30.0, 42.0, 38.0, 55.0, 48.0, 62.0, 70.0, 65.0, 78.0];
    final maxVal = data.reduce(math.max);
    final step = size.width / (data.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      points.add(
        Offset(i * step, size.height - (data[i] / maxVal) * size.height * 0.9),
      );
    }

    final fillPath = Path()..moveTo(0, size.height);
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      } else {
        final cp1x = points[i - 1].dx + step * 0.4;
        final cp2x = points[i].dx - step * 0.4;
        fillPath.cubicTo(
          cp1x,
          points[i - 1].dy,
          cp2x,
          points[i].dy,
          points[i].dx,
          points[i].dy,
        );
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BayanColors.accent.withValues(alpha: 0.15),
            BayanColors.accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePath = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        linePath.moveTo(points[i].dx, points[i].dy);
      } else {
        final cp1x = points[i - 1].dx + step * 0.4;
        final cp2x = points[i].dx - step * 0.4;
        linePath.cubicTo(
          cp1x,
          points[i - 1].dy,
          cp2x,
          points[i].dy,
          points[i].dx,
          points[i].dy,
        );
      }
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = BayanColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(points.last, 4, Paint()..color = BayanColors.accent);
    canvas.drawCircle(
      points.last,
      6,
      Paint()
        ..color = BayanColors.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
