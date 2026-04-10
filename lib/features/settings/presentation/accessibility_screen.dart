import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  bool _highContrast = false;
  bool _largeText = false;
  bool _reducedMotion = false;
  int _paletteIndex = 0;

  static const _palettes = [
    _PaletteOption(
      name: 'افتراضي',
      primary: BayanColors.accent,
      secondary: Color(0xFF6C3FA0),
      tertiary: Color(0xFFD4AF37),
    ),
    _PaletteOption(
      name: 'عمى أحمر-أخضر',
      primary: Color(0xFF56B4E9),
      secondary: Color(0xFFCC79A7),
      tertiary: Color(0xFFE69F00),
    ),
    _PaletteOption(
      name: 'عمى أزرق-أصفر',
      primary: Color(0xFF009E73),
      secondary: Color(0xFFD55E00),
      tertiary: Color(0xFFF0E442),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildVisualSection()),
            SliverToBoxAdapter(child: _buildMotionSection()),
            SliverToBoxAdapter(child: _buildPaletteSection()),
            SliverToBoxAdapter(child: _buildScreenReaderInfo()),
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
                  'الشمولية',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
                Text(
                  'إعدادات إمكانية الوصول',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'أيقونة إمكانية الوصول',
            child: Container(
              padding: const EdgeInsets.all(10),
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
        ],
      ),
    );
  }

  Widget _buildVisualSection() {
    return _buildSection(
      title: 'العرض المرئي',
      icon: Icons.visibility_rounded,
      children: [
        _ToggleTile(
          icon: Icons.contrast_rounded,
          label: 'وضع التباين العالي',
          subtitle: 'ألوان أوضح لتمييز العناصر',
          semanticsLabel: 'تفعيل وضع التباين العالي',
          value: _highContrast,
          color: BayanColors.accent,
          onChanged: (v) {
            HapticFeedback.mediumImpact();
            setState(() => _highContrast = v);
          },
        ),
        _ToggleTile(
          icon: Icons.text_increase_rounded,
          label: 'نص كبير',
          subtitle: 'تكبير حجم الخط في كامل التطبيق',
          semanticsLabel: 'تفعيل النص الكبير',
          value: _largeText,
          color: const Color(0xFFD4AF37),
          onChanged: (v) {
            HapticFeedback.mediumImpact();
            setState(() => _largeText = v);
          },
        ),
      ],
    );
  }

  Widget _buildMotionSection() {
    return _buildSection(
      title: 'الحركة والرسوم',
      icon: Icons.animation_rounded,
      children: [
        _ToggleTile(
          icon: Icons.motion_photos_off_rounded,
          label: 'تقليل الحركة',
          subtitle: 'تعطيل الرسوم المتحركة غير الضرورية',
          semanticsLabel: 'تفعيل تقليل الحركة',
          value: _reducedMotion,
          color: const Color(0xFF6C3FA0),
          onChanged: (v) {
            HapticFeedback.mediumImpact();
            setState(() => _reducedMotion = v);
          },
        ),
      ],
    );
  }

  Widget _buildPaletteSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.palette_rounded,
                  color: BayanColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'لوحة الألوان',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_palettes.length, (i) {
            final p = _palettes[i];
            final isSelected = _paletteIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HapticButton(
                hapticType: HapticFeedbackType.medium,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _paletteIndex = i);
                },
                child: Semantics(
                  label: 'لوحة ألوان ${p.name}',
                  selected: isSelected,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: BayanColors.glassBackground,
                      border: Border.all(
                        color: isSelected
                            ? p.primary.withValues(alpha: 0.5)
                            : BayanColors.glassBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _ColorDot(color: p.primary),
                        const SizedBox(width: 6),
                        _ColorDot(color: p.secondary),
                        const SizedBox(width: 6),
                        _ColorDot(color: p.tertiary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            p.name,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: BayanColors.textPrimary,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? p.primary
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
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScreenReaderInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Semantics(
        label: 'معلومات عن دعم قارئ الشاشة',
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: BayanColors.accent.withValues(alpha: 0.06),
            border: Border.all(
              color: BayanColors.accent.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Semantics(
                label: 'أيقونة قارئ الشاشة',
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BayanColors.accent.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.record_voice_over_rounded,
                    color: BayanColors.accent,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دعم قارئ الشاشة',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                    Text(
                      'بَيَان يدعم VoiceOver و TalkBack بالكامل',
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
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 14),
            child: Row(
              children: [
                Icon(icon, color: BayanColors.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _PaletteOption {
  final String name;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  const _PaletteOption({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String semanticsLabel;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.semanticsLabel,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: semanticsLabel,
        toggled: value,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: BayanColors.glassBackground,
            border: Border.all(color: BayanColors.glassBorder),
          ),
          child: Row(
            children: [
              Semantics(
                label: label,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
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
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: color.withValues(alpha: 0.3),
                activeThumbColor: color,
                inactiveTrackColor: BayanColors.glassBorder,
                inactiveThumbColor: BayanColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
