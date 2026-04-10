import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';
import 'package:bayan/features/auth/presentation/providers/invitation_provider.dart';
import 'package:bayan/features/shell/presentation/main_shell.dart';

enum _AuthStep { email, otp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _AuthStep _step = _AuthStep.email;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(userProvider.notifier).sendOtp(_emailController.text.trim());
    if (!mounted) return;
    final session = ref.read(userProvider);
    if (session.errorMessage != null) {
      _showError(session.errorMessage!);
    } else {
      setState(() => _step = _AuthStep.otp);
      _fadeCtrl
        ..reset()
        ..forward();
    }
  }

  Future<void> _onVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(userProvider.notifier)
        .verifyOtp(_emailController.text.trim(), _otpController.text.trim());
    if (!mounted) return;
    if (!ok) {
      _showError(ref.read(userProvider).errorMessage ?? 'خطأ في التحقق');
    } else {
      final userId = ref.read(authRepositoryProvider).currentUser?.id;
      if (userId != null) {
        await ref.read(invitationProvider.notifier).redeemCode(userId);
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: BayanColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: BayanColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: BayanColors.textSecondary,
          ),
          onPressed: () {
            if (_step == _AuthStep.otp) {
              setState(() => _step = _AuthStep.email);
              _fadeCtrl
                ..reset()
                ..forward();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    _step == _AuthStep.email ? 'تسجيل الدخول' : 'أدخل الرمز',
                    style: GoogleFonts.cairo(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: BayanColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step == _AuthStep.email
                        ? 'سنرسل لك رمزاً للتحقق'
                        : 'تحقق من بريدك: ${_emailController.text.trim()}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: BayanColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GlassmorphicContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (_step == _AuthStep.email) ...[
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
                                color: BayanColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                color: BayanColors.accent,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'الرجاء إدخال البريد الإلكتروني';
                              }
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+$',
                              ).hasMatch(v.trim())) {
                                return 'بريد إلكتروني غير صحيح';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: GoogleFonts.cairo(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: BayanColors.textPrimary,
                              letterSpacing: 12,
                            ),
                            decoration: InputDecoration(
                              hintText: '------',
                              counterText: '',
                              hintStyle: TextStyle(
                                color: BayanColors.textSecondary.withValues(
                                  alpha: 0.4,
                                ),
                                letterSpacing: 12,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().length != 6) {
                                return 'الرجاء إدخال الرمز المكوّن من 6 أرقام';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: session.isLoading
                                ? null
                                : (_step == _AuthStep.email
                                      ? _onSendOtp
                                      : _onVerifyOtp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BayanColors.accent,
                              foregroundColor: BayanColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: session.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: BayanColors.background,
                                    ),
                                  )
                                : Text(
                                    _step == _AuthStep.email
                                        ? 'إرسال الرمز'
                                        : 'تحقق والدخول',
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
                  if (_step == _AuthStep.otp) ...[
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: session.isLoading ? null : _onSendOtp,
                      child: Text(
                        'إعادة إرسال الرمز',
                        style: GoogleFonts.cairo(
                          color: BayanColors.accent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
