import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _ScreenshotTemplate {
  final String title;
  final String titleEn;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final String screenType;

  const _ScreenshotTemplate({
    required this.title,
    required this.titleEn,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.screenType,
  });
}

const _templates = [
  _ScreenshotTemplate(
    title: 'الديوانيّة الحيّة',
    titleEn: 'Live Conversations',
    description: 'استمع وشارك في ديوانيّات صوتية حيّة',
    icon: Icons.mic_rounded,
    gradient: [Color(0xFF5CBFAD), Color(0xFF2A6F97)],
    screenType: 'stage',
  ),
  _ScreenshotTemplate(
    title: 'اكتشف أصواتاً جديدة',
    titleEn: 'Discover New Voices',
    description: 'آلاف المحادثات الملهمة بانتظارك',
    icon: Icons.explore_rounded,
    gradient: [Color(0xFF6C3FA0), Color(0xFF2E1A3E)],
    screenType: 'feed',
  ),
  _ScreenshotTemplate(
    title: 'ملفك الشخصي',
    titleEn: 'Your Voice Profile',
    description: 'بصمتك الصوتية الفريدة',
    icon: Icons.person_rounded,
    gradient: [Color(0xFFD4AF37), Color(0xFF8B5E3C)],
    screenType: 'profile',
  ),
  _ScreenshotTemplate(
    title: 'نادي السيادة',
    titleEn: 'The Sovereign Club',
    description: 'تجربة بلا حدود للنخبة',
    icon: Icons.workspace_premium_rounded,
    gradient: [Color(0xFFD4AF37), Color(0xFF1E1035)],
    screenType: 'sovereign',
  ),
];

class StoreScreenshotsScreen extends StatefulWidget {
  const StoreScreenshotsScreen({super.key});

  @override
  State<StoreScreenshotsScreen> createState() => _StoreScreenshotsScreenState();
}

class _StoreScreenshotsScreenState extends State<StoreScreenshotsScreen> {
  int _selectedTemplate = 0;
  bool _isArabic = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  children: [
                    _buildPreview(),
                    const SizedBox(height: 20),
                    _buildLanguageToggle(),
                    const SizedBox(height: 16),
                    _buildTemplateGrid(),
                    const SizedBox(height: 20),
                    _buildExportButton(),
                  ],
                ),
              ),
            ),
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
                  'لقطات المتجر',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                  ),
                ),
                Text(
                  'Store Screenshots',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.redAccent.withValues(alpha: 0.12),
            ),
            child: Text(
              'Admin',
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final tpl = _templates[_selectedTemplate];
    return Center(
      child: Container(
        width: 240,
        height: 480,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.black,
          border: Border.all(color: Colors.grey.shade800, width: 3),
          boxShadow: [
            BoxShadow(
              color: tpl.gradient.first.withValues(alpha: 0.15),
              blurRadius: 30,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tpl.gradient.first, BayanColors.background],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: tpl.gradient),
                      boxShadow: [
                        BoxShadow(
                          color: tpl.gradient.first.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Icon(
                      tpl.icon,
                      color: BayanColors.background,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isArabic ? tpl.title : tpl.titleEn,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tpl.description,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: BayanColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  _buildMockScreen(tpl),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [BayanColors.accent, Color(0xFFD4AF37)],
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 10,
                          color: BayanColors.background,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'بَيَان',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: BayanColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockScreen(_ScreenshotTemplate tpl) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: BayanColors.glassBackground,
        border: Border.all(color: BayanColors.glassBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: tpl.gradient),
                ),
                child: Icon(tpl.icon, size: 14, color: BayanColors.background),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: BayanColors.glassBorder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 120,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: BayanColors.glassBorder.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: BayanColors.glassBorder.withValues(alpha: 0.3),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LangChip(
          label: 'عربي',
          isSelected: _isArabic,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isArabic = true);
          },
        ),
        const SizedBox(width: 10),
        _LangChip(
          label: 'English',
          isSelected: !_isArabic,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isArabic = false);
          },
        ),
      ],
    );
  }

  Widget _buildTemplateGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: _templates.length,
      itemBuilder: (context, i) {
        final tpl = _templates[i];
        final isSelected = _selectedTemplate == i;
        return HapticButton(
          hapticType: HapticFeedbackType.selection,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedTemplate = i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  tpl.gradient.first.withValues(alpha: 0.2),
                  BayanColors.glassBackground,
                ],
              ),
              border: Border.all(
                color: isSelected
                    ? tpl.gradient.first.withValues(alpha: 0.6)
                    : BayanColors.glassBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tpl.icon, color: tpl.gradient.first, size: 22),
                const SizedBox(height: 6),
                Text(
                  _isArabic ? tpl.title : tpl.titleEn,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportButton() {
    return HapticButton(
      hapticType: HapticFeedbackType.heavy,
      onTap: () => HapticFeedback.heavyImpact(),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _templates[_selectedTemplate].gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _templates[_selectedTemplate].gradient.first.withValues(
                alpha: 0.25,
              ),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download_rounded,
              color: BayanColors.background,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'تصدير اللقطة',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: BayanColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? BayanColors.accent.withValues(alpha: 0.12)
              : BayanColors.glassBackground,
          border: Border.all(
            color: isSelected
                ? BayanColors.accent.withValues(alpha: 0.3)
                : BayanColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? BayanColors.accent : BayanColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
