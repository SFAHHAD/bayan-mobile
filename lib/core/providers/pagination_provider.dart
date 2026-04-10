import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/diwan.dart';
import 'package:bayan/core/models/voice_clip.dart';
import 'package:bayan/core/providers/core_providers.dart';

// =========================================================================
// Paginated Diwan Feed (infinite scroll)
// =========================================================================
class PaginatedDiwanFeedNotifier extends AsyncNotifier<List<Diwan>> {
  static const _pageSize = 15;
  DateTime? _cursor;
  bool _hasMore = true;

  @override
  Future<List<Diwan>> build() => _fetch(reset: true);

  bool get hasMore => _hasMore;

  Future<void> fetchNextPage() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.valueOrNull ?? [];
    final next = await _fetch(reset: false);
    state = AsyncData([...current, ...next]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch(reset: true));
  }

  Future<List<Diwan>> _fetch({required bool reset}) async {
    if (reset) _cursor = null;
    final items = await ref
        .read(diwanRepositoryProvider)
        .getPublicPaged(before: _cursor, limit: _pageSize);
    _hasMore = items.length >= _pageSize;
    if (items.isNotEmpty) _cursor = items.last.createdAt;
    return items;
  }
}

final paginatedDiwanFeedProvider =
    AsyncNotifierProvider<PaginatedDiwanFeedNotifier, List<Diwan>>(
      PaginatedDiwanFeedNotifier.new,
    );

// =========================================================================
// Paginated Voice Gallery (infinite scroll, scoped to a diwan)
// =========================================================================
class PaginatedVoiceGalleryNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<VoiceClip>, String> {
  static const _pageSize = 20;
  DateTime? _cursor;
  bool _hasMore = true;

  @override
  Future<List<VoiceClip>> build(String diwanId) => _fetch(reset: true);

  bool get hasMore => _hasMore;

  Future<void> fetchNextPage() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.valueOrNull ?? [];
    final next = await _fetch(reset: false);
    state = AsyncData([...current, ...next]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch(reset: true));
  }

  Future<List<VoiceClip>> _fetch({required bool reset}) async {
    if (reset) _cursor = null;
    final items = await ref
        .read(voiceRepositoryProvider)
        .getVoicesForDiwanPaged(arg, before: _cursor, limit: _pageSize);
    _hasMore = items.length >= _pageSize;
    if (items.isNotEmpty) _cursor = items.last.createdAt;
    return items;
  }
}

final paginatedVoiceGalleryProvider = AsyncNotifierProvider.family
    .autoDispose<PaginatedVoiceGalleryNotifier, List<VoiceClip>, String>(
      PaginatedVoiceGalleryNotifier.new,
    );
