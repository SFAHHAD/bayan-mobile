import 'package:flutter/material.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/features/waitlist/presentation/screens/landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
      _scaleController.forward();
    });

    Future.delayed(const Duration(milliseconds: 4000), _navigateToLanding);
  }

  void _navigateToLanding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => const LandingScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassmorphicContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 36,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/Bayan.JPG',
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'بَيَان',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: BayanColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'قريباً',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: BayanColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
