import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/scheduled_diwan.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class ScheduleState {
  final List<ScheduledDiwan> upcoming;
  final bool isLoading;
  final String? error;

  const ScheduleState({
    this.upcoming = const [],
    this.isLoading = false,
    this.error,
  });

  ScheduleState copyWith({
    List<ScheduledDiwan>? upcoming,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => ScheduleState(
    upcoming: upcoming ?? this.upcoming,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------
class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final Ref _ref;

  ScheduleNotifier(this._ref) : super(const ScheduleState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _ref.read(scheduleRepositoryProvider).getUpcoming();
      state = state.copyWith(upcoming: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر تحميل الجدول');
    }
  }

  Future<void> refresh() => _load();

  Future<ScheduledDiwan?> scheduleDiwan({
    required String diwanId,
    required DateTime startTime,
    int durationMinutes = 60,
  }) async {
    final userId = _ref.read(userProvider).user?.id;
    if (userId == null) return null;
    try {
      final item = await _ref
          .read(scheduleRepositoryProvider)
          .scheduleDiwan(
            diwanId: diwanId,
            hostId: userId,
            startTime: startTime,
            estimatedDurationMinutes: durationMinutes,
          );
      state = state.copyWith(upcoming: [...state.upcoming, item]);
      return item;
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelSchedule(String scheduleId) async {
    await _ref.read(scheduleRepositoryProvider).cancelSchedule(scheduleId);
    state = state.copyWith(
      upcoming: state.upcoming.where((s) => s.id != scheduleId).toList(),
    );
  }
}

// -------------------------------------------------------------------------
// Providers
// -------------------------------------------------------------------------
final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>(
  (ref) => ScheduleNotifier(ref),
);

/// Upcoming schedules as a real-time stream.
final upcomingSchedulesStreamProvider =
    StreamProvider.autoDispose<List<ScheduledDiwan>>(
      (ref) => ref.read(scheduleRepositoryProvider).watchUpcomingSchedules(),
    );

/// Schedule for a specific diwan.
final diwanScheduleProvider = FutureProvider.autoDispose
    .family<ScheduledDiwan?, String>(
      (ref, diwanId) =>
          ref.read(scheduleRepositoryProvider).getForDiwan(diwanId),
    );
