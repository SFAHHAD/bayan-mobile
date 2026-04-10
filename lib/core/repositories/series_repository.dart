import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/diwan_series.dart';
import 'package:bayan/core/models/series_subscription.dart';
import 'package:bayan/core/models/diwan.dart';

class SeriesRepository {
  final SupabaseClient _client;

  const SeriesRepository(this._client);

  static const _seriesTable = 'diwan_series';
  static const _subTable = 'series_subscriptions';
  static const _diwansTable = 'diwans';

  // -------------------------------------------------------------------------
  // Series CRUD
  // -------------------------------------------------------------------------

  Future<DiwanSeries> createSeries({
    required String title,
    String? description,
    String? coverUrl,
    String? category,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final data = await _client
        .from(_seriesTable)
        .insert({
          'host_id': userId,
          'title': title,
          'description': description,
          'cover_url': coverUrl,
          'category': category,
        })
        .select()
        .single();
    return DiwanSeries.fromMap(data);
  }

  Future<DiwanSeries?> getSeries(String seriesId) async {
    final data = await _client
        .from(_seriesTable)
        .select()
        .eq('id', seriesId)
        .maybeSingle();
    if (data == null) return null;
    return DiwanSeries.fromMap(data);
  }

  Future<List<DiwanSeries>> getHostSeries() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from(_seriesTable)
        .select()
        .eq('host_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((r) => DiwanSeries.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<DiwanSeries>> getAllActiveSeries({int limit = 50}) async {
    final data = await _client
        .from(_seriesTable)
        .select()
        .eq('is_active', true)
        .order('updated_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((r) => DiwanSeries.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateSeries(
    String seriesId,
    Map<String, dynamic> updates,
  ) async {
    await _client.from(_seriesTable).update(updates).eq('id', seriesId);
  }

  Future<void> deleteSeries(String seriesId) async {
    await _client.from(_seriesTable).delete().eq('id', seriesId);
  }

  // -------------------------------------------------------------------------
  // Link / unlink diwans to series
  // -------------------------------------------------------------------------

  Future<void> addDiwanToSeries({
    required String diwanId,
    required String seriesId,
    int? episodeNumber,
  }) async {
    await _client
        .from(_diwansTable)
        .update({'series_id': seriesId, 'episode_number': episodeNumber})
        .eq('id', diwanId);
  }

  Future<void> removeDiwanFromSeries(String diwanId) async {
    await _client
        .from(_diwansTable)
        .update({'series_id': null, 'episode_number': null})
        .eq('id', diwanId);
  }

  Future<List<Diwan>> getDiwansInSeries(String seriesId) async {
    final data = await _client
        .from(_diwansTable)
        .select()
        .eq('series_id', seriesId)
        .order('episode_number', ascending: true);
    return (data as List)
        .map((r) => Diwan.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Subscriptions
  // -------------------------------------------------------------------------

  Future<bool> subscribe(String seriesId, {bool notifyNew = true}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    await _client.from(_subTable).upsert({
      'user_id': userId,
      'series_id': seriesId,
      'notify_new': notifyNew,
    }, onConflict: 'user_id,series_id');
    return true;
  }

  Future<void> unsubscribe(String seriesId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from(_subTable)
        .delete()
        .eq('user_id', userId)
        .eq('series_id', seriesId);
  }

  Future<bool> isSubscribed(String seriesId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final data = await _client
        .from(_subTable)
        .select('id')
        .eq('user_id', userId)
        .eq('series_id', seriesId)
        .maybeSingle();
    return data != null;
  }

  Future<List<SeriesSubscription>> getMySubscriptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from(_subTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((r) => SeriesSubscription.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateNotifyPreference(
    String seriesId, {
    required bool notifyNew,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from(_subTable)
        .update({'notify_new': notifyNew})
        .eq('user_id', userId)
        .eq('series_id', seriesId);
  }

  // -------------------------------------------------------------------------
  // Realtime
  // -------------------------------------------------------------------------

  Stream<List<DiwanSeries>> watchHostSeries() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _client
        .from(_seriesTable)
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map(
          (rows) => rows
              .where((r) => r['host_id'] == userId)
              .map(DiwanSeries.fromMap)
              .toList(),
        );
  }

  Stream<List<Diwan>> watchSeriesEpisodes(String seriesId) {
    return _client
        .from(_diwansTable)
        .stream(primaryKey: ['id'])
        .order('episode_number', ascending: true)
        .map(
          (rows) => rows
              .where((r) => r['series_id'] == seriesId)
              .map(Diwan.fromMap)
              .toList(),
        );
  }
}
