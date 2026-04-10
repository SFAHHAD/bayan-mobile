import 'package:hive_flutter/hive_flutter.dart';
import 'package:bayan/core/models/activity_log.dart';
import 'package:bayan/core/repositories/activity_log_repository.dart';

/// Privacy-first service that wraps [ActivityLogRepository].
///
/// - Logging can be paused locally (persisted in Hive) so no server calls are
///   made while paused.
/// - Clear History wipes all server-side logs via RPC.
/// - Pause state is local-only — not synced to server (by design).
/// - Quiet Hours: users can schedule a nightly window when notifications are
///   suppressed. Stored as (startHour, startMinute, endHour, endMinute) in Hive.
class PrivacyService {
  final ActivityLogRepository _repo;

  static const _boxName = 'privacy_prefs';
  static const _keyLoggingPaused = 'logging_paused';
  static const _keyQuietHoursEnabled = 'quiet_hours_enabled';
  static const _keyQuietStartHour = 'quiet_start_hour';
  static const _keyQuietStartMinute = 'quiet_start_minute';
  static const _keyQuietEndHour = 'quiet_end_hour';
  static const _keyQuietEndMinute = 'quiet_end_minute';

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
  // Quiet Hours
  // -------------------------------------------------------------------------

  /// Enables quiet hours from [startHour]:[startMinute] to [endHour]:[endMinute]
  /// (24-h clock, local time).
  Future<void> setQuietHours({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    assert(startHour >= 0 && startHour <= 23);
    assert(startMinute >= 0 && startMinute <= 59);
    assert(endHour >= 0 && endHour <= 23);
    assert(endMinute >= 0 && endMinute <= 59);
    final box = await _openBox();
    await box.put(_keyQuietHoursEnabled, true);
    await box.put(_keyQuietStartHour, startHour);
    await box.put(_keyQuietStartMinute, startMinute);
    await box.put(_keyQuietEndHour, endHour);
    await box.put(_keyQuietEndMinute, endMinute);
  }

  Future<void> disableQuietHours() async {
    final box = await _openBox();
    await box.put(_keyQuietHoursEnabled, false);
  }

  Future<bool> get isQuietHoursEnabled async {
    final box = await _openBox();
    return (box.get(_keyQuietHoursEnabled) as bool?) ?? false;
  }

  /// Returns `true` if [at] (defaults to now) falls within the configured
  /// quiet-hours window. Returns `false` when quiet hours are disabled.
  Future<bool> isInQuietHours({DateTime? at}) async {
    if (!await isQuietHoursEnabled) return false;
    final box = await _openBox();
    final sh = (box.get(_keyQuietStartHour) as int?) ?? 22;
    final sm = (box.get(_keyQuietStartMinute) as int?) ?? 0;
    final eh = (box.get(_keyQuietEndHour) as int?) ?? 7;
    final em = (box.get(_keyQuietEndMinute) as int?) ?? 0;
    return _timeInWindow(at ?? DateTime.now(), sh, sm, eh, em);
  }

  /// Returns the configured quiet window as a human-readable string, e.g. "22:00 – 07:00".
  Future<String?> getQuietHoursLabel() async {
    if (!await isQuietHoursEnabled) return null;
    final box = await _openBox();
    final sh = (box.get(_keyQuietStartHour) as int?) ?? 22;
    final sm = (box.get(_keyQuietStartMinute) as int?) ?? 0;
    final eh = (box.get(_keyQuietEndHour) as int?) ?? 7;
    final em = (box.get(_keyQuietEndMinute) as int?) ?? 0;
    String pad(int h, int m) =>
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    return '${pad(sh, sm)} – ${pad(eh, em)}';
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

  /// Determines whether [now] is within the quiet window [sh:sm – eh:em].
  /// Handles overnight windows (e.g. 22:00 – 07:00).
  /// Exposed as [testTimeInWindow] for unit testing without Hive.
  // ignore: prefer_function_declarations_over_variables
  static bool testTimeInWindow(DateTime now, int sh, int sm, int eh, int em) =>
      _timeInWindow(now, sh, sm, eh, em);

  static bool _timeInWindow(DateTime now, int sh, int sm, int eh, int em) {
    final nowMins = now.hour * 60 + now.minute;
    final startMins = sh * 60 + sm;
    final endMins = eh * 60 + em;

    if (startMins <= endMins) {
      // Same-day window (e.g. 09:00 – 17:00)
      return nowMins >= startMins && nowMins < endMins;
    } else {
      // Overnight window (e.g. 22:00 – 07:00)
      return nowMins >= startMins || nowMins < endMins;
    }
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }
}
