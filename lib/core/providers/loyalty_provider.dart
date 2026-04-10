import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/user_activity_metrics.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// My metrics (realtime stream)
// -------------------------------------------------------------------------
final myMetricsStreamProvider =
    StreamProvider.autoDispose<UserActivityMetrics?>((ref) {
      return ref.read(loyaltyRepositoryProvider).watchMyMetrics();
    });

// -------------------------------------------------------------------------
// Leaderboard
// -------------------------------------------------------------------------
final leaderboardProvider =
    FutureProvider.autoDispose<List<UserActivityMetrics>>((ref) {
      return ref.read(loyaltyRepositoryProvider).fetchLeaderboard();
    });

// -------------------------------------------------------------------------
// Daily check-in state
// -------------------------------------------------------------------------
class CheckinState {
  final bool isLoading;
  final CheckinResult? lastResult;
  final String? error;

  const CheckinState({this.isLoading = false, this.lastResult, this.error});

  CheckinState copyWith({
    bool? isLoading,
    CheckinResult? lastResult,
    String? error,
    bool clearError = false,
  }) => CheckinState(
    isLoading: isLoading ?? this.isLoading,
    lastResult: lastResult ?? this.lastResult,
    error: clearError ? null : (error ?? this.error),
  );
}

class CheckinNotifier extends AutoDisposeNotifier<CheckinState> {
  @override
  CheckinState build() => const CheckinState();

  Future<void> checkin() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref.read(loyaltyRepositoryProvider).dailyCheckin();
      state = state.copyWith(isLoading: false, lastResult: result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تسجيل تسجيل الوصول اليومي',
      );
    }
  }
}

final checkinProvider =
    NotifierProvider.autoDispose<CheckinNotifier, CheckinState>(
      CheckinNotifier.new,
    );
