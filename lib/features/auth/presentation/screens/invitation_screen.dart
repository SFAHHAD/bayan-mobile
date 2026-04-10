import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/features/auth/presentation/providers/invitation_provider.dart';
import 'package:bayan/features/auth/presentation/screens/auth_screen.dart';

class InvitationScreen extends ConsumerStatefulWidget {
  const InvitationScreen({super.key});

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onValidate() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(invitationProvider.notifier).validateCode(code);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (ctx, a1, a2) => const AuthScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invitationProvider);
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 64),
                    _buildIcon(),
                    const SizedBox(height: 40),
                    _buildTitle(),
                    const SizedBox(height: 48),
                    _buildCodeField(state),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      _buildError(state.error!),
                    ],
                    const SizedBox(height: 32),
                    _buildSubmitButton(state),
                    const Spacer(),
                    _buildFooter(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.0,
            colors: [
              const Color(0xFFD4AF37).withValues(alpha: 0.07),
              BayanColors.background,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return GlassmorphicContainer(
      borderRadius: 36,
      padding: const EdgeInsets.all(28),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFF5CBFAD)],
        ).createShader(bounds),
        child: const Icon(
          Icons.workspace_premium_rounded,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'رمز الدعوة',
          style: GoogleFonts.cairo(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: BayanColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'بيان منصة حصرية بدعوة فقط\nأدخل رمز الدعوة للمتابعة',
          style: GoogleFonts.cairo(
            fontSize: 15,
            color: BayanColors.textSecondary,
            height: 1.7,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCodeField(InvitationState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: BayanColors.glassBackground,
            border: Border.all(
              color: state.error != null
                  ? Colors.redAccent.withValues(alpha: 0.5)
                  : BayanColors.glassBorder,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.robotoMono(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: BayanColors.textPrimary,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              hintText: 'BAYAN-XXXX',
              hintStyle: GoogleFonts.robotoMono(
                fontSize: 18,
                color: BayanColors.textSecondary.withValues(alpha: 0.4),
                letterSpacing: 4,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            onChanged: (_) {
              if (ref.read(invitationProvider).error != null) {
                ref.read(invitationProvider.notifier).reset();
              }
            },
            onSubmitted: (_) => _onValidate(),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: Colors.redAccent,
        ),
        const SizedBox(width: 6),
        Text(
          message,
          style: GoogleFonts.cairo(fontSize: 13, color: Colors.redAccent),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(InvitationState state) {
    return HapticButton(
      hapticType: HapticFeedbackType.medium,
      onTap: state.isLoading ? null : _onValidate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: state.isLoading
                ? [
                    BayanColors.textSecondary.withValues(alpha: 0.3),
                    BayanColors.textSecondary.withValues(alpha: 0.3),
                  ]
                : [const Color(0xFFD4AF37), BayanColors.accent],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: state.isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: state.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'تحقق من الرمز',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'لا تملك رمزاً؟ اطلب من أحد أعضاء بيان دعوتك',
      style: GoogleFonts.cairo(
        fontSize: 13,
        color: BayanColors.textSecondary.withValues(alpha: 0.6),
      ),
      textAlign: TextAlign.center,
    );
  }
}
