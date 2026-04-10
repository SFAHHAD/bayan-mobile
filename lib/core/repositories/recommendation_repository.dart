// NOTE: AI Embedding gap — see migration 010 comment.
// Full vector-similarity personalisation is a future upgrade.
// Current implementation uses get_personalized_feed (tag-based weighting).
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/feed_item.dart';
import 'package:bayan/core/models/user_interest.dart';

class RecommendationRepository {
  final SupabaseClient _client;

  const RecommendationRepository(this._client);

  static const _interestsTable = 'user_interests';
  static const _tagsTable = 'diwan_tags';

  // -------------------------------------------------------------------------
  // Personalised feed
  // -------------------------------------------------------------------------

  /// Returns a paginated personalised feed via the `get_personalized_feed` RPC.
  Future<List<FeedItem>> getPersonalisedFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    final result =
        await _client.rpc(
              'get_personalized_feed',
              params: {'p_limit': limit, 'p_offset': offset},
            )
            as List;
    return result
        .map((r) => FeedItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // User interests
  // -------------------------------------------------------------------------

  Future<List<UserInterest>> getMyInterests() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from(_interestsTable)
        .select()
        .eq('user_id', userId)
        .order('weight', ascending: false);
    return (data as List)
        .map((r) => UserInterest.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Upserts an explicit interest (user picks from settings).
  Future<void> setExplicitInterest(
    String category, {
    double weight = 5.0,
  }) async {
    await _client.rpc(
      'upsert_user_interest',
      params: {
        'p_category': category,
        'p_delta': weight,
        'p_source': 'explicit',
      },
    );
  }

  /// Records an implicit interest signal from engagement (e.g., joining a diwan).
  Future<void> recordImplicitInterest(
    String category, {
    double delta = 0.1,
  }) async {
    await _client.rpc(
      'upsert_user_interest',
      params: {
        'p_category': category,
        'p_delta': delta,
        'p_source': 'implicit',
      },
    );
  }

  Future<void> removeInterest(String category) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from(_interestsTable)
        .delete()
        .eq('user_id', userId)
        .eq('category', category);
  }

  Future<void> clearAllInterests() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from(_interestsTable).delete().eq('user_id', userId);
  }

  // -------------------------------------------------------------------------
  // Diwan tags management (host-facing)
  // -------------------------------------------------------------------------

  Future<void> setDiwanTags(String diwanId, List<String> tags) async {
    await _client.from(_tagsTable).delete().eq('diwan_id', diwanId);
    if (tags.isEmpty) return;
    await _client
        .from(_tagsTable)
        .insert(tags.map((t) => {'diwan_id': diwanId, 'tag': t}).toList());
  }

  Future<List<String>> getDiwanTags(String diwanId) async {
    final data = await _client
        .from(_tagsTable)
        .select('tag')
        .eq('diwan_id', diwanId);
    return (data as List).map((r) => r['tag'] as String).toList();
  }

  // -------------------------------------------------------------------------
  // Trending feed (no auth required — used for logged-out view)
  // -------------------------------------------------------------------------

  Future<List<FeedItem>> getTrendingFeed({int limit = 20}) async {
    final data = await _client
        .from('diwans')
        .select()
        .eq('is_public', true)
        .eq('moderation_status', 'approved')
        .order('listener_count', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((r) {
      final map = r as Map<String, dynamic>;
      return FeedItem(
        diwanId: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        ownerId: map['owner_id'] as String?,
        hostName: map['host_name'] as String?,
        coverUrl: map['cover_url'] as String?,
        isLive: (map['is_live'] as bool?) ?? false,
        isPremium: (map['is_premium'] as bool?) ?? false,
        entryFee: (map['entry_fee'] as int?) ?? 0,
        listenerCount: (map['listener_count'] as int?) ?? 0,
        seriesId: map['series_id'] as String?,
        moderationStatus: (map['moderation_status'] as String?) ?? 'approved',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();
  }
}
