import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/profile.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class SocialState {
  final List<Profile> followers;
  final List<Profile> following;
  final bool isLoading;
  final String? error;

  const SocialState({
    this.followers = const [],
    this.following = const [],
    this.isLoading = false,
    this.error,
  });

  SocialState copyWith({
    List<Profile>? followers,
    List<Profile>? following,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SocialState(
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class SocialNotifier extends StateNotifier<SocialState> {
  final Ref _ref;

  SocialNotifier(this._ref) : super(const SocialState());

  String? get _myId => _ref.read(userProvider).user?.id;

  Future<void> loadMyGraph() async {
    final me = _myId;
    if (me == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(socialRepositoryProvider);
      final results = await Future.wait([
        repo.getFollowers(me),
        repo.getFollowing(me),
      ]);
      state = state.copyWith(
        followers: results[0],
        following: results[1],
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر تحميل المتابعين');
    }
  }

  Future<void> followUser(String targetId) async {
    final me = _myId;
    if (me == null) return;
    await _ref
        .read(socialRepositoryProvider)
        .followUser(followerId: me, followingId: targetId);
    await loadMyGraph();
  }

  Future<void> unfollowUser(String targetId) async {
    final me = _myId;
    if (me == null) return;
    await _ref
        .read(socialRepositoryProvider)
        .unfollowUser(followerId: me, followingId: targetId);
    await loadMyGraph();
  }

  Future<bool> isFollowing(String targetId) async {
    final me = _myId;
    if (me == null) return false;
    return _ref
        .read(socialRepositoryProvider)
        .isFollowing(followerId: me, followingId: targetId);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final socialProvider = StateNotifierProvider<SocialNotifier, SocialState>(
  (ref) => SocialNotifier(ref),
);

/// Provider for checking follow status of a specific user (auto-disposes).
final isFollowingProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  targetId,
) async {
  final myId = ref.read(userProvider).user?.id;
  if (myId == null) return false;
  return ref
      .read(socialRepositoryProvider)
      .isFollowing(followerId: myId, followingId: targetId);
});

/// Provider for mutual friends between current user and [targetId].
final mutualFriendsProvider = FutureProvider.autoDispose
    .family<List<Profile>, String>((ref, targetId) async {
      final myId = ref.read(userProvider).user?.id;
      if (myId == null) return [];
      return ref
          .read(socialRepositoryProvider)
          .getMutualFriends(myId, targetId);
    });
