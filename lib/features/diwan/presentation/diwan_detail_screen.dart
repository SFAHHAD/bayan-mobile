import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/pulsing_dot.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/features/stage/presentation/diwan_stage_screen.dart';

class DiwanDetailScreen extends StatefulWidget {
  final String heroTag;
  final String name;
  final String host;
  final IconData icon;
  final int voiceCount;
  final int listenerCount;
  final bool isLive;
  final List<Color> gradientColors;

  const DiwanDetailScreen({
    super.key,
    required this.heroTag,
    required this.name,
    required this.host,
    required this.icon,
    required this.voiceCount,
    required this.listenerCount,
    required this.isLive,
    required this.gradientColors,
  });

  @override
  State<DiwanDetailScreen> createState() => _DiwanDetailScreenState();
}

class _DiwanDetailScreenState extends State<DiwanDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  void _enterStage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DiwanStageScreen(
              diwanName: widget.name,
              hostName: widget.host,
              currentUserRole: StageRole.listener,
            ),
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideUp =
              Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return SlideTransition(position: slideUp, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  final _placeholderSpeakers = const [
    ('عبدالله المطيري', 'المضيف', Icons.star_rounded),
    ('سارة الفهد', 'متحدث', Icons.mic_rounded),
    ('فهد العنزي', 'متحدث', Icons.mic_rounded),
    ('نورة الصباح', 'مستمع', Icons.headphones_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: Stack(
        children: [
          _buildGradientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildHeroSection(),
                        const SizedBox(height: 32),
                        FadeTransition(
                          opacity: _contentFade,
                          child: SlideTransition(
                            position: _contentSlide,
                            child: Column(
                              children: [
                                _buildSpeakersSection(),
                                const SizedBox(height: 24),
                                _buildDescriptionCard(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.gradientColors.first.withValues(alpha: 0.2),
            BayanColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          const Spacer(),
          if (widget.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BayanColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: BayanColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PulsingDot(color: BayanColors.accent, size: 6),
                  const SizedBox(width: 6),
                  Text(
                    'مباشر الآن',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          HapticButton(
            hapticType: HapticFeedbackType.selection,
            onTap: () {},
            child: GlassmorphicContainer(
              borderRadius: 14,
              padding: const EdgeInsets.all(10),
              blur: 10,
              child: const Icon(
                Icons.more_horiz_rounded,
                color: BayanColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Hero(
          tag: widget.heroTag,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: widget.gradientColors.first.withValues(alpha: 0.5),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors.first.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(widget.icon, color: BayanColors.textPrimary, size: 42),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.name,
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: BayanColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'المضيف: ${widget.host}',
          style: GoogleFonts.cairo(
            fontSize: 15,
            color: BayanColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatPill(Icons.mic_rounded, '${widget.voiceCount} صوت'),
            const SizedBox(width: 12),
            _buildStatPill(
              Icons.headphones_rounded,
              '${widget.listenerCount} مستمع',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: BayanColors.glassBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BayanColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: BayanColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BayanColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassmorphicContainer(
        borderRadius: 22,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المتحدثون',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(_placeholderSpeakers.length, (i) {
              final (name, role, icon) = _placeholderSpeakers[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BayanColors.accent.withValues(alpha: 0.12),
                      ),
                      child: Center(
                        child: Text(
                          name[0],
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BayanColors.textPrimary,
                            ),
                          ),
                          Text(
                            role,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: BayanColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      icon,
                      size: 18,
                      color: i == 0
                          ? BayanColors.accent
                          : BayanColors.textSecondary,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassmorphicContainer(
        borderRadius: 22,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'عن الديوانيّة',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'مساحة حوارية راقية نناقش فيها آخر المستجدات ونتبادل الأفكار والرؤى في بيئة محترمة تليق بالمحتوى العربي.',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: BayanColors.textSecondary,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: BayanColors.background.withValues(alpha: 0.8),
              border: Border(
                top: BorderSide(
                  color: BayanColors.glassBorder.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: HapticButton(
              hapticType: HapticFeedbackType.medium,
              onTap: () {
                HapticFeedback.mediumImpact();
                if (widget.isLive) _enterStage();
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.isLive
                      ? BayanColors.accent
                      : BayanColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    widget.isLive ? 'انضم للمجلس' : 'فعّل التذكير',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: widget.isLive
                          ? BayanColors.background
                          : BayanColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
