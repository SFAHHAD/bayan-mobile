import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/verification_request.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class VerificationState {
  final VerificationRequest? request;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? successMessage;

  const VerificationState({
    this.request,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  VerificationState copyWith({
    VerificationRequest? request,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) => VerificationState(
    request: request ?? this.request,
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: clearError ? null : (error ?? this.error),
    successMessage: clearSuccess
        ? null
        : (successMessage ?? this.successMessage),
  );

  bool get hasActiveRequest => request != null && request!.isActive;
  bool get isVerified => request?.isApproved ?? false;
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------
class VerificationNotifier extends StateNotifier<VerificationState> {
  final Ref _ref;
  StreamSubscription<VerificationRequest?>? _sub;

  VerificationNotifier(this._ref) : super(const VerificationState()) {
    _init();
  }

  void _init() {
    state = state.copyWith(isLoading: true);
    _sub = _ref.read(verificationRepositoryProvider).watchMyRequest().listen((
      req,
    ) {
      if (mounted) state = state.copyWith(isLoading: false, request: req);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> submitRequest({
    required List<String> documentsUrls,
    required String professionalTitle,
    required String verifiedCategory,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final ok = await _ref
          .read(verificationRepositoryProvider)
          .submitRequest(
            documentsUrls: documentsUrls,
            professionalTitle: professionalTitle,
            verifiedCategory: verifiedCategory,
          );
      state = state.copyWith(
        isSubmitting: false,
        successMessage: ok ? 'تم إرسال طلب التوثيق بنجاح' : null,
        error: ok ? null : 'تعذّر إرسال الطلب',
      );
    } catch (_) {
      state = state.copyWith(isSubmitting: false, error: 'تعذّر إرسال الطلب');
    }
  }

  Future<void> refresh() async {
    final req = await _ref.read(verificationRepositoryProvider).getMyRequest();
    if (mounted) state = state.copyWith(request: req, isLoading: false);
  }
}

final verificationProvider =
    StateNotifierProvider<VerificationNotifier, VerificationState>(
      (ref) => VerificationNotifier(ref),
    );

// -------------------------------------------------------------------------
// Admin: pending requests list
// -------------------------------------------------------------------------
final pendingVerificationsProvider =
    FutureProvider.autoDispose<List<VerificationRequest>>((ref) {
      return ref.read(verificationRepositoryProvider).getPendingRequests();
    });

// -------------------------------------------------------------------------
// Stream for a specific user's request status (for profile pages)
// -------------------------------------------------------------------------
final verificationStreamProvider =
    StreamProvider.autoDispose<VerificationRequest?>((ref) {
      return ref.read(verificationRepositoryProvider).watchMyRequest();
    });
