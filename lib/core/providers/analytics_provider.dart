import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/user_stats.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class AnalyticsState {
  final UserStats? stats;
  final bool isLoading;
  final String? error;

  const AnalyticsState({this.stats, this.isLoading = false, this.error});

  AnalyticsState copyWith({
    UserStats? stats,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AnalyticsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref _ref;

  AnalyticsNotifier(this._ref) : super(const AnalyticsState()) {
    _loadMyStats();
  }

  Future<void> _loadMyStats() async {
    final userId = _ref.read(userProvider).user?.id;
    if (userId == null) return;
    await fetchStatsFor(userId);
  }

  Future<void> fetchStatsFor(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final stats = await _ref
          .read(analyticsRepositoryProvider)
          .getUserStats(userId);
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'تعذّر تحميل الإحصائيات');
    }
  }

  Future<void> refresh() async {
    final userId = _ref.read(userProvider).user?.id;
    if (userId == null) return;
    await fetchStatsFor(userId);
  }
}

// -------------------------------------------------------------------------
// Providers
// -------------------------------------------------------------------------
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
      (ref) => AnalyticsNotifier(ref),
    );

/// Fetches stats for any user ID on demand (for profile screens).
final userStatsProvider = FutureProvider.autoDispose.family<UserStats, String>((
  ref,
  userId,
) {
  return ref.read(analyticsRepositoryProvider).getUserStats(userId);
});

/// Top-10 profiles by influence score.
final topInfluenceProvider = FutureProvider.autoDispose<List<UserStats>>(
  (ref) => ref.read(analyticsRepositoryProvider).getTopByInfluence(),
);
