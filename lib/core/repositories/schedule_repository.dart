import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/scheduled_diwan.dart';

class ScheduleRepository {
  final SupabaseClient _client;

  const ScheduleRepository(this._client);

  static const _scheduleTable = 'scheduled_diwans';
  static const _tokenTable = 'device_tokens';

  // -------------------------------------------------------------------------
  // Scheduled Diwans
  // -------------------------------------------------------------------------

  /// Creates a new scheduled entry for [diwanId].
  Future<ScheduledDiwan> scheduleDiwan({
    required String diwanId,
    required String hostId,
    required DateTime startTime,
    int estimatedDurationMinutes = 60,
  }) async {
    final response = await _client
        .from(_scheduleTable)
        .insert({
          'diwan_id': diwanId,
          'host_id': hostId,
          'start_time': startTime.toIso8601String(),
          'estimated_duration_minutes': estimatedDurationMinutes,
        })
        .select()
        .single();
    return ScheduledDiwan.fromMap(response);
  }

  /// Updates start time or duration for an existing schedule.
  Future<ScheduledDiwan> updateSchedule(
    String scheduleId, {
    DateTime? startTime,
    int? estimatedDurationMinutes,
  }) async {
    final updates = <String, dynamic>{};
    if (startTime != null) {
      updates['start_time'] = startTime.toIso8601String();
      updates['reminder_sent'] = false;
    }
    if (estimatedDurationMinutes != null) {
      updates['estimated_duration_minutes'] = estimatedDurationMinutes;
    }
    final response = await _client
        .from(_scheduleTable)
        .update(updates)
        .eq('id', scheduleId)
        .select()
        .single();
    return ScheduledDiwan.fromMap(response);
  }

  /// Soft-cancels a scheduled diwan.
  Future<void> cancelSchedule(String scheduleId) async {
    await _client
        .from(_scheduleTable)
        .update({'is_cancelled': true})
        .eq('id', scheduleId);
  }

  /// Returns all upcoming (non-cancelled) scheduled diwans in the next [days] days.
  Future<List<ScheduledDiwan>> getUpcoming({int days = 7}) async {
    final future = DateTime.now().add(Duration(days: days));
    final data = await _client
        .from(_scheduleTable)
        .select()
        .eq('is_cancelled', false)
        .gte('start_time', DateTime.now().toIso8601String())
        .lte('start_time', future.toIso8601String())
        .order('start_time');
    return (data as List)
        .map((r) => ScheduledDiwan.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns all schedules created by [hostId].
  Future<List<ScheduledDiwan>> getHostSchedules(String hostId) async {
    final data = await _client
        .from(_scheduleTable)
        .select()
        .eq('host_id', hostId)
        .order('start_time', ascending: false);
    return (data as List)
        .map((r) => ScheduledDiwan.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Fetch the schedule for a specific diwan (if any).
  Future<ScheduledDiwan?> getForDiwan(String diwanId) async {
    final data = await _client
        .from(_scheduleTable)
        .select()
        .eq('diwan_id', diwanId)
        .maybeSingle();
    if (data == null) return null;
    return ScheduledDiwan.fromMap(data);
  }

  /// Real-time stream of upcoming schedules.
  Stream<List<ScheduledDiwan>> watchUpcomingSchedules() {
    return _client
        .from(_scheduleTable)
        .stream(primaryKey: ['id'])
        .order('start_time')
        .map(
          (rows) => rows
              .where(
                (r) =>
                    (r['is_cancelled'] as bool? ?? false) == false &&
                    DateTime.parse(
                      r['start_time'] as String,
                    ).isAfter(DateTime.now()),
              )
              .map(ScheduledDiwan.fromMap)
              .toList(),
        );
  }

  // -------------------------------------------------------------------------
  // Device tokens (push notification registration)
  // -------------------------------------------------------------------------

  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    await _client.from(_tokenTable).upsert({
      'user_id': userId,
      'token': token,
      'platform': platform,
    });
  }

  Future<void> removeDeviceToken(String token) async {
    await _client.from(_tokenTable).delete().eq('token', token);
  }
}
