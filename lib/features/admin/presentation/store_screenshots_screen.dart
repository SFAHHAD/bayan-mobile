import 'dart:math' as math;
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
  _ScreenshotTemplate(
    title: 'بصمتك الصوتية',
    titleEn: 'Your Voice Print',
    description: 'هوية صوتية فريدة تمثّلك',
    icon: Icons.graphic_eq_rounded,
    gradient: [Color(0xFF2A6F97), Color(0xFF6C3FA0)],
    screenType: 'voiceprint',
  ),
];

enum _DeviceFrame { iphone16Pro, android }

class _DeviceSpec {
  final String name;
  final double width;
  final double height;
  final double cornerRadius;
  final double bezelWidth;
  final bool hasDynamicIsland;

  const _DeviceSpec({
    required this.name,
    required this.width,
    required this.height,
    required this.cornerRadius,
    required this.bezelWidth,
    this.hasDynamicIsland = false,
  });
}

const _deviceSpecs = {
  _DeviceFrame.iphone16Pro: _DeviceSpec(
    name: 'iPhone 16 Pro',
    width: 240,
    height: 520,
    cornerRadius: 32,
    bezelWidth: 3,
    hasDynamicIsland: true,
  ),
  _DeviceFrame.android: _DeviceSpec(
    name: 'Android',
    width: 236,
    height: 510,
    cornerRadius: 22,
    bezelWidth: 2.5,
  ),
};

class StoreScreenshotsScreen extends StatefulWidget {
  const StoreScreenshotsScreen({super.key});

  @override
  State<StoreScreenshotsScreen> createState() => _StoreScreenshotsScreenState();
}

class _StoreScreenshotsScreenState extends State<StoreScreenshotsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTemplate = 0;
  bool _isArabic = true;
  bool _showVideoPreview = false;
  _DeviceFrame _selectedDevice = _DeviceFrame.iphone16Pro;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

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
                    const SizedBox(height: 16),
                    _buildVideoToggle(),
                    if (_showVideoPreview) ...[
                      const SizedBox(height: 16),
                      _buildVideoPreview(),
                    ],
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

  Widget _buildDeviceSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _DeviceFrame.values.map((d) {
          final isSelected = _selectedDevice == d;
          final spec = _deviceSpecs[d]!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: HapticButton(
              hapticType: HapticFeedbackType.selection,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDevice = d);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected
                      ? BayanColors.accent.withValues(alpha: 0.12)
                      : BayanColors.glassBackground,
                  border: Border.all(
                    color: isSelected
                        ? BayanColors.accent.withValues(alpha: 0.3)
                        : BayanColors.glassBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      d == _DeviceFrame.iphone16Pro
                          ? Icons.phone_iphone_rounded
                          : Icons.phone_android_rounded,
                      size: 14,
                      color: isSelected
                          ? BayanColors.accent
                          : BayanColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      spec.name,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? BayanColors.accent
                            : BayanColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreview() {
    final tpl = _templates[_selectedTemplate];
    final spec = _deviceSpecs[_selectedDevice]!;
    return Column(
      children: [
        _buildDeviceSelector(),
        Center(
          child: Container(
            width: spec.width,
            height: spec.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(spec.cornerRadius),
              color: Colors.black,
              border: Border.all(
                color: Colors.grey.shade800,
                width: spec.bezelWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: tpl.gradient.first.withValues(alpha: 0.15),
                  blurRadius: 30,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                spec.cornerRadius - spec.bezelWidth,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [tpl.gradient.first, BayanColors.background],
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          SizedBox(height: spec.hasDynamicIsland ? 36 : 24),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: tpl.gradient),
                              boxShadow: [
                                BoxShadow(
                                  color: tpl.gradient.first.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Icon(
                              tpl.icon,
                              color: BayanColors.background,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isArabic ? tpl.title : tpl.titleEn,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: BayanColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tpl.description,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  'assets/Bayan.JPG',
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'بيان',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: BayanColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    if (spec.hasDynamicIsland)
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 90,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
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

  Widget _buildVideoToggle() {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _showVideoPreview = !_showVideoPreview);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _showVideoPreview
              ? BayanColors.accent.withValues(alpha: 0.1)
              : BayanColors.glassBackground,
          border: Border.all(
            color: _showVideoPreview
                ? BayanColors.accent.withValues(alpha: 0.3)
                : BayanColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_rounded,
              color: _showVideoPreview
                  ? BayanColors.accent
                  : BayanColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'معاينة الفيديو التسويقي',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _showVideoPreview
                      ? BayanColors.accent
                      : BayanColors.textPrimary,
                ),
              ),
            ),
            AnimatedRotation(
              turns: _showVideoPreview ? 0.25 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.chevron_left_rounded,
                color: BayanColors.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: BayanColors.glassBackground,
            border: Border.all(color: BayanColors.glassBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _templates[_selectedTemplate].gradient.first.withValues(
                          alpha: 0.15,
                        ),
                        BayanColors.background.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WavePreviewPainter(
                      progress: _waveController.value,
                      color: _templates[_selectedTemplate].gradient.first,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BayanColors.background.withValues(alpha: 0.7),
                          border: Border.all(
                            color: BayanColors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: BayanColors.accent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'معاينة الموجات الحيّة · ١٠ ثوانٍ',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.redAccent.withValues(alpha: 0.15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LOOP',
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

class _WavePreviewPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WavePreviewPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.5;
    const barCount = 40;
    final barWidth = size.width / (barCount * 1.8);
    final spacing = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final phase = (i / barCount + progress) * 2 * math.pi;
      final amplitude =
          (math.sin(phase) * 0.5 + math.sin(phase * 2.3 + 1.2) * 0.3).abs();
      final barHeight = 10 + amplitude * size.height * 0.35;
      final alpha = 0.15 + amplitude * 0.35;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      final x = i * spacing + spacing * 0.3;
      final rRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, centerY),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePreviewPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
