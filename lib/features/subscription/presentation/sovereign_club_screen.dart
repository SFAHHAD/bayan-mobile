import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/app_icon_selector.dart';
import 'package:bayan/features/governance/presentation/governance_screen.dart';
import 'package:bayan/features/subscription/presentation/subscription_management_screen.dart';

class _PlanFeature {
  final String label;
  final bool free;
  final bool premium;

  const _PlanFeature({
    required this.label,
    required this.free,
    required this.premium,
  });
}

const _features = [
  _PlanFeature(label: 'حضور الديوانيّات', free: true, premium: true),
  _PlanFeature(label: 'إنشاء ديوانيّة', free: true, premium: true),
  _PlanFeature(label: 'التسجيل الصوتي', free: false, premium: true),
  _PlanFeature(label: 'المؤثرات الصوتية', free: false, premium: true),
  _PlanFeature(label: 'التوثيق السريع', free: false, premium: true),
  _PlanFeature(label: 'إحصائيات متقدمة', free: false, premium: true),
  _PlanFeature(label: 'دعم أولوية', free: false, premium: true),
  _PlanFeature(label: 'شارة ذهبية حصرية', free: false, premium: true),
  _PlanFeature(label: 'تخصيص الملف الشخصي', free: false, premium: true),
];

class SovereignClubScreen extends StatelessWidget {
  const SovereignClubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: Stack(
        children: [
          _buildBg(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildHero()),
                SliverToBoxAdapter(child: _buildFounderHighlight()),
                SliverToBoxAdapter(child: _buildComparisonTable()),
                SliverToBoxAdapter(child: _buildPricingCards()),
                SliverToBoxAdapter(child: _buildCta(context)),
                SliverToBoxAdapter(child: _buildMemberActions(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBg() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFD4AF37).withValues(alpha: 0.08),
            BayanColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFD4AF37),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'نادي السيادة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFFD4AF37), Color(0xFF8B5E3C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                  blurRadius: 28,
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: BayanColors.background,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'انضم لنادي السيادة',
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'تجربة بيان بلا حدود',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: BayanColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The Sovereign Club',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: BayanColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFounderHighlight() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  const Color(0xFF3A2050),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFD4AF37),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عضوية المؤسسين',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                      Text(
                        'انضم الآن واحصل على شارة المؤسس الذهبية الحصرية مدى الحياة',
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

  Widget _buildComparisonTable() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 14),
            child: Text(
              'مقارنة المميزات',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: BayanColors.glassBackground,
                  border: Border.all(color: BayanColors.glassBorder),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'الميزة',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: BayanColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'مجاني',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: BayanColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'سيادة',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFD4AF37),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: BayanColors.glassBorder.withValues(alpha: 0.3),
                    ),
                    ..._features.map((f) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    f.label,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: BayanColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Icon(
                                      f.free
                                          ? Icons.check_circle_rounded
                                          : Icons.remove_rounded,
                                      color: f.free
                                          ? BayanColors.accent
                                          : BayanColors.textSecondary
                                                .withValues(alpha: 0.3),
                                      size: 18,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Icon(
                                      f.premium
                                          ? Icons.check_circle_rounded
                                          : Icons.remove_rounded,
                                      color: f.premium
                                          ? const Color(0xFFD4AF37)
                                          : BayanColors.textSecondary
                                                .withValues(alpha: 0.3),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: BayanColors.glassBorder.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _PricingCard(
              title: 'شهري',
              price: '٢٩',
              currency: 'ر.س',
              period: '/شهر',
              isPopular: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PricingCard(
              title: 'سنوي',
              price: '٢٤٩',
              currency: 'ر.س',
              period: '/سنة',
              isPopular: true,
              badge: 'وفّر ٣٠٪',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          HapticButton(
            hapticType: HapticFeedbackType.heavy,
            onTap: () => HapticFeedback.heavyImpact(),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFF8B5E3C)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: BayanColors.background,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'انضم للنادي الآن',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.background,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'يمكنك الإلغاء في أي وقت',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: BayanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 12),
            child: Text(
              'إدارة العضوية',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
            ),
          ),
          _MemberActionTile(
            icon: Icons.account_balance_rounded,
            label: 'قاعة الشورى',
            subtitle: 'شارك في حوكمة المجتمع',
            color: const Color(0xFF6C3FA0),
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, a, b) => const GovernanceScreen(),
                  transitionDuration: const Duration(milliseconds: 400),
                  transitionsBuilder: (context, animation, _, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _MemberActionTile(
            icon: Icons.settings_rounded,
            label: 'إدارة الاشتراك',
            subtitle: 'تغيير الخطة، استعادة المشتريات',
            color: BayanColors.accent,
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, a, b) =>
                      const SubscriptionManagementScreen(),
                  transitionDuration: const Duration(milliseconds: 400),
                  transitionsBuilder: (context, animation, _, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _MemberActionTile(
            icon: Icons.app_settings_alt_rounded,
            label: 'أيقونة التطبيق',
            subtitle: 'اختر الأيقونة الذهبية أو الداكنة',
            color: const Color(0xFFD4AF37),
            onTap: () => showAppIconSelector(context),
          ),
        ],
      ),
    );
  }
}

class _MemberActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MemberActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: BayanColors.glassBackground,
              border: Border.all(color: BayanColors.glassBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: BayanColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String currency;
  final String period;
  final bool isPopular;
  final String? badge;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.currency,
    required this.period,
    required this.isPopular,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.medium,
      onTap: () => HapticFeedback.mediumImpact(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: BayanColors.glassBackground,
              border: Border.all(
                color: isPopular
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
                    : BayanColors.glassBorder,
                width: isPopular ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                if (badge != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BayanColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.cairo(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isPopular
                            ? const Color(0xFFD4AF37)
                            : BayanColors.textPrimary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        ' $currency',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  period,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
