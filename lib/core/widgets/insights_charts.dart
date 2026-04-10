import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/revenue_section.dart';

class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(),
          const SizedBox(height: 24),
          _buildChartCard(
            title: 'نمو المستمعين',
            subtitle: 'آخر ٧ أيام',
            icon: Icons.trending_up_rounded,
            child: const SizedBox(height: 180, child: _ListenerGrowthChart()),
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            title: 'تأثير الأصوات',
            subtitle: 'التفاعل الأسبوعي',
            icon: Icons.insights_rounded,
            child: const SizedBox(height: 160, child: _VoiceImpactChart()),
          ),
          const SizedBox(height: 16),
          _buildAchievements(),
          const SizedBox(height: 24),
          const RevenueSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'إجمالي الاستماع',
            value: '٣,٢٤٧',
            icon: Icons.headphones_rounded,
            color: BayanColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'ساعات البث',
            value: '١٤.٥',
            icon: Icons.access_time_rounded,
            color: const Color(0xFFD4AF37),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BayanColors.glassBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BayanColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: BayanColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BayanColors.glassBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BayanColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الإنجازات',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AchievementBadge(
                    label: 'مبدع',
                    icon: Icons.auto_awesome_rounded,
                    earned: true,
                  ),
                  _AchievementBadge(
                    label: 'مضيف نشط',
                    icon: Icons.campaign_rounded,
                    earned: true,
                  ),
                  _AchievementBadge(
                    label: 'ملهم',
                    icon: Icons.local_fire_department_rounded,
                    earned: false,
                  ),
                  _AchievementBadge(
                    label: 'أسطوري',
                    icon: Icons.diamond_rounded,
                    earned: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: BayanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListenerGrowthChart extends StatelessWidget {
  const _ListenerGrowthChart();

  static const _data = [120.0, 145.0, 132.0, 178.0, 210.0, 195.0, 248.0];
  static const _labels = ['س', 'أ', 'إ', 'ث', 'أ', 'خ', 'ج'];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        data: _data,
        labels: _labels,
        lineColor: BayanColors.accent,
        fillColor: BayanColors.accent.withValues(alpha: 0.08),
        gridColor: BayanColors.glassBorder.withValues(alpha: 0.3),
        labelColor: BayanColors.textSecondary,
      ),
      size: Size.infinite,
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color labelColor;

  _LineChartPainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = maxVal - minVal;
    final chartH = size.height - 30;
    final chartW = size.width;
    final stepX = chartW / (data.length - 1);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (var i = 0; i < 4; i++) {
      final y = chartH * i / 3;
      canvas.drawLine(Offset(0, y), Offset(chartW, y), gridPaint);
    }

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartH - ((data[i] - minVal) / range) * chartH * 0.85;
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(0, chartH);
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      } else {
        final cp1x = points[i - 1].dx + stepX * 0.4;
        final cp2x = points[i].dx - stepX * 0.4;
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
    fillPath.lineTo(chartW, chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor, fillColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, chartW, chartH))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        linePath.moveTo(points[i].dx, points[i].dy);
      } else {
        final cp1x = points[i - 1].dx + stepX * 0.4;
        final cp2x = points[i].dx - stepX * 0.4;
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

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor;
    final dotBgPaint = Paint()..color = const Color(0xFF241231);
    for (final p in points) {
      canvas.drawCircle(p, 4, dotBgPaint);
      canvas.drawCircle(p, 3, dotPaint);
    }

    final textStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
      fontFamily: 'Cairo',
    );
    for (var i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(i * stepX - tp.width / 2, chartH + 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VoiceImpactChart extends StatelessWidget {
  const _VoiceImpactChart();

  static const _data = [0.6, 0.85, 0.45, 0.72, 0.9, 0.55, 0.78];
  static const _labels = ['س', 'أ', 'إ', 'ث', 'أ', 'خ', 'ج'];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(
        data: _data,
        labels: _labels,
        barColor: BayanColors.accent,
        goldColor: const Color(0xFFD4AF37),
        gridColor: BayanColors.glassBorder.withValues(alpha: 0.3),
        labelColor: BayanColors.textSecondary,
      ),
      size: Size.infinite,
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color barColor;
  final Color goldColor;
  final Color gridColor;
  final Color labelColor;

  _BarChartPainter({
    required this.data,
    required this.labels,
    required this.barColor,
    required this.goldColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartH = size.height - 28;
    final barW = size.width / (data.length * 2 + 1);
    final spacing = barW;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (var i = 0; i < 4; i++) {
      final y = chartH * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < data.length; i++) {
      final x = spacing + i * (barW + spacing);
      final barH = data[i] * chartH * 0.9;
      final top = chartH - barH;
      final isHighest = data[i] == data.reduce(math.max);

      final color = isHighest ? goldColor : barColor;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, top, barW, barH),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.4)],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);

      final textStyle = TextStyle(
        color: labelColor,
        fontSize: 10,
        fontFamily: 'Cairo',
      );
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, chartH + 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AchievementBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool earned;

  const _AchievementBadge({
    required this.label,
    required this.icon,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: earned
                ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                : BayanColors.glassBackground,
            border: Border.all(
              color: earned
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                  : BayanColors.glassBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: earned
                ? const Color(0xFFD4AF37)
                : BayanColors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: earned
                ? BayanColors.textPrimary
                : BayanColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
