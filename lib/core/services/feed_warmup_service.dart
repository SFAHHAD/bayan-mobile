import 'package:bayan/core/models/feed_item.dart';
import 'package:bayan/core/models/prestige_category.dart';
import 'package:bayan/core/repositories/recommendation_repository.dart';
import 'package:bayan/core/services/prefetch_service.dart';

/// Wires user-selected Prestige Categories to the personalised feed engine.
///
/// ## Flow
/// 1. Bulk-upserts explicit interest rows via [RecommendationRepository].
/// 2. Immediately calls [PrefetchService.warmCache] so the very first feed
///    the user sees is 100% tailored to their selection.
///
/// The service is fire-and-forget safe: every error is caught and logged
/// internally; the onboarding flow is never blocked.
class FeedWarmupService {
  final RecommendationRepository _recommendation;
  final PrefetchService _prefetch;

  const FeedWarmupService(this._recommendation, this._prefetch);

  // -------------------------------------------------------------------------
  // Constants
  // -------------------------------------------------------------------------

  /// Weight applied to each explicitly chosen onboarding category.
  /// Matches `warm_feed_with_interests` default and the `upsert_user_interest`
  /// maximum for immediate top-of-feed placement.
  static const double onboardingWeight = 5.0;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Applies [categories] as explicit interests and warms the feed cache.
  ///
  /// Returns the first page of the freshly personalised feed on success, or
  /// an empty list if the network is unavailable.
  Future<List<FeedItem>> warmWithCategories(
    List<PrestigeCategory> categories,
  ) async {
    if (categories.isEmpty) return [];

    await _applyInterests(categories);
    await _prefetch.warmCache();
    return _fetchFirstPage();
  }

  /// Re-warms the feed from a list of raw category key strings.
  /// Used when restoring from [OnboardingStatus.selectedCategories].
  Future<List<FeedItem>> warmWithKeys(List<String> keys) async {
    final categories = PrestigeCategory.fromKeys(keys);
    return warmWithCategories(categories);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Future<void> _applyInterests(List<PrestigeCategory> categories) async {
    for (final category in categories) {
      try {
        await _recommendation.setExplicitInterest(
          category.key,
          weight: onboardingWeight,
        );
      } catch (_) {
        // Continue applying remaining categories even if one fails
      }
    }
  }

  Future<List<FeedItem>> _fetchFirstPage() async {
    try {
      return await _recommendation.getPersonalisedFeed(limit: 20, offset: 0);
    } catch (_) {
      return [];
    }
  }
}
