import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/features/diwan/presentation/diwan_feed_screen.dart';
import 'package:bayan/features/search/presentation/search_screen.dart';
import 'package:bayan/features/profile/presentation/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [DiwanFeedScreen(), SearchScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: BayanColors.background.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: BayanColors.glassBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 4,
            top: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'الديوانيّات',
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'استكشف',
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'حسابي',
                isSelected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: BayanColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? BayanColors.accent
                  : BayanColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? BayanColors.accent
                    : BayanColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
