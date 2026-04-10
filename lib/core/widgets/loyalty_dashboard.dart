import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _Achievement {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool unlocked;

  const _Achievement({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.unlocked = false,
  });
}

const _achievements = [
  _Achievement(
    title: '٧ أيام متواصلة',
    subtitle: 'حضور يومي لمدة أسبوع',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFD4AF37),
    unlocked: true,
  ),
  _Achievement(
    title: 'صوت مؤثر',
    subtitle: 'احصل على ١٠٠ إعجاب',
    icon: Icons.campaign_rounded,
    color: BayanColors.accent,
    unlocked: true,
  ),
  _Achievement(
    title: 'مضيف محترف',
    subtitle: 'استضف ١٠ ديوانيّات',
    icon: Icons.star_rounded,
    color: Color(0xFF6C3FA0),
    unlocked: false,
  ),
  _Achievement(
    title: 'حافظ الرأي',
    subtitle: 'شارك ٥٠ مقطع صوتي',
    icon: Icons.graphic_eq_rounded,
    color: Color(0xFF2A6F97),
    unlocked: false,
  ),
  _Achievement(
    title: 'قائد المجتمع',
    subtitle: 'ادعُ ٢٠ شخصاً',
    icon: Icons.group_add_rounded,
    color: Color(0xFF8B5E3C),
    unlocked: false,
  ),
];

class LoyaltyDashboard extends StatefulWidget {
  const LoyaltyDashboard({super.key});

  @override
  State<LoyaltyDashboard> createState() => _LoyaltyDashboardState();
}

class _LoyaltyDashboardState extends State<LoyaltyDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barController;
  late final Animation<double> _barAnimation;

  static const _currentXp = 2450;
  static const _nextLevelXp = 3000;
  static const _currentLevel = 7;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _barAnimation = Tween<double>(begin: 0, end: _currentXp / _nextLevelXp)
        .animate(
          CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic),
        );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _barController.forward();
    });
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLevelCard(),
        const SizedBox(height: 20),
        _buildAchievementsTitle(),
        const SizedBox(height: 12),
        ..._achievements.map(_buildAchievementCard),
      ],
    );
  }

  Widget _buildLevelCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF3A2050),
                BayanColors.surface.withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: BayanColors.accent.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [BayanColors.accent, Color(0xFFD4AF37)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: BayanColors.accent.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$_currentLevel',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: BayanColors.background,
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
                          'المستوى $_currentLevel',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.textPrimary,
                          ),
                        ),
                        Text(
                          'مسار النخبة',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_currentXp / $_nextLevelXp',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                      Text(
                        'XP',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: BayanColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AnimatedBuilder(
                animation: _barAnimation,
                builder: (context, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 14,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: BayanColors.glassBorder,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: _barAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  colors: [
                                    BayanColors.accent,
                                    Color(0xFFD4AF37),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: BayanColors.accent.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المستوى $_currentLevel',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                  Text(
                    'المستوى ${_currentLevel + 1}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsTitle() {
    return Row(
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
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: BayanColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          '${_achievements.where((a) => a.unlocked).length}/${_achievements.length}',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: BayanColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(_Achievement achievement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: BayanColors.glassBackground,
              border: Border.all(
                color: achievement.unlocked
                    ? achievement.color.withValues(alpha: 0.3)
                    : BayanColors.glassBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: achievement.unlocked
                        ? achievement.color.withValues(alpha: 0.15)
                        : BayanColors.glassBorder.withValues(alpha: 0.5),
                    boxShadow: achievement.unlocked
                        ? [
                            BoxShadow(
                              color: achievement.color.withValues(alpha: 0.25),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    achievement.icon,
                    color: achievement.unlocked
                        ? achievement.color
                        : BayanColors.textSecondary.withValues(alpha: 0.4),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: achievement.unlocked
                              ? BayanColors.textPrimary
                              : BayanColors.textSecondary,
                        ),
                      ),
                      Text(
                        achievement.subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (achievement.unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: achievement.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: achievement.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'مُنجَز',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: achievement.color,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.lock_outline_rounded,
                    color: BayanColors.textSecondary.withValues(alpha: 0.3),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showLevelUpCelebration(BuildContext context, {int level = 8}) {
  HapticFeedback.heavyImpact();
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => _LevelUpOverlay(level: level),
  );
}

class _LevelUpOverlay extends StatefulWidget {
  final int level;
  const _LevelUpOverlay({required this.level});

  @override
  State<_LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<_LevelUpOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _particleController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final List<_CelebrationParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _scale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    final rng = math.Random();
    _particles = List.generate(30, (i) {
      return _CelebrationParticle(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.3,
        speed: 0.3 + rng.nextDouble() * 0.7,
        size: 3 + rng.nextDouble() * 5,
        color: [
          BayanColors.accent,
          const Color(0xFFD4AF37),
          const Color(0xFF6C3FA0),
          BayanColors.accentLight,
        ][i % 4],
      );
    });

    _controller.forward();
    _particleController.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _particleController]),
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CelebrationPainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              ),
            ),
            Opacity(
              opacity: _opacity.value,
              child: Center(
                child: Transform.scale(
                  scale: _scale.value,
                  child: _buildCard(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF3A2050), Color(0xFF1E1035)],
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
            blurRadius: 48,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [BayanColors.accent, Color(0xFFD4AF37)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${widget.level}',
                style: GoogleFonts.cairo(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: BayanColors.background,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '🎉 ترقية!',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: const Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'المستوى ${widget.level}',
            style: GoogleFonts.cairo(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'واصل مسيرتك نحو قمة النخبة',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: BayanColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          HapticButton(
            hapticType: HapticFeedbackType.heavy,
            onTap: () {
              HapticFeedback.heavyImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BayanColors.accent, Color(0xFFD4AF37)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: BayanColors.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'رائع!',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.background,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationParticle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;

  const _CelebrationParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _CelebrationPainter extends CustomPainter {
  final List<_CelebrationParticle> particles;
  final double progress;

  _CelebrationPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.y) % 1.0;
      final x = p.x * size.width;
      final y = t * size.height;
      final opacity = (1.0 - t).clamp(0.0, 0.8);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size * (1.0 - t * 0.5), paint);

      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.size * 2 * (1.0 - t * 0.5), glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
