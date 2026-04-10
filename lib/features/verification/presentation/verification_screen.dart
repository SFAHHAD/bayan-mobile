import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedExpertise;
  bool _hasSubmitted = false;

  late final AnimationController _badgeController;

  static const _expertiseOptions = [
    'أدب وشعر',
    'تقنية وريادة',
    'تعليم وتدريب',
    'إعلام وصحافة',
    'فن وتصميم',
    'علوم ودين',
  ];

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.mediumImpact();
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      setState(() => _hasSubmitted = true);
      HapticFeedback.heavyImpact();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.selectionClick();
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: _hasSubmitted ? _buildSuccessState() : _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildStepIndicator(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildCurrentStep(),
          ),
        ),
        _buildNavBar(),
      ],
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
            child: Text(
              'طلب التوثيق',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: BayanColors.textPrimary,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _badgeController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: const [
                    Color(0xFF2A6F97),
                    BayanColors.accent,
                    Color(0xFF2A6F97),
                  ],
                  stops: [0.0, _badgeController.value, 1.0],
                ).createShader(bounds),
                child: child,
              );
            },
            child: const Icon(
              Icons.verified_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i < 2 ? 8 : 0),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isActive
                          ? BayanColors.accent
                          : BayanColors.glassBorder,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: BayanColors.accent.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ['الهوية', 'الخبرة', 'الإثبات'][i],
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? BayanColors.textPrimary
                          : BayanColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildIdentityStep();
      case 1:
        return _buildExpertiseStep();
      case 2:
        return _buildSocialProofStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdentityStep() {
    return SingleChildScrollView(
      key: const ValueKey('identity'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIcon(
            Icons.person_rounded,
            'الهوية الشخصية',
            'أخبرنا عن نفسك لنتحقق من هويتك',
          ),
          const SizedBox(height: 28),
          _buildLabel('الاسم الكامل'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: BayanColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'أدخل اسمك الكامل',
              hintStyle: GoogleFonts.cairo(color: BayanColors.textSecondary),
              prefixIcon: const Icon(
                Icons.badge_rounded,
                color: BayanColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel('نبذة تعريفية'),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: BayanColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'اكتب نبذة قصيرة عن نفسك وإنجازاتك...',
              hintStyle: GoogleFonts.cairo(
                color: BayanColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildUploadArea('صورة الهوية الرسمية', Icons.credit_card_rounded),
        ],
      ),
    );
  }

  Widget _buildExpertiseStep() {
    return SingleChildScrollView(
      key: const ValueKey('expertise'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIcon(
            Icons.workspace_premium_rounded,
            'مجال الخبرة',
            'حدد مجال تخصصك لمنحك التوثيق المناسب',
          ),
          const SizedBox(height: 28),
          _buildLabel('اختر التخصص'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _expertiseOptions.map((opt) {
              final isSelected = _selectedExpertise == opt;
              return HapticButton(
                hapticType: HapticFeedbackType.selection,
                onTap: () => setState(() => _selectedExpertise = opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isSelected
                        ? BayanColors.accent.withValues(alpha: 0.15)
                        : BayanColors.glassBackground,
                    border: Border.all(
                      color: isSelected
                          ? BayanColors.accent.withValues(alpha: 0.5)
                          : BayanColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? BayanColors.accent
                          : BayanColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          _buildLabel('سنوات الخبرة'),
          const SizedBox(height: 8),
          TextField(
            textDirection: TextDirection.rtl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: BayanColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'مثال: ٥',
              hintStyle: GoogleFonts.cairo(color: BayanColors.textSecondary),
              prefixIcon: const Icon(
                Icons.timeline_rounded,
                color: BayanColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProofStep() {
    return SingleChildScrollView(
      key: const ValueKey('social'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIcon(
            Icons.verified_user_rounded,
            'الإثبات الاجتماعي',
            'أثبت حضورك ومصداقيتك للمجتمع',
          ),
          const SizedBox(height: 28),
          _buildUploadArea(
            'رابط حساب تويتر / X',
            Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 16),
          _buildUploadArea('رابط لينكدإن أو موقعك الشخصي', Icons.link_rounded),
          const SizedBox(height: 16),
          _buildUploadArea('مقال أو ظهور إعلامي', Icons.article_rounded),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFD4AF37).withValues(alpha: 0.06),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD4AF37),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'سيتم مراجعة طلبك خلال ٤٨ ساعة. التوثيق يمنحك ريشة التميز الزرقاء.',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: BayanColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: HapticButton(
                hapticType: HapticFeedbackType.selection,
                onTap: _prevStep,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BayanColors.glassBorder),
                  ),
                  child: Center(
                    child: Text(
                      'السابق',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BayanColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: HapticButton(
              hapticType: HapticFeedbackType.heavy,
              onTap: _nextStep,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _currentStep == 2
                      ? const Color(0xFFD4AF37)
                      : BayanColors.accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_currentStep == 2
                                  ? const Color(0xFFD4AF37)
                                  : BayanColors.accent)
                              .withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _currentStep == 2 ? 'إرسال الطلب' : 'التالي',
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
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _badgeController,
              builder: (context, _) {
                return Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        const Color(0xFF2A6F97).withValues(alpha: 0.3),
                        BayanColors.accent.withValues(alpha: 0.4),
                        const Color(0xFF2A6F97).withValues(alpha: 0.3),
                      ],
                      transform: GradientRotation(
                        _badgeController.value * 2 * math.pi,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: BayanColors.surface,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: BayanColors.accent,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'تم إرسال طلبك!',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: BayanColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم مراجعة طلبك ومنحك ريشة التميز الزرقاء خلال ٤٨ ساعة.',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: BayanColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            HapticButton(
              hapticType: HapticFeedbackType.medium,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: BayanColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'العودة للملف الشخصي',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BayanColors.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIcon(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BayanColors.accent.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: BayanColors.accent, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: BayanColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: BayanColors.textPrimary,
      ),
    );
  }

  Widget _buildUploadArea(String label, IconData icon) {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: BayanColors.glassBackground,
          border: Border.all(color: BayanColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BayanColors.accent.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: BayanColors.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: BayanColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.upload_file_rounded,
              color: BayanColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class BlueFeatherBadge extends StatefulWidget {
  final Widget child;
  final double size;
  final bool isVerified;

  const BlueFeatherBadge({
    super.key,
    required this.child,
    this.size = 96,
    this.isVerified = true,
  });

  @override
  State<BlueFeatherBadge> createState() => _BlueFeatherBadgeState();
}

class _BlueFeatherBadgeState extends State<BlueFeatherBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVerified) return widget.child;

    return SizedBox(
      width: widget.size + 12,
      height: widget.size + 12,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: _BlueFeatherGlowPainter(
                  progress: _shimmerController.value,
                ),
                size: Size(widget.size + 12, widget.size + 12),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(-2.0 + _shimmerController.value * 4, -0.5),
                  end: Alignment(-1.0 + _shimmerController.value * 4, 0.5),
                  colors: const [
                    Color(0x00FFFFFF),
                    Color(0x30FFFFFF),
                    Color(0x00FFFFFF),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds),
                blendMode: BlendMode.srcATop,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: widget.child,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: const [
                      Color(0xFF2A6F97),
                      BayanColors.accent,
                      Color(0xFF2A6F97),
                    ],
                    stops: [0.0, _shimmerController.value, 1.0],
                  ).createShader(bounds),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BayanColors.surface,
                      border: Border.all(
                        color: BayanColors.background,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BlueFeatherGlowPainter extends CustomPainter {
  final double progress;
  _BlueFeatherGlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF2A6F97).withValues(alpha: 0.0),
          BayanColors.accent.withValues(alpha: 0.5),
          const Color(0xFF2A6F97).withValues(alpha: 0.0),
        ],
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_BlueFeatherGlowPainter old) => old.progress != progress;
}
