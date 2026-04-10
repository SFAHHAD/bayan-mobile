import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

// ═══════════════════════════════════════════════════════════════════
//  MAIN ONBOARDING SHELL
// ═══════════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late final AnimationController _dissolveController;

  @override
  void initState() {
    super.initState();
    _dissolveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _dissolveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dissolveController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _completeOnboarding() {
    HapticFeedback.heavyImpact();
    _dissolveController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dissolveController,
      builder: (context, child) {
        final t = Curves.easeInCubic.transform(_dissolveController.value);
        return Opacity(
          opacity: 1.0 - t,
          child: Transform.scale(scale: 1.0 + t * 0.06, child: child),
        );
      },
      child: Scaffold(
        backgroundColor: BayanColors.background,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) {
                HapticFeedback.selectionClick();
                setState(() => _currentPage = p);
              },
              children: [
                _WelcomeRevealScene(onNext: () => _goToPage(1)),
                _PrestigeInterestsScene(onNext: () => _goToPage(2)),
                _AcousticFingerprintScene(
                  onComplete: _completeOnboarding,
                  onSkip: _completeOnboarding,
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: _buildProgressDots(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == _currentPage;
        final isPast = i < _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isActive
                ? const Color(0xFFD4AF37)
                : isPast
                ? BayanColors.accent.withValues(alpha: 0.5)
                : BayanColors.textSecondary.withValues(alpha: 0.18),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SCENE 1 — THE WELCOME REVEAL
// ═══════════════════════════════════════════════════════════════════

class _WelcomeRevealScene extends StatefulWidget {
  final VoidCallback onNext;
  const _WelcomeRevealScene({required this.onNext});

  @override
  State<_WelcomeRevealScene> createState() => _WelcomeRevealSceneState();
}

class _WelcomeRevealSceneState extends State<_WelcomeRevealScene>
    with TickerProviderStateMixin {
  late final AnimationController _featherController;
  late final AnimationController _textController;
  late final AnimationController _glowPulse;
  late final AnimationController _buttonController;

  static const _line1Words = ['مرحباً', 'بك', 'في', 'بيان..'];
  static const _line2Words = ['حيث', 'للصوت', 'هيبة،', 'وللكلمة', 'قيمة.'];

  @override
  void initState() {
    super.initState();
    _featherController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _glowPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _featherController.forward();
        HapticFeedback.mediumImpact();
      }
    });
    _featherController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _textController.forward();
      }
    });
    _textController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _buttonController.forward();
      }
    });
  }

  @override
  void dispose() {
    _featherController.dispose();
    _textController.dispose();
    _glowPulse.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildAmbientGlow(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              children: [
                const Spacer(flex: 3),
                _buildFeatherLogo(),
                const SizedBox(height: 52),
                _buildCinematicText(),
                const Spacer(flex: 4),
                _buildNextButton(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmbientGlow() {
    return AnimatedBuilder(
      animation: _glowPulse,
      builder: (context, _) {
        final p = _glowPulse.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 1.0 + p * 0.15,
              colors: [
                const Color(0xFFD4AF37).withValues(alpha: 0.05 + p * 0.04),
                BayanColors.background,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatherLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_featherController, _glowPulse]),
      builder: (context, _) {
        final scale = CurvedAnimation(
          parent: _featherController,
          curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
        ).value;
        final rotate = Tween<double>(begin: -0.06, end: 0.0)
            .animate(
              CurvedAnimation(
                parent: _featherController,
                curve: Curves.easeOutBack,
              ),
            )
            .value;
        final glowAlpha = 0.18 + _glowPulse.value * 0.14;

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotate,
            child: Container(
              width: 164,
              height: 164,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(42),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: glowAlpha),
                    blurRadius: 64,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: BayanColors.accent.withValues(
                      alpha: glowAlpha * 0.3,
                    ),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(42),
                child: Image.asset(
                  'assets/icon_gold_edition.png',
                  width: 164,
                  height: 164,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCinematicText() {
    final totalWords = _line1Words.length + _line2Words.length;
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, _) {
        return Column(
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                alignment: WrapAlignment.center,
                children: List.generate(_line1Words.length, (i) {
                  final start = i / totalWords;
                  final wp = ((_textController.value - start) / 0.14).clamp(
                    0.0,
                    1.0,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: wp,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - wp)),
                        child: Text(
                          _line1Words[i],
                          style: GoogleFonts.cairo(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: BayanColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                alignment: WrapAlignment.center,
                children: List.generate(_line2Words.length, (i) {
                  final globalIdx = _line1Words.length + i;
                  final start = globalIdx / totalWords;
                  final wp = ((_textController.value - start) / 0.14).clamp(
                    0.0,
                    1.0,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: wp,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - wp)),
                        child: Text(
                          _line2Words[i],
                          style: GoogleFonts.cairo(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: BayanColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNextButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _buttonController,
          curve: Curves.easeOutCubic,
        ).value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: HapticButton(
        hapticType: HapticFeedbackType.medium,
        onTap: widget.onNext,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [BayanColors.accent, Color(0xFF2A9D8F)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: BayanColors.accent.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'التالي',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SCENE 2 — PRESTIGE INTERESTS
// ═══════════════════════════════════════════════════════════════════

class _InterestItem {
  final String label;
  final IconData icon;
  const _InterestItem(this.label, this.icon);
}

const _interests = [
  _InterestItem('الشعر', Icons.menu_book_rounded),
  _InterestItem('التقنية', Icons.computer_rounded),
  _InterestItem('السياسة', Icons.account_balance_rounded),
  _InterestItem('الرياضة', Icons.sports_soccer_rounded),
  _InterestItem('الأعمال', Icons.trending_up_rounded),
  _InterestItem('التعليم', Icons.school_rounded),
  _InterestItem('الفن', Icons.palette_rounded),
  _InterestItem('التاريخ', Icons.history_edu_rounded),
  _InterestItem('الصحة', Icons.favorite_rounded),
  _InterestItem('الفلسفة', Icons.psychology_rounded),
  _InterestItem('الأدب', Icons.auto_stories_rounded),
  _InterestItem('العلوم', Icons.science_rounded),
  _InterestItem('السفر', Icons.flight_rounded),
  _InterestItem('التصميم', Icons.design_services_rounded),
];

class _PrestigeInterestsScene extends StatefulWidget {
  final VoidCallback onNext;
  const _PrestigeInterestsScene({required this.onNext});

  @override
  State<_PrestigeInterestsScene> createState() =>
      _PrestigeInterestsSceneState();
}

class _PrestigeInterestsSceneState extends State<_PrestigeInterestsScene>
    with TickerProviderStateMixin {
  final Set<int> _selected = {};
  late final AnimationController _floatController;
  late final AnimationController _entranceController;
  late final AnimationController _buttonPulse;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _buttonPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entranceController.dispose();
    _buttonPulse.dispose();
    super.dispose();
  }

  bool get _canProceed => _selected.length >= 3;

  void _toggleInterest(int index) {
    HapticFeedback.heavyImpact();
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.6, -0.5),
              radius: 1.2,
              colors: [
                BayanColors.accent.withValues(alpha: 0.05),
                BayanColors.background,
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                _buildHeader(),
                const SizedBox(height: 28),
                Expanded(child: _buildInterestCloud()),
                _buildCounter(),
                const SizedBox(height: 16),
                _buildNextButton(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
        ).value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Text(
            'اختر اهتماماتك',
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ساعدنا لنقدّم لك تجربة مخصّصة',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: BayanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestCloud() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        return Center(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(_interests.length, (i) {
                final phase = i * 0.47;
                final floatY =
                    math.sin(_floatController.value * 2 * math.pi + phase) *
                    3.0;

                final delay = 0.15 + (i / _interests.length) * 0.55;
                final entranceT = CurvedAnimation(
                  parent: _entranceController,
                  curve: Interval(
                    delay.clamp(0.0, 0.75),
                    (delay + 0.3).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                ).value;

                return Opacity(
                  opacity: entranceT,
                  child: Transform.translate(
                    offset: Offset(0, floatY + 14 * (1 - entranceT)),
                    child: _buildChip(i),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(int index) {
    final interest = _interests[index];
    final isSelected = _selected.contains(index);
    const gold = Color(0xFFD4AF37);

    return GestureDetector(
      onTap: () => _toggleInterest(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: isSelected
              ? gold.withValues(alpha: 0.10)
              : BayanColors.glassBackground,
          border: Border.all(
            color: isSelected
                ? gold.withValues(alpha: 0.7)
                : BayanColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: gold.withValues(alpha: 0.18), blurRadius: 14)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              interest.icon,
              size: 16,
              color: isSelected ? gold : BayanColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              interest.label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? gold : BayanColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 14, color: gold),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        _canProceed
            ? '${_selected.length} اهتمامات مختارة'
            : 'اختر ${3 - _selected.length} على الأقل',
        key: ValueKey(_selected.length),
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _canProceed ? BayanColors.accent : BayanColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return AnimatedBuilder(
      animation: _buttonPulse,
      builder: (context, child) {
        final pulse = _canProceed ? _buttonPulse.value : 0.0;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _canProceed ? 1.0 : 0.35,
          child: Container(
            decoration: _canProceed
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: BayanColors.accent.withValues(
                          alpha: 0.2 + pulse * 0.15,
                        ),
                        blurRadius: 16 + pulse * 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  )
                : null,
            child: child,
          ),
        );
      },
      child: HapticButton(
        hapticType: HapticFeedbackType.medium,
        onTap: _canProceed ? widget.onNext : null,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [BayanColors.accent, Color(0xFF2A9D8F)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'التالي',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SCENE 3 — THE ACOUSTIC FINGERPRINT
// ═══════════════════════════════════════════════════════════════════

class _AcousticFingerprintScene extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  const _AcousticFingerprintScene({
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<_AcousticFingerprintScene> createState() =>
      _AcousticFingerprintSceneState();
}

class _AcousticFingerprintSceneState extends State<_AcousticFingerprintScene>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _pulseController;
  late final AnimationController _verifyController;
  late final AnimationController _entranceController;

  final List<double> _amplitudes = [];
  final _rng = math.Random();
  bool _isRecording = false;
  bool _isVerified = false;

  static const int _maxBars = 60;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _maxBars * 75),
    );
    _waveController.addListener(_onWaveTick);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _verifyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _waveController.removeListener(_onWaveTick);
    _waveController.dispose();
    _pulseController.dispose();
    _verifyController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onWaveTick() {
    if (!_isRecording) return;
    final expected = (_waveController.value * _maxBars).floor();
    if (expected > _amplitudes.length) {
      setState(() {
        while (_amplitudes.length < expected) {
          final base = 0.3 + _rng.nextDouble() * 0.5;
          final wave = math.sin(_amplitudes.length * 0.35) * 0.12;
          _amplitudes.add((base + wave).clamp(0.1, 0.95));
        }
      });
    }
    if (_waveController.isCompleted) {
      _stopRecording();
    }
  }

  void _startRecording() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRecording = true;
      _isVerified = false;
      _amplitudes.clear();
    });
    _verifyController.reset();
    _pulseController.repeat(reverse: true);
    _waveController.forward(from: 0);
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    _pulseController.stop();
    _pulseController.animateTo(0);
    _waveController.stop();

    if (_amplitudes.length >= 15) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() => _isVerified = true);
          _verifyController.forward();
          HapticFeedback.heavyImpact();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 0.3),
              radius: 1.3,
              colors: [
                const Color(0xFF6C3FA0).withValues(alpha: 0.05),
                BayanColors.background,
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                _buildHeader(),
                const SizedBox(height: 32),
                Expanded(child: _buildWaveformArea()),
                const SizedBox(height: 24),
                if (!_isVerified) _buildRecordButton(),
                const SizedBox(height: 16),
                _buildBottomAction(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 48),
              ],
            ),
          ),
        ),
        if (_isVerified) _buildVerificationFlash(),
      ],
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
        ).value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  BayanColors.accent.withValues(alpha: 0.15),
                  const Color(0xFF6C3FA0).withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(color: BayanColors.glassBorder),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: BayanColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'تسجيل البصمة الصوتية',
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'سجّل صوتك لتحصل على بصمتك الفريدة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: BayanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformArea() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
        ).value;
        return Opacity(opacity: t, child: child);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: BayanColors.glassBackground,
              border: Border.all(color: BayanColors.glassBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      color: BayanColors.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'البصمة الصوتية',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_isRecording)
                      _buildRecordingBadge()
                    else if (_isVerified)
                      _buildVerifiedBadge(),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _amplitudes.isEmpty && !_isRecording
                      ? _buildEmptyState()
                      : CustomPaint(
                          painter: _LiveWaveformPainter(
                            amplitudes: _amplitudes,
                            totalBars: _maxBars,
                          ),
                          size: Size.infinite,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingBadge() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFE53935).withValues(alpha: 0.12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFFE53935,
                  ).withValues(alpha: 0.6 + _pulseController.value * 0.4),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'تسجيل',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE53935),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: BayanColors.accent.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 12,
            color: BayanColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            'فريدة',
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: BayanColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_none_rounded,
            size: 48,
            color: BayanColors.textSecondary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'اضغط على زر التسجيل لبدء بصمتك',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: BayanColors.textSecondary.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _isRecording ? _pulseController.value : 0.0;
        return GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isRecording
                    ? [const Color(0xFFE53935), const Color(0xFFD32F2F)]
                    : [BayanColors.accent, const Color(0xFF2A9D8F)],
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (_isRecording
                              ? const Color(0xFFE53935)
                              : BayanColors.accent)
                          .withValues(alpha: 0.25 + pulse * 0.2),
                  blurRadius: 20 + pulse * 14,
                  spreadRadius: pulse * 5,
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAction() {
    if (_isVerified) {
      return AnimatedBuilder(
        animation: _verifyController,
        builder: (context, child) {
          final t = CurvedAnimation(
            parent: _verifyController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
          ).value;
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - t)),
              child: child,
            ),
          );
        },
        child: HapticButton(
          hapticType: HapticFeedbackType.heavy,
          onTap: widget.onComplete,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'ابدأ الرحلة',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: BayanColors.background,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Text(
          _isRecording
              ? 'تحدّث بشكل طبيعي...'
              : _amplitudes.isEmpty
              ? 'اضغط على الزر لبدء التسجيل'
              : 'اضغط لإعادة التسجيل',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: BayanColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSkip();
          },
          child: Text(
            'تخطّي',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BayanColors.textSecondary.withValues(alpha: 0.5),
              decoration: TextDecoration.underline,
              decorationColor: BayanColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationFlash() {
    return AnimatedBuilder(
      animation: _verifyController,
      builder: (context, _) {
        final t = _verifyController.value;
        final overlayOpacity = t < 0.5
            ? (t / 0.25).clamp(0.0, 1.0)
            : ((1.0 - t) / 0.5).clamp(0.0, 1.0);

        if (overlayOpacity <= 0.01) return const SizedBox.shrink();

        final checkScale = CurvedAnimation(
          parent: _verifyController,
          curve: const Interval(0.05, 0.45, curve: Curves.elasticOut),
        ).value;

        return IgnorePointer(
          child: Opacity(
            opacity: overlayOpacity,
            child: Container(
              color: BayanColors.background.withValues(alpha: 0.8),
              child: Center(
                child: Transform.scale(
                  scale: checkScale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF2A9D8F), BayanColors.accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: BayanColors.accent.withValues(alpha: 0.45),
                          blurRadius: 48,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LIVE WAVEFORM PAINTER
// ═══════════════════════════════════════════════════════════════════

class _LiveWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final int totalBars;

  _LiveWaveformPainter({required this.amplitudes, required this.totalBars});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final centerY = size.height / 2;
    final barWidth = (size.width / totalBars) * 0.55;
    final spacing = size.width / totalBars;

    for (int i = 0; i < amplitudes.length; i++) {
      final amp = amplitudes[i];
      final barHeight = amp * size.height * 0.85;
      final x = i * spacing + spacing * 0.22;
      final top = centerY - barHeight / 2;

      final t = amplitudes.length > 1 ? i / (amplitudes.length - 1) : 0.0;
      final color = Color.lerp(BayanColors.accent, const Color(0xFFD4AF37), t)!;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.3)],
        ).createShader(Rect.fromLTWH(x, top, barWidth, barHeight))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barWidth, barHeight),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );

      final glowPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(x + barWidth / 2, centerY),
                radius: barHeight * 0.35,
              ),
            )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x + barWidth / 2, centerY),
        barHeight * 0.25,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveWaveformPainter old) =>
      old.amplitudes.length != amplitudes.length;
}
