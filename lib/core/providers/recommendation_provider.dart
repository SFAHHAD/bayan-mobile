import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/feed_item.dart';
import 'package:bayan/core/models/user_interest.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// Personalised feed (cursor-based pagination)
// -------------------------------------------------------------------------
class FeedState {
  final List<FeedItem> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int _offset;

  const FeedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    int offset = 0,
  }) : _offset = offset;

  int get offset => _offset;

  FeedState copyWith({
    List<FeedItem>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool clearError = false,
    int? offset,
  }) => FeedState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
    offset: offset ?? _offset,
  );
}

class FeedNotifier extends AutoDisposeNotifier<FeedState> {
  static const _pageSize = 20;

  @override
  FeedState build() {
    _loadInitial();
    return const FeedState(isLoading: true);
  }

  Future<void> _loadInitial() async {
    try {
      final items = await ref
          .read(recommendationRepositoryProvider)
          .getPersonalisedFeed(limit: _pageSize, offset: 0);
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == _pageSize,
        offset: items.length,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر تحميل الخلاصة');
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final more = await ref
          .read(recommendationRepositoryProvider)
          .getPersonalisedFeed(limit: _pageSize, offset: state.offset);
      state = state.copyWith(
        items: [...state.items, ...more],
        isLoading: false,
        hasMore: more.length == _pageSize,
        offset: state.offset + more.length,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر تحميل المزيد');
    }
  }

  Future<void> refresh() async {
    state = const FeedState(isLoading: true);
    await _loadInitial();
  }
}

final feedProvider = NotifierProvider.autoDispose<FeedNotifier, FeedState>(
  FeedNotifier.new,
);

// -------------------------------------------------------------------------
// Trending feed (no auth)
// -------------------------------------------------------------------------
final trendingFeedProvider = FutureProvider.autoDispose<List<FeedItem>>((ref) {
  return ref.read(recommendationRepositoryProvider).getTrendingFeed();
});

// -------------------------------------------------------------------------
// User interests
// -------------------------------------------------------------------------
final myInterestsProvider = FutureProvider.autoDispose<List<UserInterest>>((
  ref,
) {
  return ref.read(recommendationRepositoryProvider).getMyInterests();
});

// -------------------------------------------------------------------------
// Interests management
// -------------------------------------------------------------------------
class InterestsNotifier extends AutoDisposeNotifier<List<UserInterest>> {
  @override
  List<UserInterest> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final interests = await ref
        .read(recommendationRepositoryProvider)
        .getMyInterests();
    state = interests;
  }

  Future<void> addExplicit(String category, {double weight = 5.0}) async {
    await ref
        .read(recommendationRepositoryProvider)
        .setExplicitInterest(category, weight: weight);
    ref.invalidate(myInterestsProvider);
    await _load();
  }

  Future<void> remove(String category) async {
    await ref.read(recommendationRepositoryProvider).removeInterest(category);
    state = state.where((i) => i.category != category).toList();
    ref.invalidate(myInterestsProvider);
  }

  Future<void> clearAll() async {
    await ref.read(recommendationRepositoryProvider).clearAllInterests();
    state = [];
    ref.invalidate(myInterestsProvider);
  }
}

final interestsProvider =
    NotifierProvider.autoDispose<InterestsNotifier, List<UserInterest>>(
      InterestsNotifier.new,
    );
