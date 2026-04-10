import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({super.key});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen>
    with SingleTickerProviderStateMixin {
  static const _codeLength = 6;
  final _controllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isError = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _focusNodes[_codeLength - 1].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _entranceController.dispose();
    super.dispose();
  }

  String get _fullCode => _controllers.map((c) => c.text).join();

  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);

  void _onCodeChanged(int index, String value) {
    if (_isError) setState(() => _isError = false);

    if (value.length == 1 && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (value.isEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  void _onPaste(String pasted) {
    final cleaned = pasted.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleaned.length < _codeLength) return;

    for (var i = 0; i < _codeLength; i++) {
      _controllers[_codeLength - 1 - i].text = cleaned[cleaned.length - 1 - i]
          .toUpperCase();
    }
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  Future<void> _verify() async {
    if (!_isComplete) return;
    HapticFeedback.mediumImpact();
    setState(() => _isVerifying = true);

    // TODO: validate _fullCode against backend
    debugPrint('Verifying code: $_fullCode');
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isVerifying = false;
      _isError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildTopBar(),
                      const Spacer(flex: 2),
                      _buildLockIcon(),
                      const SizedBox(height: 32),
                      _buildTitle(),
                      const SizedBox(height: 40),
                      _buildCodeInput(),
                      if (_isError) _buildErrorMessage(),
                      const SizedBox(height: 36),
                      _buildVerifyButton(),
                      const Spacer(flex: 3),
                      _buildFooterNote(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.4),
          radius: 1.0,
          colors: [
            BayanColors.accent.withValues(alpha: 0.06),
            BayanColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
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
      ],
    );
  }

  Widget _buildLockIcon() {
    return GlassmorphicContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(24),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [BayanColors.accent, Color(0xFF6C3FA0)],
        ).createShader(bounds),
        child: const Icon(
          Icons.verified_user_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'التحقق من الهوية',
          style: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: BayanColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'أدخل رمز الدعوة الحصري',
          style: GoogleFonts.cairo(
            fontSize: 15,
            color: BayanColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_codeLength, (index) {
          final displayIndex = _codeLength - 1 - index;
          final hasValue = _controllers[displayIndex].text.isNotEmpty;
          final isFocused = _focusNodes[displayIndex].hasFocus;

          return Padding(
            padding: EdgeInsets.only(left: index > 0 ? 10 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isError
                        ? Colors.redAccent.withValues(alpha: 0.08)
                        : hasValue
                        ? BayanColors.accent.withValues(alpha: 0.08)
                        : BayanColors.glassBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isError
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : isFocused
                          ? BayanColors.accent
                          : hasValue
                          ? BayanColors.accent.withValues(alpha: 0.3)
                          : BayanColors.glassBorder,
                      width: isFocused ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _controllers[displayIndex],
                      focusNode: _focusNodes[displayIndex],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _isError
                            ? Colors.redAccent
                            : BayanColors.textPrimary,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty) {
                          _controllers[displayIndex].text = v.toUpperCase();
                          _controllers[displayIndex].selection =
                              TextSelection.collapsed(offset: 1);
                        }
                        _onCodeChanged(displayIndex, v);

                        if (v.length > 1) {
                          _onPaste(v);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        'رمز غير صحيح، تحقق وحاول مرة أخرى',
        style: GoogleFonts.cairo(
          fontSize: 13,
          color: Colors.redAccent.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return HapticButton(
      hapticType: HapticFeedbackType.medium,
      onTap: _isComplete && !_isVerifying ? _verify : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: _isComplete ? BayanColors.accent : BayanColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isComplete
              ? [
                  BoxShadow(
                    color: BayanColors.accent.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isVerifying
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: BayanColors.background,
                  ),
                )
              : Text(
                  'تحقّق',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _isComplete
                        ? BayanColors.background
                        : BayanColors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 16,
          color: BayanColors.textSecondary.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 6),
        Text(
          'الدعوات مشفّرة وفريدة لكل عضو',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: BayanColors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
