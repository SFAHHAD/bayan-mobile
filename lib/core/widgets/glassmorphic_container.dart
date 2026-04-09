import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bayan/core/theme/theme.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 32,
    this.blur = 20,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: BayanColors.glassBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: BayanColors.glassBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
