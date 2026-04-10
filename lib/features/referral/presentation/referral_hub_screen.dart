import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _Referral {
  final String name;
  final String initial;
  final String date;
  final bool isActive;

  const _Referral({
    required this.name,
    required this.initial,
    required this.date,
    this.isActive = true,
  });
}

const _referrals = [
  _Referral(name: 'سارة الفهد', initial: 'س', date: '٣ أبريل'),
  _Referral(name: 'فهد العنزي', initial: 'ف', date: '٢٩ مارس'),
  _Referral(name: 'نورة الصباح', initial: 'ن', date: '٢٥ مارس'),
  _Referral(name: 'أحمد الحربي', initial: 'أ', date: '٢٠ مارس'),
  _Referral(
    name: 'دانة العجمي',
    initial: 'د',
    date: '١٤ مارس',
    isActive: false,
  ),
];

class ReferralHubScreen extends StatefulWidget {
  const ReferralHubScreen({super.key});

  @override
  State<ReferralHubScreen> createState() => _ReferralHubScreenState();
}

class _ReferralHubScreenState extends State<ReferralHubScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _borderController;

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
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildShareCard()),
            SliverToBoxAdapter(child: _buildStats()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
                child: Text(
                  'شجرة الدعوات',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _ReferralTile(referral: _referrals[index], index: index),
                  childCount: _referrals.length,
                ),
              ),
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
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: BayanColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'ادعُ النخبة',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: AnimatedBuilder(
        animation: _borderController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: SweepGradient(
                colors: [
                  const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  BayanColors.accent.withValues(alpha: 0.3),
                  const Color(0xFF6C3FA0).withValues(alpha: 0.3),
                  const Color(0xFFD4AF37).withValues(alpha: 0.5),
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
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            color: BayanColors.surface,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFD4AF37),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عبدالله الكندري',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: BayanColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFFD4AF37),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'عضو مؤسس',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: BayanColors.glassBackground,
                  border: Border.all(color: BayanColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'BAYAN-AK2024',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    HapticButton(
                      hapticType: HapticFeedbackType.medium,
                      onTap: () => HapticFeedback.mediumImpact(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: BayanColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'نسخ',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.background,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              HapticButton(
                hapticType: HapticFeedbackType.heavy,
                onTap: () => HapticFeedback.heavyImpact(),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFB8960F)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.share_rounded,
                          color: BayanColors.background,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'مشاركة الدعوة',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.background,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatBox(
              value: '${_referrals.length}',
              label: 'دعوات مقبولة',
              icon: Icons.people_rounded,
              color: BayanColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatBox(
              value: '${_referrals.where((r) => r.isActive).length}',
              label: 'نشطون',
              icon: Icons.bolt_rounded,
              color: const Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatBox(
              value: '٧',
              label: 'دعوات متبقية',
              icon: Icons.mail_rounded,
              color: const Color(0xFF6C3FA0),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: BayanColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReferralTile extends StatelessWidget {
  final _Referral referral;
  final int index;
  const _ReferralTile({required this.referral, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: referral.isActive
                      ? BayanColors.accent
                      : BayanColors.textSecondary.withValues(alpha: 0.3),
                  border: Border.all(color: BayanColors.surface, width: 2),
                ),
              ),
              if (index < _referrals.length - 1)
                Container(
                  width: 2,
                  height: 60,
                  color: BayanColors.glassBorder.withValues(alpha: 0.3),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: BayanColors.glassBackground,
                border: Border.all(color: BayanColors.glassBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          referral.isActive
                              ? BayanColors.accent.withValues(alpha: 0.3)
                              : BayanColors.surface,
                          BayanColors.surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        referral.initial,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          referral.name,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BayanColors.textPrimary,
                          ),
                        ),
                        Text(
                          'انضم ${referral.date}',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: BayanColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (referral.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: BayanColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'نشط',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
