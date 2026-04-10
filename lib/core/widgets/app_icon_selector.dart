import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _AppIconOption {
  final String name;
  final String label;
  final String subtitle;
  final String assetPath;
  final Color accentColor;
  final Color bgColor;

  const _AppIconOption({
    required this.name,
    required this.label,
    required this.subtitle,
    required this.assetPath,
    required this.accentColor,
    required this.bgColor,
  });
}

const _iconOptions = [
  _AppIconOption(
    name: 'gold',
    label: 'الذهبي',
    subtitle: 'Gold Edition',
    assetPath: 'assets/icon_gold_edition.png',
    accentColor: Color(0xFFD4AF37),
    bgColor: Color(0xFF0A0A0A),
  ),
  _AppIconOption(
    name: 'platinum',
    label: 'البلاتيني',
    subtitle: 'Platinum Edition',
    assetPath: 'assets/icon_platinum_edition.png',
    accentColor: Color(0xFFA8B4C0),
    bgColor: Color(0xFF0A1628),
  ),
  _AppIconOption(
    name: 'classic',
    label: 'الكلاسيكي',
    subtitle: 'Classic Edition',
    assetPath: 'assets/icon_classic_edition.png',
    accentColor: BayanColors.accent,
    bgColor: Color(0xFF5CBFAD),
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

class _AppIconSelectorSheetState extends State<_AppIconSelectorSheet>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: BayanColors.surface.withValues(alpha: 0.97),
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
              _buildHandle(),
              _buildHeader(),
              const SizedBox(height: 6),
              _buildHeroPreview(),
              const SizedBox(height: 20),
              _buildIconRow(),
              const SizedBox(height: 20),
              _buildApplyButton(),
              SizedBox(height: bottomPad + 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: BayanColors.glassBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  const Color(0xFFD4AF37).withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.diamond_rounded,
                  size: 10,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(width: 4),
                Text(
                  'UHD',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
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

  Widget _buildHeroPreview() {
    final opt = _iconOptions[_selectedIndex];
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final scale = Curves.easeOutBack.transform(
          _entranceController.value.clamp(0.0, 1.0),
        );
        return Transform.scale(scale: 0.5 + scale * 0.5, child: child);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        child: _buildIPhoneIcon(
          key: ValueKey(opt.name),
          assetPath: opt.assetPath,
          accentColor: opt.accentColor,
          size: 140,
          showShadow: true,
        ),
      ),
    );
  }

  Widget _buildIPhoneIcon({
    required Key key,
    required String assetPath,
    required Color accentColor,
    required double size,
    bool showShadow = false,
  }) {
    final radius = size * 0.2237;
    return Container(
      key: key,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(assetPath, fit: BoxFit.cover),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_iconOptions.length, (i) {
          final opt = _iconOptions[i];
          final isSelected = _selectedIndex == i;

          final itemDelay = 0.15 + i * 0.12;
          final itemAnim = CurvedAnimation(
            parent: _entranceController,
            curve: Interval(
              itemDelay,
              (itemDelay + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          );

          return AnimatedBuilder(
            animation: itemAnim,
            builder: (context, child) {
              return Opacity(
                opacity: itemAnim.value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - itemAnim.value)),
                  child: child,
                ),
              );
            },
            child: HapticButton(
              hapticType: HapticFeedbackType.medium,
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _selectedIndex = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected
                      ? opt.accentColor.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? opt.accentColor.withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    _buildIPhoneIcon(
                      key: ValueKey('${opt.name}_thumb'),
                      assetPath: opt.assetPath,
                      accentColor: opt.accentColor,
                      size: 68,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      opt.label,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? opt.accentColor
                            : BayanColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt.subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? opt.accentColor.withValues(alpha: 0.6)
                            : BayanColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 8 : 0,
                      height: isSelected ? 8 : 0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: opt.accentColor,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: opt.accentColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildApplyButton() {
    final opt = _iconOptions[_selectedIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: HapticButton(
        hapticType: HapticFeedbackType.heavy,
        onTap: () {
          HapticFeedback.heavyImpact();
          Navigator.of(context).pop();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [opt.accentColor, opt.accentColor.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: opt.accentColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: opt.bgColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'تطبيق الأيقونة',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: opt.bgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
