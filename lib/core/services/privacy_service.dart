import 'package:hive_flutter/hive_flutter.dart';
import 'package:bayan/core/models/activity_log.dart';
import 'package:bayan/core/repositories/activity_log_repository.dart';

/// Privacy-first service that wraps [ActivityLogRepository].
///
/// - Logging can be paused locally (persisted in Hive) so no server calls are
///   made while paused.
/// - Clear History wipes all server-side logs via RPC.
/// - Pause state is local-only — not synced to server (by design).
class PrivacyService {
  final ActivityLogRepository _repo;

  static const _boxName = 'privacy_prefs';
  static const _keyLoggingPaused = 'logging_paused';

  PrivacyService(this._repo);

  // -------------------------------------------------------------------------
  // Pause / resume
  // -------------------------------------------------------------------------

  Future<bool> get isLoggingPaused async {
    final box = await _openBox();
    return (box.get(_keyLoggingPaused) as bool?) ?? false;
  }

  Future<void> pauseLogging() async {
    final box = await _openBox();
    await box.put(_keyLoggingPaused, true);
  }

  Future<void> resumeLogging() async {
    final box = await _openBox();
    await box.put(_keyLoggingPaused, false);
  }

  Future<void> toggleLogging() async {
    final paused = await isLoggingPaused;
    if (paused) {
      await resumeLogging();
    } else {
      await pauseLogging();
    }
  }

  // -------------------------------------------------------------------------
  // Logging (no-op when paused)
  // -------------------------------------------------------------------------

  Future<void> log(
    ActivityLogType type, {
    Map<String, dynamic> metadata = const {},
  }) async {
    if (await isLoggingPaused) return;
    await _repo.log(type, metadata: metadata);
  }

  Future<void> logJoinedDiwan(String diwanId, {String? seriesId}) async {
    if (await isLoggingPaused) return;
    await _repo.logJoinedDiwan(diwanId, seriesId: seriesId);
  }

  Future<void> logPurchasedTicket(String diwanId, int price) async {
    if (await isLoggingPaused) return;
    await _repo.logPurchasedTicket(diwanId, price);
  }

  Future<void> logFollowedUser(String targetUserId) async {
    if (await isLoggingPaused) return;
    await _repo.logFollowedUser(targetUserId);
  }

  Future<void> logUnfollowedUser(String targetUserId) async {
    if (await isLoggingPaused) return;
    await _repo.logUnfollowedUser(targetUserId);
  }

  // -------------------------------------------------------------------------
  // Clear history
  // -------------------------------------------------------------------------

  /// Permanently deletes all server-side activity logs for the current user.
  Future<void> clearHistory() async {
    await _repo.clearHistory();
  }

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }
}
