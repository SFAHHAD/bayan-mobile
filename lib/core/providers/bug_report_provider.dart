import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/bug_report.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// My bug reports list
// -------------------------------------------------------------------------

final myBugReportsProvider = FutureProvider.autoDispose<List<BugReport>>((
  ref,
) async {
  return ref.read(bugReportServiceProvider).fetchMyReports();
});

// -------------------------------------------------------------------------
// Submit / shake-to-report notifier
// -------------------------------------------------------------------------

class BugReportState {
  final bool isLoading;
  final bool success;
  final String? error;
  final String? submittedId;

  const BugReportState({
    this.isLoading = false,
    this.success = false,
    this.error,
    this.submittedId,
  });

  BugReportState copyWith({
    bool? isLoading,
    bool? success,
    String? error,
    String? submittedId,
    bool clearError = false,
  }) => BugReportState(
    isLoading: isLoading ?? this.isLoading,
    success: success ?? this.success,
    error: clearError ? null : (error ?? this.error),
    submittedId: submittedId ?? this.submittedId,
  );
}

class BugReportNotifier extends AutoDisposeNotifier<BugReportState> {
  @override
  BugReportState build() => const BugReportState();

  Future<void> submitShakeReport({
    required String screenName,
    Map<String, dynamic> screenState = const {},
    String? title,
    String? description,
    BugSeverity severity = BugSeverity.medium,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, success: false);
    try {
      final id = await ref
          .read(bugReportServiceProvider)
          .submitShakeReport(
            screenName: screenName,
            screenState: screenState,
            title: title,
            description: description,
            severity: severity,
          );
      state = state.copyWith(isLoading: false, success: true, submittedId: id);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر إرسال التقرير: ${e.toString()}',
      );
    }
  }

  void reset() => state = const BugReportState();
}

final bugReportNotifierProvider =
    NotifierProvider.autoDispose<BugReportNotifier, BugReportState>(
      BugReportNotifier.new,
    );
