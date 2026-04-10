import 'package:bayan/core/models/bug_report.dart';
import 'package:bayan/core/repositories/bug_report_repository.dart';
import 'package:bayan/core/repositories/log_repository.dart';

/// High-level service for the "Shake to Report" feature.
///
/// Captures the current screen state, recent system_logs from the DB, and
/// device metadata, then submits a [BugReport] via [BugReportRepository].
class BugReportService {
  final BugReportRepository _repo;
  final LogRepository _logRepo;

  BugReportService(this._repo, this._logRepo);

  // -------------------------------------------------------------------------
  // Shake-to-report entry point
  // -------------------------------------------------------------------------

  /// Captures the current state and submits a bug report.
  ///
  /// [screenName]  — current route name, e.g. '/diwan/abc'.
  /// [screenState] — serialisable snapshot of the current screen state.
  /// [title]       — auto-generated or user-supplied short description.
  /// [description] — optional detailed description.
  /// [severity]    — defaults to [BugSeverity.medium].
  Future<String> submitShakeReport({
    required String screenName,
    Map<String, dynamic> screenState = const {},
    String? title,
    String? description,
    BugSeverity severity = BugSeverity.medium,
  }) async {
    // Fetch the 20 most recent error logs from the DB
    final recentSystemLogs = await _logRepo.fetchRecentErrors(limit: 20);
    final recentLogs = recentSystemLogs
        .map(
          (l) => {
            'id': l.id,
            'severity': l.severity.name,
            'source': l.source,
            'message': l.message,
            'created_at': l.createdAt.toIso8601String(),
          },
        )
        .toList();

    final report = BugReport(
      id: '',
      title: title ?? 'Shake Report — $screenName',
      description: description,
      severity: severity,
      screenName: screenName,
      screenState: screenState,
      appVersion: LogRepository.appVersion,
      platform: LogRepository.platform,
      sessionId: LogRepository.currentSessionId,
      deviceInfo: {
        'app_version': LogRepository.appVersion,
        'platform': LogRepository.platform,
        'session_id': LogRepository.currentSessionId,
      },
      recentLogs: recentLogs,
      createdAt: DateTime.now(),
    );

    return _repo.submit(report);
  }

  /// Submit a fully constructed [BugReport].
  Future<String> submit(BugReport report) => _repo.submit(report);

  /// Fetch all reports submitted by the current user.
  Future<List<BugReport>> fetchMyReports({int limit = 20}) =>
      _repo.fetchMyReports(limit: limit);
}
