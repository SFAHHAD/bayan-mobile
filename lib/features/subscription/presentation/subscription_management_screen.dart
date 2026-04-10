import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/prestige_loading.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  int _selectedPlan = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildCurrentPlan()),
            SliverToBoxAdapter(child: _buildPlans()),
            SliverToBoxAdapter(child: _buildActions(context)),
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
                  'إدارة الاشتراك',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
                Text(
                  'نادي السيادة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
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

  Widget _buildCurrentPlan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ClipRRect(
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
                  const Color(0xFFD4AF37).withValues(alpha: 0.12),
                  const Color(0xFF3A2050),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFF8B5E3C)],
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: BayanColors.background,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الخطة السنوية',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.textPrimary,
                            ),
                          ),
                          Text(
                            'التجديد: ١٥ مارس ٢٠٢٧',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: BayanColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: BayanColors.accent.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        'نشط',
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.7,
                    minHeight: 6,
                    backgroundColor: BayanColors.glassBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFD4AF37),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '٢٥٥ يوم متبقي',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: BayanColors.textSecondary,
                      ),
                    ),
                    Text(
                      '٣٦٥ يوم',
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
      ),
    );
  }

  Widget _buildPlans() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تغيير الخطة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BayanColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _PlanOption(
            title: 'شهري',
            price: '٢٩ ر.س/شهر',
            isSelected: _selectedPlan == 0,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedPlan = 0);
            },
          ),
          const SizedBox(height: 10),
          _PlanOption(
            title: 'سنوي',
            price: '٢٤٩ ر.س/سنة',
            badge: 'الحالي',
            isSelected: _selectedPlan == 1,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedPlan = 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          HapticButton(
            hapticType: HapticFeedbackType.heavy,
            onTap: () async {
              showPrestigeLoading(context, message: 'جارٍ تحديث الخطة...');
              await Future.delayed(const Duration(seconds: 2));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFF8B5E3C)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'تأكيد الخطة',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.background,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          HapticButton(
            hapticType: HapticFeedbackType.medium,
            onTap: () async {
              showPrestigeLoading(
                context,
                message: 'جارٍ استعادة المشتريات...',
              );
              await Future.delayed(const Duration(seconds: 2));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BayanColors.glassBorder),
              ),
              child: Center(
                child: Text(
                  'استعادة المشتريات',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          HapticButton(
            hapticType: HapticFeedbackType.selection,
            onTap: () => HapticFeedback.selectionClick(),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  'إلغاء الاشتراك',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent.withValues(alpha: 0.7),
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

class _PlanOption extends StatelessWidget {
  final String title;
  final String price;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.title,
    required this.price,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: BayanColors.glassBackground,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
                : BayanColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFD4AF37)
                    : BayanColors.glassBorder,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: BayanColors.background,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.textPrimary,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: BayanColors.accent.withValues(alpha: 0.12),
                          ),
                          child: Text(
                            badge!,
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    price,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
