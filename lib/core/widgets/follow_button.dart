import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';

class FollowButton extends StatefulWidget {
  final bool initialFollowing;
  final ValueChanged<bool>? onChanged;

  const FollowButton({
    super.key,
    this.initialFollowing = false,
    this.onChanged,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton>
    with SingleTickerProviderStateMixin {
  late bool _isFollowing;
  late final AnimationController _morphController;
  late final Animation<double> _widthAnim;
  late final Animation<double> _colorAnim;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initialFollowing;
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _widthAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeOutCubic),
    );
    _colorAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeInOut),
    );

    if (_isFollowing) _morphController.value = 1.0;
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() => _isFollowing = !_isFollowing);
    if (_isFollowing) {
      _morphController.forward();
    } else {
      _morphController.reverse();
    }
    widget.onChanged?.call(_isFollowing);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _morphController,
        builder: (context, child) {
          final bgColor = Color.lerp(
            BayanColors.accent,
            BayanColors.glassBackground,
            _colorAnim.value,
          )!;
          final borderColor = Color.lerp(
            BayanColors.accent,
            BayanColors.glassBorder,
            _colorAnim.value,
          )!;
          final textColor = Color.lerp(
            BayanColors.background,
            BayanColors.accent,
            _colorAnim.value,
          )!;

          final iconScale = _widthAnim.value;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: !_isFollowing
                  ? [
                      BoxShadow(
                        color: BayanColors.accent.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconScale > 0.3)
                  Opacity(
                    opacity: iconScale.clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16 * iconScale,
                        color: textColor,
                      ),
                    ),
                  ),
                Text(
                  _isFollowing ? 'مُتابَع' : 'متابعة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
