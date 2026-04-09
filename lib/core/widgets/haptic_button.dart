import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HapticButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final HapticFeedbackType hapticType;

  const HapticButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.hapticType = HapticFeedbackType.light,
  });

  @override
  State<HapticButton> createState() => _HapticButtonState();
}

enum HapticFeedbackType { light, medium, heavy, selection }

class _HapticButtonState extends State<HapticButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _triggerHaptic() async {
    switch (widget.hapticType) {
      case HapticFeedbackType.light:
        await HapticFeedback.lightImpact();
      case HapticFeedbackType.medium:
        await HapticFeedback.mediumImpact();
      case HapticFeedbackType.heavy:
        await HapticFeedback.heavyImpact();
      case HapticFeedbackType.selection:
        await HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        _triggerHaptic();
        widget.onTap?.call();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
