import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/prestige_loading.dart';

class _Proposal {
  final String id;
  final String title;
  final String description;
  final String author;
  final int forVotes;
  final int againstVotes;
  final String timeLeft;
  final bool isActive;

  const _Proposal({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.forVotes,
    required this.againstVotes,
    required this.timeLeft,
    this.isActive = true,
  });

  int get totalVotes => forVotes + againstVotes;
  double get forRatio => totalVotes > 0 ? forVotes / totalVotes : 0.5;
}

const _proposals = [
  _Proposal(
    id: 'p1',
    title: 'إضافة ديوانيّات خاصة بالكتب',
    description: 'اقتراح إنشاء تصنيف جديد مخصص لمناقشة الكتب والمؤلفات',
    author: 'عبدالله المطيري',
    forVotes: 145,
    againstVotes: 23,
    timeLeft: '٣ أيام',
  ),
  _Proposal(
    id: 'p2',
    title: 'تحسين نظام المكافآت',
    description: 'مراجعة نقاط الولاء ومضاعفة المكافآت للمؤسسين',
    author: 'سارة الفهد',
    forVotes: 98,
    againstVotes: 67,
    timeLeft: '٥ أيام',
  ),
  _Proposal(
    id: 'p3',
    title: 'ميزة البث المرئي',
    description: 'إضافة خيار البث المرئي للديوانيّات المميزة',
    author: 'فهد العنزي',
    forVotes: 210,
    againstVotes: 45,
    timeLeft: 'انتهى',
    isActive: false,
  ),
];

class GovernanceScreen extends StatefulWidget {
  const GovernanceScreen({super.key});

  @override
  State<GovernanceScreen> createState() => _GovernanceScreenState();
}

class _GovernanceScreenState extends State<GovernanceScreen> {
  final Map<String, double> _votes = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildIntro()),
            ..._proposals.map(
              (p) => SliverToBoxAdapter(child: _buildProposalCard(p)),
            ),
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
              child: Semantics(
                label: 'رجوع',
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: BayanColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قاعة الشورى',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
                Text(
                  'حوكمة المجتمع',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'رمز الحوكمة',
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C3FA0).withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Color(0xFF6C3FA0),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  const Color(0xFF6C3FA0).withValues(alpha: 0.1),
                  BayanColors.glassBackground,
                ],
              ),
              border: Border.all(
                color: const Color(0xFF6C3FA0).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6C3FA0).withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.how_to_vote_rounded,
                    color: Color(0xFF6C3FA0),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صوتك يصنع الفرق',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.textPrimary,
                        ),
                      ),
                      Text(
                        'شارك في تشكيل مستقبل بَيَان من خلال التصويت على المقترحات',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: BayanColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProposalCard(_Proposal proposal) {
    final vote = _votes[proposal.id];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: BayanColors.glassBackground,
              border: Border.all(
                color: proposal.isActive
                    ? BayanColors.glassBorder
                    : BayanColors.glassBorder.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: proposal.isActive
                            ? BayanColors.accent.withValues(alpha: 0.1)
                            : BayanColors.textSecondary.withValues(alpha: 0.1),
                      ),
                      child: Text(
                        proposal.isActive ? 'نشط' : 'مغلق',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: proposal.isActive
                              ? BayanColors.accent
                              : BayanColors.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.timer_rounded,
                      size: 14,
                      color: BayanColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      proposal.timeLeft,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: BayanColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  proposal.title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  proposal.description,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: BayanColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اقتراح: ${proposal.author}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: BayanColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildVoteBar(proposal),
                const SizedBox(height: 14),
                if (proposal.isActive) _buildVoteSlider(proposal, vote),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoteBar(_Proposal proposal) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'مؤيد ${proposal.forVotes}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: BayanColors.accent,
              ),
            ),
            Text(
              '${proposal.totalVotes} صوت',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: BayanColors.textSecondary,
              ),
            ),
            Text(
              'معارض ${proposal.againstVotes}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: (proposal.forRatio * 100).round(),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [BayanColors.accent, Color(0xFF7DD4C4)],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - proposal.forRatio) * 100).round(),
                  child: Container(
                    color: Colors.redAccent.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoteSlider(_Proposal proposal, double? currentVote) {
    final sliderValue = currentVote ?? 0.5;
    final isFor = sliderValue > 0.55;
    final isAgainst = sliderValue < 0.45;

    return Column(
      children: [
        Semantics(
          label: 'شريط التصويت',
          value: isFor
              ? 'مؤيد'
              : isAgainst
              ? 'معارض'
              : 'محايد',
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: BayanColors.accent,
              inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.3),
              thumbColor: isFor
                  ? BayanColors.accent
                  : isAgainst
                  ? Colors.redAccent
                  : BayanColors.textSecondary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
              overlayColor: BayanColors.accent.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: sliderValue,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _votes[proposal.id] = v);
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'معارض',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (currentVote != null)
              HapticButton(
                hapticType: HapticFeedbackType.heavy,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  showPrestigeLoading(context, message: 'جارٍ تسجيل صوتك...');
                  final nav = Navigator.of(context);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (nav.mounted) nav.pop();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isFor
                        ? BayanColors.accent
                        : isAgainst
                        ? Colors.redAccent
                        : BayanColors.textSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isFor
                        ? 'تأييد'
                        : isAgainst
                        ? 'معارضة'
                        : 'محايد',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.background,
                    ),
                  ),
                ),
              ),
            Text(
              'مؤيد',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: BayanColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TrustMeter extends StatefulWidget {
  final double score;
  final double size;

  const TrustMeter({super.key, required this.score, this.size = 140});

  @override
  State<TrustMeter> createState() => _TrustMeterState();
}

class _TrustMeterState extends State<TrustMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.7,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _TrustGaugePainter(score: _animation.value),
            child: Align(
              alignment: const Alignment(0, 0.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_animation.value * 100).round()}',
                    style: GoogleFonts.cairo(
                      fontSize: widget.size * 0.18,
                      fontWeight: FontWeight.w800,
                      color: _scoreColor(_animation.value),
                    ),
                  ),
                  Text(
                    'مؤشر الثقة',
                    style: GoogleFonts.cairo(
                      fontSize: widget.size * 0.07,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 0.75) return BayanColors.accent;
    if (s >= 0.5) return const Color(0xFFD4AF37);
    return Colors.redAccent;
  }
}

class _TrustGaugePainter extends CustomPainter {
  final double score;

  _TrustGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    final trackPaint = Paint()
      ..color = BayanColors.glassBorder.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: const [Colors.redAccent, Color(0xFFD4AF37), BayanColors.accent],
      transform: GradientRotation(startAngle),
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * score,
      false,
      fillPaint,
    );

    final needleAngle = startAngle + sweepAngle * score;
    final needleTip = Offset(
      center.dx + (radius - 18) * math.cos(needleAngle),
      center.dy + (radius - 18) * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = BayanColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleTip, needlePaint);

    final dotPaint = Paint()
      ..color = BayanColors.textPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, dotPaint);

    final glowPaint = Paint()
      ..color = _glowColor(score).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(needleTip, 6, glowPaint);
  }

  Color _glowColor(double s) {
    if (s >= 0.75) return BayanColors.accent;
    if (s >= 0.5) return const Color(0xFFD4AF37);
    return Colors.redAccent;
  }

  @override
  bool shouldRepaint(covariant _TrustGaugePainter oldDelegate) =>
      oldDelegate.score != score;
}
