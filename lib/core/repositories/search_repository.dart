import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/search_result.dart';

class SearchRepository {
  final SupabaseClient _client;

  const SearchRepository(this._client);

  // -------------------------------------------------------------------------
  // Global search (calls Supabase RPC)
  // -------------------------------------------------------------------------

  /// Searches profiles, diwans, and voices simultaneously.
  /// Requires a minimum of 2 characters to avoid excessive load.
  Future<List<SearchResult>> globalSearch(
    String query, {
    int limit = 15,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final data =
        await _client.rpc(
              'global_search',
              params: {'p_query': trimmed, 'p_limit': limit},
            )
            as List<dynamic>;

    return data
        .map((r) => SearchResult.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Scoped helpers (bypass RPC for targeted lookups)
  // -------------------------------------------------------------------------

  Future<List<SearchResult>> searchProfiles(
    String query, {
    int limit = 10,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final q = '%$trimmed%';
    final data = await _client
        .from('profiles')
        .select('id, display_name, username, bio, avatar_url, follower_count')
        .or('display_name.ilike.$q,username.ilike.$q')
        .limit(limit);
    return (data as List).map((r) {
      final m = r as Map<String, dynamic>;
      return SearchResult(
        entityType: SearchEntityType.profile,
        id: m['id'] as String,
        title:
            (m['display_name'] as String?) ?? (m['username'] as String?) ?? '',
        subtitle: (m['bio'] as String?) ?? '',
        avatarUrl: m['avatar_url'] as String?,
      );
    }).toList();
  }

  Future<List<SearchResult>> searchDiwans(
    String query, {
    int limit = 10,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final q = '%$trimmed%';
    final data = await _client
        .from('diwans')
        .select('id, title, description, cover_url')
        .eq('is_public', true)
        .or('title.ilike.$q,description.ilike.$q')
        .limit(limit);
    return (data as List).map((r) {
      final m = r as Map<String, dynamic>;
      return SearchResult(
        entityType: SearchEntityType.diwan,
        id: m['id'] as String,
        title: (m['title'] as String?) ?? '',
        subtitle: (m['description'] as String?) ?? '',
        avatarUrl: m['cover_url'] as String?,
      );
    }).toList();
  }
}
