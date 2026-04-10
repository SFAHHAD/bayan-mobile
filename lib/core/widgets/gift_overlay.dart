import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class EliteGift {
  final String name;
  final String nameAr;
  final IconData icon;
  final Color color;
  final int tokenCost;

  const EliteGift({
    required this.name,
    required this.nameAr,
    required this.icon,
    required this.color,
    required this.tokenCost,
  });
}

const eliteGifts = [
  EliteGift(
    name: 'golden_feather',
    nameAr: 'الريشة الذهبية',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFFD4AF37),
    tokenCost: 50,
  ),
  EliteGift(
    name: 'crystal_dallah',
    nameAr: 'الدلة البلورية',
    icon: Icons.coffee_rounded,
    color: Color(0xFF7DD4C4),
    tokenCost: 100,
  ),
  EliteGift(
    name: 'royal_falcon',
    nameAr: 'الصقر الملكي',
    icon: Icons.flutter_dash_rounded,
    color: Color(0xFF6C3FA0),
    tokenCost: 250,
  ),
  EliteGift(
    name: 'pearl_crown',
    nameAr: 'التاج اللؤلؤي',
    icon: Icons.diamond_rounded,
    color: Color(0xFF2A6F97),
    tokenCost: 500,
  ),
];

class _GiftParticle {
  Offset position;
  Offset velocity;
  double size;
  final Color color;

  _GiftParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
  });
}

void showGiftPanel(BuildContext context, {required VoidCallback onGiftSent}) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _GiftPanel(onGiftSent: onGiftSent),
  );
}

class _GiftPanel extends StatelessWidget {
  final VoidCallback onGiftSent;
  const _GiftPanel({required this.onGiftSent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: BayanColors.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: BayanColors.glassBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: BayanColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFFD4AF37),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الهدايا الفاخرة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.toll_rounded,
                          color: Color(0xFFD4AF37),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '١,٢٥٠',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: eliteGifts.map((gift) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _GiftItem(
                        gift: gift,
                        onSend: () {
                          HapticFeedback.heavyImpact();
                          Navigator.pop(context);
                          onGiftSent();
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftItem extends StatelessWidget {
  final EliteGift gift;
  final VoidCallback onSend;
  const _GiftItem({required this.gift, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.heavy,
      onTap: onSend,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: gift.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gift.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(gift.icon, color: gift.color, size: 32),
            const SizedBox(height: 8),
            Text(
              gift.nameAr,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.toll_rounded, size: 12, color: gift.color),
                const SizedBox(width: 2),
                Text(
                  '${gift.tokenCost}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: gift.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GiftAnimationOverlay extends StatefulWidget {
  final EliteGift gift;
  final String senderName;
  final VoidCallback onComplete;

  const GiftAnimationOverlay({
    super.key,
    required this.gift,
    required this.senderName,
    required this.onComplete,
  });

  @override
  State<GiftAnimationOverlay> createState() => _GiftAnimationOverlayState();
}

class _GiftAnimationOverlayState extends State<GiftAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = math.Random();
  final List<_GiftParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2500),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onComplete();
          }
        });

    for (var i = 0; i < 30; i++) {
      _particles.add(
        _GiftParticle(
          position: Offset(
            _random.nextDouble() * 400,
            200 + _random.nextDouble() * 200,
          ),
          velocity: Offset(
            (_random.nextDouble() - 0.5) * 4,
            -_random.nextDouble() * 6 - 2,
          ),
          size: _random.nextDouble() * 4 + 2,
          color: widget.gift.color.withValues(
            alpha: _random.nextDouble() * 0.5 + 0.5,
          ),
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final opacity = progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2);
        return IgnorePointer(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: progress,
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.25,
                  left: 0,
                  right: 0,
                  child: Transform.scale(
                    scale: 0.8 + progress * 0.2,
                    child: Column(
                      children: [
                        Icon(
                          widget.gift.icon,
                          size: 64,
                          color: widget.gift.color,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.gift.nameAr,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: widget.gift.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'من ${widget.senderName}',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: BayanColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
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
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_GiftParticle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = progress;
      final x = p.position.dx + p.velocity.dx * t * 120;
      final y = p.position.dy + p.velocity.dy * t * 120 + 40 * t * t;
      final fadeOut = (1.0 - t).clamp(0.0, 1.0);
      final currentSize = p.size * (1.0 + t * 0.5);

      final paint = Paint()
        ..color = p.color.withValues(alpha: fadeOut * 0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentSize * 0.5);
      canvas.drawCircle(Offset(x, y), currentSize, paint);

      final corePaint = Paint()..color = p.color.withValues(alpha: fadeOut);
      canvas.drawCircle(Offset(x, y), currentSize * 0.4, corePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

void showGiftLeaderboard(BuildContext context) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GiftLeaderboardSheet(),
  );
}

class _LeaderEntry {
  final String name;
  final String initial;
  final int totalTokens;
  final int rank;

  const _LeaderEntry({
    required this.name,
    required this.initial,
    required this.totalTokens,
    required this.rank,
  });
}

const _leaderboard = [
  _LeaderEntry(name: 'خالد العتيبي', initial: 'خ', totalTokens: 2450, rank: 1),
  _LeaderEntry(name: 'سارة الفهد', initial: 'س', totalTokens: 1800, rank: 2),
  _LeaderEntry(name: 'محمد الراشد', initial: 'م', totalTokens: 1250, rank: 3),
  _LeaderEntry(name: 'نورة الصباح', initial: 'ن', totalTokens: 900, rank: 4),
  _LeaderEntry(name: 'أحمد الحربي', initial: 'أ', totalTokens: 650, rank: 5),
];

class _GiftLeaderboardSheet extends StatelessWidget {
  const _GiftLeaderboardSheet();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: BayanColors.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: BayanColors.glassBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: BayanColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFD4AF37),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'المتصدرون',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._leaderboard.map((entry) => _buildLeaderRow(entry)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderRow(_LeaderEntry entry) {
    final rankColors = [
      const Color(0xFFD4AF37),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
      BayanColors.textSecondary,
      BayanColors.textSecondary,
    ];
    final color = rankColors[entry.rank - 1];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.3), BayanColors.surface],
              ),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                entry.initial,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.name,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BayanColors.textPrimary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.toll_rounded, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                '${entry.totalTokens}',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
