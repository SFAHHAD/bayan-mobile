import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/bug_report.dart';

class BugReportRepository {
  final SupabaseClient _client;

  const BugReportRepository(this._client);

  static const _table = 'bug_reports';

  // -------------------------------------------------------------------------
  // Submit via RPC (attaches auth.uid() server-side)
  // -------------------------------------------------------------------------

  Future<String> submit(BugReport report) async {
    final id = await _client.rpc(
      'submit_bug_report',
      params: {
        'p_title': report.title,
        'p_description': report.description,
        'p_severity': BugReport.severityToString(report.severity),
        'p_screen_name': report.screenName,
        'p_screen_state': report.screenState,
        'p_app_version': report.appVersion,
        'p_platform': report.platform,
        'p_session_id': report.sessionId,
        'p_device_info': report.deviceInfo,
        'p_recent_logs': report.recentLogs,
      },
    );
    return id as String;
  }

  // -------------------------------------------------------------------------
  // Fetch own reports
  // -------------------------------------------------------------------------

  Future<List<BugReport>> fetchMyReports({int limit = 20}) async {
    final data = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((r) => BugReport.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Stream own reports (Realtime)
  // -------------------------------------------------------------------------

  Stream<List<BugReport>> watchMyReports() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('reporter_id', uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => BugReport.fromMap(r)).toList());
  }
}
