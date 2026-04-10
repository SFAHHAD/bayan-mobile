import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/diwan.dart';
import 'package:bayan/core/models/tag.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// Trending diwans
// -------------------------------------------------------------------------

/// Fetches the hotness-sorted diwan list via `get_trending_diwans` RPC.
final trendingDiwansProvider = FutureProvider.autoDispose<List<Diwan>>(
  (ref) => ref.read(diwanRepositoryProvider).getTrending(),
);

// -------------------------------------------------------------------------
// Tags
// -------------------------------------------------------------------------

/// All available tags.
final tagsProvider = FutureProvider.autoDispose<List<Tag>>(
  (ref) => ref.read(tagRepositoryProvider).fetchAll(),
);

/// Diwans filtered by a specific tag slug.
final diwansByTagProvider = FutureProvider.autoDispose
    .family<List<Diwan>, String>((ref, tagSlug) async {
      final tag = await ref.read(tagRepositoryProvider).getBySlug(tagSlug);
      if (tag == null) return [];
      return ref.read(diwanRepositoryProvider).getDiwansByTag(tag.id);
    });

/// Tags for a specific diwan.
final diwanTagsProvider = FutureProvider.autoDispose.family<List<Tag>, String>(
  (ref, diwanId) => ref.read(tagRepositoryProvider).getTagsForDiwan(diwanId),
);
