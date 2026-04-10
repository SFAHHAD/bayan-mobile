import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/system_log.dart';

/// Captures Flutter errors, Dart zone errors, and manual log calls.
/// Persists them to `system_logs` via the `log_system_event` RPC.
class LogRepository {
  final SupabaseClient _client;

  static const _table = 'system_logs';

  /// Injected at app start via [init]; used in metadata on every log.
  static String _appVersion = 'unknown';
  static String _platform = 'unknown';
  static String? _sessionId;

  const LogRepository(this._client);

  // -------------------------------------------------------------------------
  // Initialisation — call once in main()
  // -------------------------------------------------------------------------

  static void configure({
    required String appVersion,
    required String platform,
    String? sessionId,
  }) {
    _appVersion = appVersion;
    _platform = platform;
    _sessionId = sessionId;
  }

  // -------------------------------------------------------------------------
  // Flutter global error hooks
  // -------------------------------------------------------------------------

  /// Installs [FlutterError.onError] and [PlatformDispatcher.instance.onError].
  /// Call after [WidgetsFlutterBinding.ensureInitialized].
  void installGlobalHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _captureFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      captureError(
        source: 'platform_dispatcher',
        message: error.toString(),
        stackTrace: stack.toString(),
        severity: LogSeverity.fatal,
      );
      return true;
    };
  }

  void _captureFlutterError(FlutterErrorDetails details) {
    captureError(
      source: 'flutter_error',
      message: details.exceptionAsString(),
      stackTrace: details.stack?.toString(),
      severity: LogSeverity.error,
      metadata: {
        'library': details.library ?? '',
        'context': details.context?.toString() ?? '',
      },
    );
  }

  // -------------------------------------------------------------------------
  // Manual log API
  // -------------------------------------------------------------------------

  Future<void> log({
    required LogSeverity severity,
    required String source,
    required String message,
    String? stackTrace,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await _client.rpc(
        'log_system_event',
        params: {
          'p_severity': SystemLog.severityToString(severity),
          'p_source': source,
          'p_message': message,
          'p_stack_trace': stackTrace,
          'p_metadata': metadata,
          'p_app_version': _appVersion,
          'p_platform': _platform,
          'p_session_id': _sessionId,
        },
      );
    } catch (_) {
      // Logging must never crash the app
    }
  }

  Future<void> debug(
    String source,
    String message, {
    Map<String, dynamic> metadata = const {},
  }) => log(
    severity: LogSeverity.debug,
    source: source,
    message: message,
    metadata: metadata,
  );

  Future<void> info(
    String source,
    String message, {
    Map<String, dynamic> metadata = const {},
  }) => log(
    severity: LogSeverity.info,
    source: source,
    message: message,
    metadata: metadata,
  );

  Future<void> warning(
    String source,
    String message, {
    Map<String, dynamic> metadata = const {},
  }) => log(
    severity: LogSeverity.warning,
    source: source,
    message: message,
    metadata: metadata,
  );

  Future<void> captureError({
    required String source,
    required String message,
    String? stackTrace,
    LogSeverity severity = LogSeverity.error,
    Map<String, dynamic> metadata = const {},
  }) => log(
    severity: severity,
    source: source,
    message: message,
    stackTrace: stackTrace,
    metadata: metadata,
  );

  /// Wraps an async RPC call, capturing any exception as an error log.
  Future<T?> guardRpc<T>(
    Future<T> Function() call, {
    required String source,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      return await call();
    } catch (e, st) {
      await captureError(
        source: source,
        message: e.toString(),
        stackTrace: st.toString(),
        metadata: metadata,
      );
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Read (admin / debug)
  // -------------------------------------------------------------------------

  Future<List<SystemLog>> fetchRecentErrors({int limit = 50}) async {
    final data = await _client
        .from(_table)
        .select()
        .inFilter('severity', ['error', 'fatal'])
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((r) => SystemLog.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<SystemLog>> fetchMyLogs({int limit = 100}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((r) => SystemLog.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
