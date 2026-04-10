import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientAccent;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientAccent,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.auto_stories_rounded,
    title: 'مرحباً ببيان',
    subtitle:
        'منصة الديوانيّات الرقميّة الأولى\nمساحة عربية راقية للحوار والمعرفة',
    gradientAccent: [Color(0xFF5CBFAD), Color(0xFF2A6F97)],
  ),
  _OnboardingPage(
    icon: Icons.graphic_eq_rounded,
    title: 'أصوات مختارة',
    subtitle: 'استمع لأرقى الحوارات العربية\nمحتوى حصري من نخبة المتحدثين',
    gradientAccent: [Color(0xFF6C3FA0), Color(0xFF5CBFAD)],
  ),
  _OnboardingPage(
    icon: Icons.workspace_premium_rounded,
    title: 'انضم للنخبة',
    subtitle: 'عضوية حصرية بدعوة فقط\nكن من المؤسسين الأوائل',
    gradientAccent: [Color(0xFFD4AF37), Color(0xFF5CBFAD)],
  ),
];

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _iconRotation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _iconController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _goNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      HapticFeedback.mediumImpact();
      widget.onComplete();
    }
  }

  void _onPageChanged(int page) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = page);
    _iconController.reset();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _iconController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildSkipButton(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) => _buildPage(_pages[index]),
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    final page = _pages[_currentPage];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [
            page.gradientAccent.first.withValues(alpha: 0.08),
            BayanColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPage < _pages.length - 1)
            HapticButton(
              hapticType: HapticFeedbackType.selection,
              onTap: widget.onComplete,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: BayanColors.glassBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BayanColors.glassBorder),
                ),
                child: Text(
                  'تخطّي',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _iconScale,
            child: RotationTransition(
              turns: _iconRotation,
              child: GlassmorphicContainer(
                borderRadius: 36,
                padding: const EdgeInsets.all(32),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: page.gradientAccent,
                  ).createShader(bounds),
                  child: Icon(page.icon, size: 72, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: BayanColors.textSecondary,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLast = _currentPage == _pages.length - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        children: [
          _buildDotIndicator(),
          const SizedBox(height: 32),
          HapticButton(
            hapticType: isLast
                ? HapticFeedbackType.medium
                : HapticFeedbackType.light,
            onTap: _goNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _pages[_currentPage].gradientAccent,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _pages[_currentPage].gradientAccent.first.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isLast ? 'ابدأ الآن' : 'التالي',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? _pages[_currentPage].gradientAccent.first
                : BayanColors.textSecondary.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}
