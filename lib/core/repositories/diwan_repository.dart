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
}
