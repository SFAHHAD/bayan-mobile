import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/repositories/log_repository.dart';
import 'package:bayan/core/models/system_log.dart';

/// Crash Recovery Service
///
/// Uses a Hive-persisted "heartbeat" flag pattern:
/// - On launch: set [_keySessionStarted] = true
/// - On clean close (e.g. app lifecycle dispose): set [_keySessionEnded] = true
/// - On next launch: if started=true AND ended=false → previous session crashed
///
/// When a crash is detected, the UI layer reads [hasPendingCrash] and offers
/// "Clear Cache & Restore Session" via [recover].
class CrashRecoveryService {
  final LogRepository _logger;
  final SupabaseClient _client;

  static const _boxName = 'crash_recovery';
  static const _keySessionStarted = 'session_started';
  static const _keySessionEnded = 'session_ended';
  static const _keyCrashDetected = 'crash_detected';
  static const _keyLastSessionId = 'last_session_id';

  CrashRecoveryService(this._logger, this._client);

  // -------------------------------------------------------------------------
  // Lifecycle hooks — call from main() / app lifecycle observer
  // -------------------------------------------------------------------------

  /// Call once at the very beginning of [main], before any other initialisation.
  /// Returns true if the previous session appears to have crashed.
  Future<bool> onAppStart(String sessionId) async {
    final box = await _openBox();

    final previouslyStarted = (box.get(_keySessionStarted) as bool?) ?? false;
    final previouslyEnded = (box.get(_keySessionEnded) as bool?) ?? true;

    final crashed = previouslyStarted && !previouslyEnded;

    // Record new session
    await box.put(_keySessionStarted, true);
    await box.put(_keySessionEnded, false);
    await box.put(_keyLastSessionId, sessionId);
    if (crashed) {
      await box.put(_keyCrashDetected, true);
      await _logger.captureError(
        source: 'crash_recovery',
        message: 'Previous session did not terminate cleanly — crash suspected',
        severity: LogSeverity.warning,
        metadata: {'previous_session_id': box.get(_keyLastSessionId) ?? ''},
      );
    }

    return crashed;
  }

  /// Call when the app closes cleanly (e.g. AppLifecycleState.detached).
  Future<void> onAppClose() async {
    final box = await _openBox();
    await box.put(_keySessionEnded, true);
  }

  // -------------------------------------------------------------------------
  // State queries
  // -------------------------------------------------------------------------

  Future<bool> get hasPendingCrash async {
    final box = await _openBox();
    return (box.get(_keyCrashDetected) as bool?) ?? false;
  }

  // -------------------------------------------------------------------------
  // Recovery actions
  // -------------------------------------------------------------------------

  /// Clears all Hive caches and acknowledges the crash.
  /// Returns true on success.
  Future<bool> clearCache() async {
    try {
      final boxNames = [_boxName, 'privacy_prefs', 'cache'];
      for (final name in boxNames) {
        final box = Hive.isBoxOpen(name)
            ? Hive.box(name)
            : await Hive.openBox(name);
        await box.clear();
      }
      await _acknowledgeCrash();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Attempts to restore the Supabase session from persisted token.
  /// Returns true if a valid session is available after recovery.
  Future<bool> restoreSession() async {
    try {
      // Supabase persists the session in secure storage automatically.
      // If the client still has a valid session, we're good.
      final session = _client.auth.currentSession;
      if (session != null && !_isExpired(session)) {
        await _logger.info(
          'crash_recovery',
          'Session restored successfully',
          metadata: {'user_id': session.user.id},
        );
        return true;
      }
      // Try refresh
      final refreshed = await _client.auth.refreshSession();
      return refreshed.session != null;
    } catch (e) {
      await _logger.captureError(
        source: 'crash_recovery',
        message: 'Session restore failed: $e',
      );
      return false;
    }
  }

  /// Full recovery: clear cache then restore session.
  /// Returns a [RecoveryResult] describing the outcome.
  Future<RecoveryResult> recover() async {
    final cleared = await clearCache();
    final sessionOk = await restoreSession();
    return RecoveryResult(cacheCleared: cleared, sessionRestored: sessionOk);
  }

  /// Dismiss the crash prompt without taking action.
  Future<void> dismissCrash() async => _acknowledgeCrash();

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  Future<void> _acknowledgeCrash() async {
    final box = await _openBox();
    await box.put(_keyCrashDetected, false);
  }

  bool _isExpired(Session session) {
    final expiry = session.expiresAt;
    if (expiry == null) return false;
    return DateTime.fromMillisecondsSinceEpoch(
      expiry * 1000,
    ).isBefore(DateTime.now());
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }
}

class RecoveryResult {
  final bool cacheCleared;
  final bool sessionRestored;

  const RecoveryResult({
    required this.cacheCleared,
    required this.sessionRestored,
  });

  bool get fullyRecovered => cacheCleared && sessionRestored;

  @override
  String toString() =>
      'RecoveryResult(cacheCleared: $cacheCleared, sessionRestored: $sessionRestored)';
}
