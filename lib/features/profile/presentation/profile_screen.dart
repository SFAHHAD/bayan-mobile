import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/founder_glow_badge.dart';
import 'package:bayan/core/widgets/shimmer_skeleton.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: BayanColors.background,
        body: SafeArea(child: ProfileSkeleton()),
      );
    }

    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 32),
              _buildStatsRow(),
              const SizedBox(height: 28),
              const FounderGlowBadge(),
              const SizedBox(height: 28),
              _buildSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BayanColors.accent.withValues(alpha: 0.15),
                BayanColors.background,
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الملف الشخصي',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
              HapticButton(
                hapticType: HapticFeedbackType.selection,
                onTap: () {},
                child: GlassmorphicContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(10),
                  blur: 10,
                  child: const Icon(
                    Icons.edit_rounded,
                    color: BayanColors.accent,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(bottom: -40, child: _buildAvatar()),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: BayanColors.background, width: 4),
        boxShadow: [
          BoxShadow(
            color: BayanColors.accent.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BayanColors.accent.withValues(alpha: 0.3),
                  BayanColors.surface,
                ],
              ),
              border: Border.all(color: BayanColors.glassBorder, width: 1.5),
            ),
            child: Center(
              child: Text(
                'ع',
                style: GoogleFonts.cairo(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: BayanColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 0),
      child: Column(
        children: [
          Text(
            'عبدالله الكندري',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@abdullahk',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: BayanColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '٤٧',
                  label: 'أصوات مشاركة',
                  icon: Icons.mic_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '١٢',
                  label: 'دعوات مرسلة',
                  icon: Icons.card_giftcard_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '٨',
                  label: 'ديوانيّات',
                  icon: Icons.groups_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 12),
            child: Text(
              'الإعدادات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
            ),
          ),
          GlassmorphicContainer(
            borderRadius: 20,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  label: 'تعديل الملف الشخصي',
                  showDivider: true,
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'الإشعارات',
                  showDivider: true,
                ),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'الخصوصية والأمان',
                  showDivider: true,
                ),
                _SettingsTile(
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
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'عن بَيَان',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          HapticButton(
            hapticType: HapticFeedbackType.medium,
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
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
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: BayanColors.accent, size: 22),
          const SizedBox(height: 8),
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
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: BayanColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HapticButton(
          hapticType: HapticFeedbackType.selection,
          onTap: () {},
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: BayanColors.textSecondary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: BayanColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ?trailing,
                if (trailing == null)
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
