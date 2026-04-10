import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/profile.dart';
import 'package:bayan/core/repositories/base_repository.dart';

class ProfileRepository implements BaseRepository<Profile> {
  final SupabaseClient _client;

  const ProfileRepository(this._client);

  static const _table = 'profiles';

  static const _fullSelect =
      'id, username, display_name, bio, avatar_url, is_founder, '
      'follower_count, following_count, voice_count, created_at';

  @override
  Future<List<Profile>> getAll() async {
    final data = await _client
        .from(_table)
        .select(_fullSelect)
        .order('created_at', ascending: false);
    return data.map(Profile.fromMap).toList();
  }

  Future<Profile?> getByUsername(String username) async {
    final data = await _client
        .from(_table)
        .select(_fullSelect)
        .eq('username', username)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }

  @override
  Future<Profile?> getById(String id) async {
    final data = await _client
        .from(_table)
        .select(_fullSelect)
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }

  /// Fetches a profile including up-to-date social counters.
  Future<Profile?> getProfileWithStats(String id) => getById(id);

  /// Search profiles by display name or username (case-insensitive).
  Future<List<Profile>> search(String query) async {
    final q = '%${query.toLowerCase()}%';
    final data = await _client
        .from(_table)
        .select(_fullSelect)
        .or('display_name.ilike.$q,username.ilike.$q')
        .limit(20);
    return data.map(Profile.fromMap).toList();
  }

  @override
  Future<Profile> create(Map<String, dynamic> data) async {
    final response = await _client.from(_table).insert(data).select().single();
    return Profile.fromMap(response);
  }

  @override
  Future<Profile> update(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from(_table)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Profile.fromMap(response);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
