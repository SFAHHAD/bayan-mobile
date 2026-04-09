import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bayan/core/theme/theme.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: BayanColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class DiwanFeedSkeleton extends StatelessWidget {
  const DiwanFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BayanColors.surface,
      highlightColor: BayanColors.surface.withValues(alpha: 0.3),
      period: const Duration(milliseconds: 1800),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  ShimmerBox(width: 160, height: 36, borderRadius: 10),
                  Spacer(),
                  ShimmerBox(width: 44, height: 44, borderRadius: 14),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: ShimmerBox(width: 200, height: 18, borderRadius: 8),
            ),
            const SizedBox(height: 24),
            ..._buildCardSkeletons(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCardSkeletons() {
    return List.generate(4, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _GlassCardSkeleton(),
      );
    });
  }
}

class _GlassCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BayanColors.glassBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BayanColors.glassBorder, width: 1),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBox(width: 60, height: 24, borderRadius: 12),
                  SizedBox(width: 10),
                  ShimmerBox(width: 140, height: 20, borderRadius: 8),
                ],
              ),
              SizedBox(height: 12),
              ShimmerBox(width: 120, height: 14, borderRadius: 6),
              SizedBox(height: 16),
              Row(
                children: [
                  ShimmerBox(width: 70, height: 16, borderRadius: 8),
                  SizedBox(width: 12),
                  ShimmerBox(width: 80, height: 16, borderRadius: 8),
                  Spacer(),
                  ShimmerBox(width: 72, height: 38, borderRadius: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BayanColors.surface,
      highlightColor: BayanColors.surface.withValues(alpha: 0.3),
      period: const Duration(milliseconds: 1800),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            color: BayanColors.surface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 56),
          const ShimmerBox(width: 150, height: 28, borderRadius: 10),
          const SizedBox(height: 8),
          const ShimmerBox(width: 100, height: 16, borderRadius: 8),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: BayanColors.glassBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: BayanColors.glassBorder),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ShimmerBox(
              width: double.infinity,
              height: 90,
              borderRadius: 20,
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ShimmerBox(
              width: double.infinity,
              height: 260,
              borderRadius: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BayanColors.surface,
      highlightColor: BayanColors.surface.withValues(alpha: 0.3),
      period: const Duration(milliseconds: 1800),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: ShimmerBox(width: 120, height: 36, borderRadius: 10),
            ),
            const SizedBox(height: 20),
            const ShimmerBox(
              width: double.infinity,
              height: 52,
              borderRadius: 18,
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: ShimmerBox(width: 130, height: 20, borderRadius: 8),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: Row(
                children: List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: ShimmerBox(
                      width: 80 + (i * 10).toDouble(),
                      height: 36,
                      borderRadius: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: ShimmerBox(width: 110, height: 20, borderRadius: 8),
            ),
            const SizedBox(height: 14),
            ...List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerBox(
                  width: double.infinity,
                  height: 72,
                  borderRadius: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
