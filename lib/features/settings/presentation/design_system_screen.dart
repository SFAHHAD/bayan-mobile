import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/pulsing_dot.dart';

class DesignSystemScreen extends StatelessWidget {
  const DesignSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildColorPalette()),
            SliverToBoxAdapter(child: _buildTypography()),
            SliverToBoxAdapter(child: _buildButtons()),
            SliverToBoxAdapter(child: _buildGlassCards()),
            SliverToBoxAdapter(child: _buildBadges()),
            SliverToBoxAdapter(child: _buildInputs()),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نظام التصميم',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
                Text(
                  'Bayan Design System',
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
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: BayanColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    const colors = [
      ('Background', BayanColors.background, '#241231'),
      ('Surface', BayanColors.surface, '#2E1A3E'),
      ('Accent / Teal', BayanColors.accent, '#5CBFAD'),
      ('Accent Light', BayanColors.accentLight, '#7DD4C4'),
      ('Founder Gold', Color(0xFFD4AF37), '#D4AF37'),
      ('Royal Purple', Color(0xFF6C3FA0), '#6C3FA0'),
      ('Deep Blue', Color(0xFF2A6F97), '#2A6F97'),
      ('Text Primary', BayanColors.textPrimary, '#F5F0FA'),
      ('Text Secondary', BayanColors.textSecondary, '#B8A9C9'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('لوحة الألوان'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors.map((c) {
              return Container(
                width: 100,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: BayanColors.glassBackground,
                  border: Border.all(color: BayanColors.glassBorder),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.$2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.$1,
                      style: GoogleFonts.cairo(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: BayanColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      c.$3,
                      style: GoogleFonts.cairo(
                        fontSize: 8,
                        color: BayanColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTypography() {
    final styles = [
      ('عنوان رئيسي', 32, FontWeight.w800),
      ('عنوان فرعي', 22, FontWeight.w700),
      ('نص عادي', 15, FontWeight.w500),
      ('نص ثانوي', 13, FontWeight.w500),
      ('تسمية صغيرة', 11, FontWeight.w600),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('الطباعة - Cairo Font'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassmorphicContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: styles.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.$1,
                          style: GoogleFonts.cairo(
                            fontSize: s.$2.toDouble(),
                            fontWeight: s.$3,
                            color: BayanColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${s.$2}px',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('الأزرار'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              HapticButton(
                hapticType: HapticFeedbackType.heavy,
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: BayanColors.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: BayanColors.accent.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'زر رئيسي — Primary',
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
                hapticType: HapticFeedbackType.heavy,
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFB8960F)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'زر ذهبي — Gold',
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
                hapticType: HapticFeedbackType.selection,
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BayanColors.glassBorder),
                  ),
                  child: Center(
                    child: Text(
                      'زر ثانوي — Secondary',
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
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'زر خطير — Destructive',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('البطاقات الزجاجية'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              GlassmorphicContainer(
                borderRadius: 22,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: BayanColors.accent.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: BayanColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بطاقة زجاجية',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Glassmorphic Card',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: BayanColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PulsingDot(color: BayanColors.accent, size: 8),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          BayanColors.accent.withValues(alpha: 0.15),
                          BayanColors.surface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: BayanColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'بطاقة متدرجة',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: BayanColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Gradient Card',
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
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: BayanColors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ادخل',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.background,
                            ),
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
      ],
    );
  }

  Widget _buildBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('الشارات والعلامات'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _badge('مباشر', BayanColors.accent, Icons.circle, 6),
              _badge(
                'مؤسس',
                const Color(0xFFD4AF37),
                Icons.workspace_premium_rounded,
                14,
              ),
              _badge(
                'موثّق',
                const Color(0xFF2A6F97),
                Icons.verified_rounded,
                14,
              ),
              _badge(
                'Hi-Fi',
                const Color(0xFFD4AF37),
                Icons.graphic_eq_rounded,
                12,
              ),
              _badge('مضيف', BayanColors.accent, Icons.star_rounded, 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color, IconData icon, double iconSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('حقول الإدخال'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              TextField(
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: BayanColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'حقل إدخال عادي',
                  hintStyle: GoogleFonts.cairo(
                    color: BayanColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: BayanColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: BayanColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'حقل مع أيقونة',
                  hintStyle: GoogleFonts.cairo(
                    color: BayanColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_rounded,
                    color: BayanColors.accent,
                  ),
                  suffixIcon: const Icon(
                    Icons.check_circle_rounded,
                    color: BayanColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
