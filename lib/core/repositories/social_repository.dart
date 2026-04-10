import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/follow.dart';
import 'package:bayan/core/models/profile.dart';

class SocialRepository {
  final SupabaseClient _client;

  const SocialRepository(this._client);

  static const _followsTable = 'follows';
  static const _profilesTable = 'profiles';

  // -------------------------------------------------------------------------
  // Follow / Unfollow
  // -------------------------------------------------------------------------

  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {
    await _client.from(_followsTable).upsert({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    await _client
        .from(_followsTable)
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  /// Returns true if [followerId] is currently following [followingId].
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    final data = await _client
        .from(_followsTable)
        .select('follower_id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return data != null;
  }

  // -------------------------------------------------------------------------
  // Followers / Following lists
  // -------------------------------------------------------------------------

  Future<List<Profile>> getFollowers(String userId) async {
    final data = await _client
        .from(_followsTable)
        .select('profiles!follows_follower_id_fkey(*)')
        .eq('following_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((row) => Profile.fromMap(row['profiles'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Profile>> getFollowing(String userId) async {
    final data = await _client
        .from(_followsTable)
        .select('profiles!follows_following_id_fkey(*)')
        .eq('follower_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((row) => Profile.fromMap(row['profiles'] as Map<String, dynamic>))
        .toList();
  }

  /// Returns profiles that both [userA] and [userB] are following
  /// (mutual connections), via the `get_mutual_friends` RPC.
  Future<List<Profile>> getMutualFriends(String userA, String userB) async {
    final data =
        await _client.rpc(
              'get_mutual_friends',
              params: {'p_user_a': userA, 'p_user_b': userB},
            )
            as List<dynamic>;
    return data.map((row) {
      final m = row as Map<String, dynamic>;
      return Profile(
        id: m['user_id'] as String,
        displayName: m['display_name'] as String?,
        username: m['username'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Real-time follow status stream
  // -------------------------------------------------------------------------

  Stream<bool> watchIsFollowing({
    required String followerId,
    required String followingId,
  }) {
    return _client
        .from(_followsTable)
        .stream(primaryKey: ['follower_id', 'following_id'])
        .map(
          (rows) => rows.any(
            (r) =>
                r['follower_id'] == followerId &&
                r['following_id'] == followingId,
          ),
        );
  }

  // -------------------------------------------------------------------------
  // Profile with social counts (calls profiles table directly)
  // -------------------------------------------------------------------------

  Future<Profile?> getProfileWithStats(String userId) async {
    final data = await _client
        .from(_profilesTable)
        .select(
          'id, username, display_name, bio, avatar_url, is_founder, '
          'follower_count, following_count, voice_count, created_at',
        )
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }

  // -------------------------------------------------------------------------
  // Follow record model helpers
  // -------------------------------------------------------------------------

  Future<List<Follow>> getRawFollows(String userId) async {
    final data = await _client
        .from(_followsTable)
        .select()
        .eq('follower_id', userId);
    return (data as List)
        .map((r) => Follow.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
