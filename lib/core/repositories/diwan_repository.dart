import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/diwan.dart';
import 'package:bayan/core/repositories/base_repository.dart';

class DiwanRepository implements BaseRepository<Diwan> {
  final SupabaseClient _client;

  const DiwanRepository(this._client);

  static const _table = 'diwans';

  @override
  Future<List<Diwan>> getAll() async {
    final data = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return data.map(Diwan.fromMap).toList();
  }

  Future<List<Diwan>> getPublic() async {
    final data = await _client
        .from(_table)
        .select()
        .eq('is_public', true)
        .order('created_at', ascending: false);
    return data.map(Diwan.fromMap).toList();
  }

  Future<List<Diwan>> getByOwner(String ownerId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return data.map(Diwan.fromMap).toList();
  }

  @override
  Future<Diwan?> getById(String id) async {
    final data = await _client.from(_table).select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Diwan.fromMap(data);
  }

  @override
  Future<Diwan> create(Map<String, dynamic> data) async {
    final response = await _client.from(_table).insert(data).select().single();
    return Diwan.fromMap(response);
  }

  @override
  Future<Diwan> update(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from(_table)
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .select()
        .single();
    return Diwan.fromMap(response);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Real-time stream — auto-updates on INSERT / UPDATE / DELETE via
  /// Supabase Realtime. Filters public diwans and orders by live status.
  Stream<List<Diwan>> watchPublicDiwans() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('is_live', ascending: false)
        .map(
          (rows) => rows
              .where((r) => (r['is_public'] as bool?) == true)
              .map(Diwan.fromMap)
              .toList(),
        );
  }

  // -------------------------------------------------------------------------
  // Cursor-based pagination
  // -------------------------------------------------------------------------

  /// Returns a page of public diwans older than [before] (cursor by created_at).
  Future<List<Diwan>> getPublicPaged({DateTime? before, int limit = 15}) async {
    var query = _client.from(_table).select().eq('is_public', true);
    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }
    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List)
        .map((r) => Diwan.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Trending
  // -------------------------------------------------------------------------

  /// Returns diwans sorted by hotness score via `get_trending_diwans` RPC.
  Future<List<Diwan>> getTrending({int limit = 20}) async {
    final data =
        await _client.rpc('get_trending_diwans', params: {'p_limit': limit})
            as List<dynamic>;
    return data.map((r) => Diwan.fromMap(r as Map<String, dynamic>)).toList();
  }

  // -------------------------------------------------------------------------
  // Tags
  // -------------------------------------------------------------------------

  /// Returns public diwans that have the given [tagId] attached.
  Future<List<Diwan>> getDiwansByTag(String tagId) async {
    final data = await _client
        .from('diwan_tags')
        .select('diwans(*)')
        .eq('tag_id', tagId);
    return (data as List)
        .map((r) => Diwan.fromMap(r['diwans'] as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Live operations
  // -------------------------------------------------------------------------

  /// Called when a user enters a Diwan room.
  /// Delegates to the Supabase RPC defined in migration 002.
  Future<void> incrementListenerCount(String diwanId) async {
    await _client.rpc(
      'increment_listener_count',
      params: {'p_diwan_id': diwanId},
    );
  }

  /// Called when a user leaves a Diwan room.
  Future<void> decrementListenerCount(String diwanId) async {
    await _client.rpc(
      'decrement_listener_count',
      params: {'p_diwan_id': diwanId},
    );
  }
}
