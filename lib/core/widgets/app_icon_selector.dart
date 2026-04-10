import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _AppIconOption {
  final String name;
  final String label;
  final LinearGradient gradient;
  final Color iconColor;
  final Color borderHighlight;

  const _AppIconOption({
    required this.name,
    required this.label,
    required this.gradient,
    required this.iconColor,
    required this.borderHighlight,
  });
}

const _iconOptions = [
  _AppIconOption(
    name: 'default',
    label: 'الافتراضي',
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF3A2050), Color(0xFF1E1035)],
    ),
    iconColor: BayanColors.accent,
    borderHighlight: BayanColors.accent,
  ),
  _AppIconOption(
    name: 'golden',
    label: 'الذهبي',
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF3A2818), Color(0xFF1E1208)],
    ),
    iconColor: Color(0xFFD4AF37),
    borderHighlight: Color(0xFFD4AF37),
  ),
  _AppIconOption(
    name: 'dark',
    label: 'الداكن',
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
    ),
    iconColor: BayanColors.textPrimary,
    borderHighlight: BayanColors.textPrimary,
  ),
];

void showAppIconSelector(BuildContext context) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AppIconSelectorSheet(),
  );
}

class _AppIconSelectorSheet extends StatefulWidget {
  const _AppIconSelectorSheet();

  @override
  State<_AppIconSelectorSheet> createState() => _AppIconSelectorSheetState();
}

class _AppIconSelectorSheetState extends State<_AppIconSelectorSheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: BayanColors.surface.withValues(alpha: 0.96),
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
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BayanColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.app_settings_alt_rounded,
                      color: Color(0xFFD4AF37),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'أيقونة التطبيق',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                      ),
                      child: Text(
                        'حصري',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  'اختر أيقونة تطبيق تعكس أسلوبك كعضو في نادي السيادة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: BayanColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_iconOptions.length, (i) {
                    final opt = _iconOptions[i];
                    final isSelected = _selectedIndex == i;
                    return HapticButton(
                      hapticType: HapticFeedbackType.medium,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _selectedIndex = i);
                      },
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: opt.gradient,
                              border: Border.all(
                                color: isSelected
                                    ? opt.borderHighlight
                                    : BayanColors.glassBorder,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: opt.borderHighlight.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/Bayan.JPG',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  colorBlendMode: opt.name == 'dark'
                                      ? BlendMode.saturation
                                      : null,
                                  color: opt.name == 'dark'
                                      ? Colors.grey
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            opt.label,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? opt.borderHighlight
                                  : BayanColors.textSecondary,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: opt.borderHighlight,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: HapticButton(
                  hapticType: HapticFeedbackType.heavy,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _iconOptions[_selectedIndex].borderHighlight,
                          _iconOptions[_selectedIndex].borderHighlight
                              .withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'تطبيق الأيقونة',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}
