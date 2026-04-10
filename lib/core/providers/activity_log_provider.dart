import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/activity_log.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/services/privacy_service.dart';

// -------------------------------------------------------------------------
// Privacy service singleton
// -------------------------------------------------------------------------
final privacyServiceProvider = Provider<PrivacyService>((ref) {
  return PrivacyService(ref.read(activityLogRepositoryProvider));
});

// -------------------------------------------------------------------------
// Activity log history
// -------------------------------------------------------------------------
final activityHistoryProvider = FutureProvider.autoDispose<List<ActivityLog>>((
  ref,
) {
  return ref.read(activityLogRepositoryProvider).getMyHistory();
});

// -------------------------------------------------------------------------
// Privacy state
// -------------------------------------------------------------------------
class PrivacyState {
  final bool loggingPaused;
  final bool isLoading;
  final String? successMessage;
  final String? error;

  const PrivacyState({
    this.loggingPaused = false,
    this.isLoading = false,
    this.successMessage,
    this.error,
  });

  PrivacyState copyWith({
    bool? loggingPaused,
    bool? isLoading,
    String? successMessage,
    String? error,
    bool clearMessages = false,
  }) => PrivacyState(
    loggingPaused: loggingPaused ?? this.loggingPaused,
    isLoading: isLoading ?? this.isLoading,
    successMessage: clearMessages
        ? null
        : (successMessage ?? this.successMessage),
    error: clearMessages ? null : (error ?? this.error),
  );
}

class PrivacyNotifier extends AutoDisposeNotifier<PrivacyState> {
  @override
  PrivacyState build() {
    _loadPauseState();
    return const PrivacyState();
  }

  Future<void> _loadPauseState() async {
    final paused = await ref.read(privacyServiceProvider).isLoggingPaused;
    state = state.copyWith(loggingPaused: paused);
  }

  Future<void> toggleLogging() async {
    await ref.read(privacyServiceProvider).toggleLogging();
    await _loadPauseState();
  }

  Future<void> clearHistory() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await ref.read(privacyServiceProvider).clearHistory();
      ref.invalidate(activityHistoryProvider);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'تم حذف سجل النشاط بنجاح',
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر حذف السجل');
    }
  }
}

final privacyProvider =
    NotifierProvider.autoDispose<PrivacyNotifier, PrivacyState>(
      PrivacyNotifier.new,
    );
