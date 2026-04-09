import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/services/database_service.dart';

class WaitlistState {
  final bool isLoading;
  final bool isSubmitted;
  final String? errorMessage;

  const WaitlistState({
    this.isLoading = false,
    this.isSubmitted = false,
    this.errorMessage,
  });

  WaitlistState copyWith({
    bool? isLoading,
    bool? isSubmitted,
    String? errorMessage,
  }) {
    return WaitlistState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: errorMessage,
    );
  }
}

class WaitlistNotifier extends StateNotifier<WaitlistState> {
  final DatabaseService _db;

  WaitlistNotifier(this._db) : super(const WaitlistState());

  Future<void> submitEmail(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _db.addToWaitlist(email);
      state = state.copyWith(isLoading: false, isSubmitted: true);
    } on DuplicateEmailException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'هذا البريد مسجل بالفعل',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'حدث خطأ، حاول مرة أخرى',
      );
    }
  }

  void reset() {
    state = const WaitlistState();
  }
}

final waitlistProvider = StateNotifierProvider<WaitlistNotifier, WaitlistState>(
  (ref) => WaitlistNotifier(ref.read(databaseServiceProvider)),
);
