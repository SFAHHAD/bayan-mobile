import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class DiwanThemeData {
  final String id;
  final String name;
  final String nameEn;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final LinearGradient headerGradient;
  final IconData icon;

  const DiwanThemeData({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.headerGradient,
    required this.icon,
  });
}

const diwanThemes = [
  DiwanThemeData(
    id: 'royal_desert',
    name: 'الصحراء الملكية',
    nameEn: 'Royal Desert',
    primary: Color(0xFFD4AF37),
    secondary: Color(0xFF8B5E3C),
    accent: Color(0xFFE8C97A),
    background: Color(0xFF1C1408),
    surface: Color(0xFF2A1E10),
    textPrimary: Color(0xFFF5EDE0),
    textSecondary: Color(0xFFBEA882),
    headerGradient: LinearGradient(
      colors: [Color(0xFF3A2818), Color(0xFF1C1408)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    icon: Icons.wb_sunny_rounded,
  ),
  DiwanThemeData(
    id: 'midnight_oasis',
    name: 'واحة منتصف الليل',
    nameEn: 'Midnight Oasis',
    primary: Color(0xFF1E3A5F),
    secondary: Color(0xFF5CBFAD),
    accent: Color(0xFF7DD4C4),
    background: Color(0xFF0A1628),
    surface: Color(0xFF122240),
    textPrimary: Color(0xFFE0EFF5),
    textSecondary: Color(0xFF8AACBE),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0D2040), Color(0xFF0A1628)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    icon: Icons.nightlight_rounded,
  ),
  DiwanThemeData(
    id: 'modern_majlis',
    name: 'المجلس العصري',
    nameEn: 'Modern Majlis',
    primary: Color(0xFFC0C0C0),
    secondary: Color(0xFF808080),
    accent: Color(0xFFE8E8E8),
    background: Color(0xFF1A1A1A),
    surface: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFF0F0F0),
    textSecondary: Color(0xFF9E9E9E),
    headerGradient: LinearGradient(
      colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    icon: Icons.weekend_rounded,
  ),
];

void showThemeSelector(
  BuildContext context, {
  ValueChanged<DiwanThemeData>? onSelected,
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ThemeSelectorSheet(onSelected: onSelected),
  );
}

class _ThemeSelectorSheet extends StatefulWidget {
  final ValueChanged<DiwanThemeData>? onSelected;
  const _ThemeSelectorSheet({this.onSelected});

  @override
  State<_ThemeSelectorSheet> createState() => _ThemeSelectorSheetState();
}

class _ThemeSelectorSheetState extends State<_ThemeSelectorSheet> {
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
                    Semantics(
                      label: 'هوية المجلس البصرية',
                      child: const Icon(
                        Icons.palette_rounded,
                        color: BayanColors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الهوية البصرية للمجلس',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'اختر هوية بصرية مميزة لديوانيّتك',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ),
              ...List.generate(diwanThemes.length, (i) {
                final theme = diwanThemes[i];
                final isSelected = _selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: HapticButton(
                    hapticType: HapticFeedbackType.medium,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _selectedIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [theme.surface, theme.background],
                        ),
                        border: Border.all(
                          color: isSelected
                              ? theme.primary.withValues(alpha: 0.6)
                              : BayanColors.glassBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.primary.withValues(alpha: 0.15),
                                  blurRadius: 14,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primary.withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              theme.icon,
                              color: theme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theme.name,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textPrimary,
                                  ),
                                ),
                                Text(
                                  theme.nameEn,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dot(theme.primary),
                              const SizedBox(width: 4),
                              _dot(theme.secondary),
                              const SizedBox(width: 4),
                              _dot(theme.accent),
                            ],
                          ),
                          const SizedBox(width: 10),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? theme.primary
                                  : BayanColors.glassBorder,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: theme.background,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: HapticButton(
                  hapticType: HapticFeedbackType.heavy,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    widget.onSelected?.call(diwanThemes[_selectedIndex]);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: diwanThemes[_selectedIndex].primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'تطبيق الهوية',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: diwanThemes[_selectedIndex].background,
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

  Widget _dot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
    );
  }
}
