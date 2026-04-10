import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';

void showPrestigeLoading(BuildContext context, {String? message}) {
  HapticFeedback.mediumImpact();
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black38,
    builder: (_) => _PrestigeLoadingOverlay(message: message),
  );
}

class _PrestigeLoadingOverlay extends StatefulWidget {
  final String? message;
  const _PrestigeLoadingOverlay({this.message});

  @override
  State<_PrestigeLoadingOverlay> createState() =>
      _PrestigeLoadingOverlayState();
}

class _PrestigeLoadingOverlayState extends State<_PrestigeLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: BayanColors.surface.withValues(alpha: 0.92),
                border: Border.all(
                  color: BayanColors.accent.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: BayanColors.accent.withValues(alpha: 0.08),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        BayanColors.accent.withValues(alpha: 0.8),
                      ),
                      backgroundColor: BayanColors.glassBorder,
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      widget.message!,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BayanColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
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
