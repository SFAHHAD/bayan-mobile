import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/system_log.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/services/crash_recovery_service.dart';

// -------------------------------------------------------------------------
// Recent errors (admin / debug view)
// -------------------------------------------------------------------------
final recentErrorsProvider = FutureProvider.autoDispose<List<SystemLog>>((ref) {
  return ref.read(logRepositoryProvider).fetchRecentErrors();
});

// -------------------------------------------------------------------------
// Crash recovery state
// -------------------------------------------------------------------------
class CrashRecoveryState {
  final bool hasCrash;
  final bool isRecovering;
  final RecoveryResult? lastResult;
  final String? error;

  const CrashRecoveryState({
    this.hasCrash = false,
    this.isRecovering = false,
    this.lastResult,
    this.error,
  });

  CrashRecoveryState copyWith({
    bool? hasCrash,
    bool? isRecovering,
    RecoveryResult? lastResult,
    String? error,
    bool clearError = false,
  }) => CrashRecoveryState(
    hasCrash: hasCrash ?? this.hasCrash,
    isRecovering: isRecovering ?? this.isRecovering,
    lastResult: lastResult ?? this.lastResult,
    error: clearError ? null : (error ?? this.error),
  );
}

class CrashRecoveryNotifier extends AutoDisposeNotifier<CrashRecoveryState> {
  @override
  CrashRecoveryState build() {
    _checkCrash();
    return const CrashRecoveryState();
  }

  Future<void> _checkCrash() async {
    final has = await ref.read(crashRecoveryServiceProvider).hasPendingCrash;
    state = state.copyWith(hasCrash: has);
  }

  Future<void> recover() async {
    state = state.copyWith(isRecovering: true, clearError: true);
    try {
      final result = await ref.read(crashRecoveryServiceProvider).recover();
      state = state.copyWith(
        isRecovering: false,
        hasCrash: false,
        lastResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        isRecovering: false,
        error: 'تعذّر استعادة الجلسة',
      );
    }
  }

  Future<void> dismiss() async {
    await ref.read(crashRecoveryServiceProvider).dismissCrash();
    state = state.copyWith(hasCrash: false);
  }
}

final crashRecoveryProvider =
    NotifierProvider.autoDispose<CrashRecoveryNotifier, CrashRecoveryState>(
      CrashRecoveryNotifier.new,
    );
