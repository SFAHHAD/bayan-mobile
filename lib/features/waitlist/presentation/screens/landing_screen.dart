import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/features/waitlist/presentation/providers/waitlist_provider.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(waitlistProvider.notifier)
        .submitEmail(_emailController.text.trim());

    if (!mounted) return;
    final state = ref.read(waitlistProvider);
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!, textAlign: TextAlign.center),
          backgroundColor: BayanColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (state.isSubmitted) {
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: BayanColors.background,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'تم تسجيلك بنجاح!',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w600,
                  color: BayanColors.background,
                ),
              ),
            ],
          ),
          backgroundColor: BayanColors.accent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitted = ref.watch(
      waitlistProvider.select((s) => s.isSubmitted),
    );
    final isLoading = ref.watch(waitlistProvider.select((s) => s.isLoading));

    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildLogoSection(),
                  const SizedBox(height: 48),
                  _buildHeadline(),
                  const SizedBox(height: 16),
                  _buildSubtitle(),
                  const SizedBox(height: 48),
                  isSubmitted
                      ? _buildSuccessState()
                      : _buildEmailForm(isLoading),
                  const SizedBox(height: 60),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 32,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/Bayan.JPG',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    return Text(
      'بيان',
      style: GoogleFonts.cairo(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: BayanColors.textPrimary,
        height: 1.1,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: BayanColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            'قريباً',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BayanColors.accent,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'منصة المحتوى العربي الراقي',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 18,
            color: BayanColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'انضم لقائمة الانتظار واحصل على دعوة حصرية',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: BayanColors.textSecondary.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm(bool isLoading) {
    return GlassmorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              'انضم لقائمة الانتظار',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BayanColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BayanColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'بريدك الإلكتروني',
                hintStyle: TextStyle(
                  color: BayanColors.textSecondary.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(
                  Icons.mail_outline_rounded,
                  color: BayanColors.accent,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال بريدك الإلكتروني';
                }
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'بريد إلكتروني غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BayanColors.accent,
                  foregroundColor: BayanColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: BayanColors.background,
                        ),
                      )
                    : Text(
                        'احجز مكانك',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return GlassmorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BayanColors.accent.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: BayanColors.accent,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'تم تسجيلك بنجاح',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: BayanColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سنرسل لك دعوة حصرية عند الإطلاق',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: BayanColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      '© 2026 Bayan. All rights reserved.',
      style: GoogleFonts.cairo(
        fontSize: 12,
        color: BayanColors.textSecondary.withValues(alpha: 0.4),
      ),
    );
  }
}
