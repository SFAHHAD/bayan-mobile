import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bayan/core/theme/theme.dart';

class BayanScrollPhysics extends BouncingScrollPhysics {
  const BayanScrollPhysics({super.parent});

  @override
  BayanScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return BayanScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.4, stiffness: 130, damping: 16);
}

class BayanOverscrollGlow extends StatelessWidget {
  final Widget child;

  const BayanOverscrollGlow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (notification) {
        notification.disallowIndicator();
        return true;
      },
      child: ScrollConfiguration(
        behavior: _BayanScrollBehavior(),
        child: child,
      ),
    );
  }
}

class _BayanScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BayanScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return _GlowOverscrollWidget(child: child);
  }
}

class _GlowOverscrollWidget extends StatefulWidget {
  final Widget child;
  const _GlowOverscrollWidget({required this.child});

  @override
  State<_GlowOverscrollWidget> createState() => _GlowOverscrollWidgetState();
}

class _GlowOverscrollWidgetState extends State<_GlowOverscrollWidget> {
  double _overscrollAmount = 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is OverscrollNotification) {
          setState(() {
            _overscrollAmount =
                (_overscrollAmount + notification.overscroll * 0.3).clamp(
                  -40.0,
                  40.0,
                );
          });
        } else if (notification is ScrollEndNotification) {
          setState(() => _overscrollAmount = 0);
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_overscrollAmount < -2)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildGlow(_overscrollAmount.abs(), false),
            ),
          if (_overscrollAmount > 2)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildGlow(_overscrollAmount, true),
            ),
        ],
      ),
    );
  }

  Widget _buildGlow(double amount, bool isTop) {
    final opacity = (amount / 40).clamp(0.0, 0.4);
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: math.max(amount * 1.5, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [
              BayanColors.accent.withValues(alpha: opacity),
              BayanColors.accent.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
