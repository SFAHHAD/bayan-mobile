import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/features/settings/presentation/accessibility_screen.dart';
import 'package:bayan/features/settings/presentation/concierge_screen.dart';
import 'package:bayan/features/settings/presentation/design_system_screen.dart';
import 'package:bayan/features/creator/presentation/creator_studio_screen.dart';
import 'package:bayan/features/referral/presentation/referral_hub_screen.dart';
import 'package:bayan/features/verification/presentation/verification_screen.dart';
import 'package:bayan/core/widgets/live_event_banner.dart';

class SettingsCenterScreen extends StatefulWidget {
  const SettingsCenterScreen({super.key});

  @override
  State<SettingsCenterScreen> createState() => _SettingsCenterScreenState();
}

class _SettingsCenterScreenState extends State<SettingsCenterScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = true;

  void _pushScreen(Widget screen) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a, b) => screen,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildAccountGroup()),
            SliverToBoxAdapter(child: _buildPrivacyGroup()),
            SliverToBoxAdapter(child: _buildAppearanceGroup()),
            SliverToBoxAdapter(child: _buildAccessibilityGroup()),
            SliverToBoxAdapter(child: _buildSupportGroup()),
            SliverToBoxAdapter(child: _buildLogout()),
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
                  'مركز التحكم',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
                Text(
                  'الإعدادات والتفضيلات',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'أيقونة الإعدادات',
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    BayanColors.accent.withValues(alpha: 0.15),
                    const Color(0xFF6C3FA0).withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: BayanColors.accent,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupTitle('الحساب', Icons.person_rounded, BayanColors.accent),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
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
                    _ControlTile(
                      icon: Icons.person_outline_rounded,
                      label: 'تعديل الملف الشخصي',
                      showDivider: true,
                      onTap: () => HapticFeedback.selectionClick(),
                    ),
                    _ControlTile(
                      icon: Icons.auto_awesome_rounded,
                      label: 'مركز المبدعين',
                      iconColor: const Color(0xFFD4AF37),
                      showDivider: true,
                      onTap: () => _pushScreen(const CreatorStudioScreen()),
                    ),
                    _ControlTile(
                      icon: Icons.verified_rounded,
                      label: 'طلب التوثيق',
                      iconColor: const Color(0xFF2A6F97),
                      showDivider: true,
                      onTap: () => _pushScreen(const VerificationScreen()),
                    ),
                    _ControlTile(
                      icon: Icons.workspace_premium_rounded,
                      label: 'ادعُ النخبة',
                      iconColor: const Color(0xFFD4AF37),
                      showDivider: true,
                      onTap: () => _pushScreen(const ReferralHubScreen()),
                    ),
                    _ControlTile(
                      icon: Icons.history_rounded,
                      label: 'سجل النشاط',
                      showDivider: false,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        showActivityHistory(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupTitle(
          'الخصوصية والأمان',
          Icons.shield_rounded,
          const Color(0xFF6C3FA0),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
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
                    _ControlTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'الخصوصية',
                      showDivider: true,
                      onTap: () => HapticFeedback.selectionClick(),
                    ),
                    _ControlTile(
                      icon: Icons.block_rounded,
                      label: 'الحسابات المحظورة',
                      showDivider: true,
                      onTap: () => HapticFeedback.selectionClick(),
                    ),
                    _ControlToggleTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'الإشعارات',
                      value: _notificationsEnabled,
                      color: BayanColors.accent,
                      showDivider: false,
                      onChanged: (v) {
                        HapticFeedback.mediumImpact();
                        setState(() => _notificationsEnabled = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupTitle(
          'المظهر',
          Icons.palette_rounded,
          const Color(0xFFD4AF37),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
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
                    _ControlToggleTile(
                      icon: Icons.dark_mode_rounded,
                      label: 'الوضع الداكن',
                      value: _darkMode,
                      color: const Color(0xFFD4AF37),
                      showDivider: true,
                      onChanged: (v) {
                        HapticFeedback.mediumImpact();
                        setState(() => _darkMode = v);
                      },
                    ),
                    _ControlTile(
                      icon: Icons.language_rounded,
                      label: 'اللغة',
                      trailing: Text(
                        'العربية',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: BayanColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      showDivider: true,
                      onTap: () => HapticFeedback.selectionClick(),
                    ),
                    _ControlTile(
                      icon: Icons.design_services_rounded,
                      label: 'نظام التصميم',
                      iconColor: BayanColors.accent,
                      showDivider: false,
                      onTap: () => _pushScreen(const DesignSystemScreen()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilityGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupTitle(
          'الشمولية وإمكانية الوصول',
          Icons.accessibility_new_rounded,
          BayanColors.accent,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: HapticButton(
            hapticType: HapticFeedbackType.selection,
            onTap: () => _pushScreen(const AccessibilityScreen()),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        BayanColors.accent.withValues(alpha: 0.08),
                        BayanColors.glassBackground,
                      ],
                    ),
                    border: Border.all(color: BayanColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'أيقونة إمكانية الوصول',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BayanColors.accent.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.accessibility_new_rounded,
                            color: BayanColors.accent,
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
                              'إعدادات إمكانية الوصول',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: BayanColors.textPrimary,
                              ),
                            ),
                            Text(
                              'التباين، حجم الخط، الحركة، الألوان',
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
          ),
        ),
      ],
    );
  }

  Widget _buildSupportGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupTitle(
          'المساعدة',
          Icons.support_agent_rounded,
          const Color(0xFF2A6F97),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
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
                    _ControlTile(
                      icon: Icons.headset_mic_rounded,
                      label: 'كونسيرج بَيَان',
                      iconColor: const Color(0xFFD4AF37),
                      showDivider: true,
                      onTap: () => _pushScreen(const ConciergeScreen()),
                    ),
                    _ControlTile(
                      icon: Icons.info_outline_rounded,
                      label: 'عن بَيَان',
                      showDivider: false,
                      onTap: () => HapticFeedback.selectionClick(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: HapticButton(
        hapticType: HapticFeedbackType.heavy,
        onTap: () => HapticFeedback.heavyImpact(),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool showDivider;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _ControlTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.showDivider,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HapticButton(
          hapticType: HapticFeedbackType.selection,
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Semantics(
                  label: label,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (iconColor ?? BayanColors.textSecondary)
                          .withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? BayanColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: BayanColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing ??
                    const Icon(
                      Icons.chevron_left_rounded,
                      color: BayanColors.textSecondary,
                      size: 22,
                    ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              height: 1,
              color: BayanColors.glassBorder.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}

class _ControlToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color color;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  const _ControlToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.showDivider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Semantics(
                label: label,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: BayanColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Semantics(
                label: '$label تبديل',
                toggled: value,
                child: Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: color.withValues(alpha: 0.3),
                  activeThumbColor: color,
                  inactiveTrackColor: BayanColors.glassBorder,
                  inactiveThumbColor: BayanColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              height: 1,
              color: BayanColors.glassBorder.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}
