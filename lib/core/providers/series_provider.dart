import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/diwan_series.dart';
import 'package:bayan/core/models/series_subscription.dart';
import 'package:bayan/core/models/diwan.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// Series list — host's own series (realtime)
// -------------------------------------------------------------------------
final hostSeriesStreamProvider = StreamProvider.autoDispose<List<DiwanSeries>>((
  ref,
) {
  return ref.read(seriesRepositoryProvider).watchHostSeries();
});

// -------------------------------------------------------------------------
// All active series (discovery)
// -------------------------------------------------------------------------
final activeSeriesProvider = FutureProvider.autoDispose<List<DiwanSeries>>((
  ref,
) {
  return ref.read(seriesRepositoryProvider).getAllActiveSeries();
});

// -------------------------------------------------------------------------
// Single series detail
// -------------------------------------------------------------------------
final seriesDetailProvider = FutureProvider.autoDispose
    .family<DiwanSeries?, String>((ref, seriesId) {
      return ref.read(seriesRepositoryProvider).getSeries(seriesId);
    });

// -------------------------------------------------------------------------
// Episodes in a series (realtime)
// -------------------------------------------------------------------------
final seriesEpisodesStreamProvider = StreamProvider.autoDispose
    .family<List<Diwan>, String>((ref, seriesId) {
      return ref.read(seriesRepositoryProvider).watchSeriesEpisodes(seriesId);
    });

// -------------------------------------------------------------------------
// My subscriptions
// -------------------------------------------------------------------------
final mySubscriptionsProvider =
    FutureProvider.autoDispose<List<SeriesSubscription>>((ref) {
      return ref.read(seriesRepositoryProvider).getMySubscriptions();
    });

// -------------------------------------------------------------------------
// Subscription check (per-series)
// -------------------------------------------------------------------------
final isSubscribedProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  seriesId,
) {
  return ref.read(seriesRepositoryProvider).isSubscribed(seriesId);
});

// -------------------------------------------------------------------------
// Series management state (create / subscribe)
// -------------------------------------------------------------------------
class SeriesState {
  final List<DiwanSeries> series;
  final bool isLoading;
  final String? error;

  const SeriesState({
    this.series = const [],
    this.isLoading = false,
    this.error,
  });

  SeriesState copyWith({
    List<DiwanSeries>? series,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => SeriesState(
    series: series ?? this.series,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

class SeriesNotifier extends AutoDisposeNotifier<SeriesState> {
  StreamSubscription<List<DiwanSeries>>? _sub;

  @override
  SeriesState build() {
    ref.onDispose(() => _sub?.cancel());
    _sub = ref
        .read(seriesRepositoryProvider)
        .watchHostSeries()
        .listen((list) => state = state.copyWith(series: list));
    return const SeriesState(isLoading: true);
  }

  Future<DiwanSeries?> createSeries({
    required String title,
    String? description,
    String? coverUrl,
    String? category,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final s = await ref
          .read(seriesRepositoryProvider)
          .createSeries(
            title: title,
            description: description,
            coverUrl: coverUrl,
            category: category,
          );
      state = state.copyWith(isLoading: false);
      return s;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'تعذّر إنشاء السلسلة');
      return null;
    }
  }

  Future<void> subscribe(String seriesId) async {
    try {
      await ref.read(seriesRepositoryProvider).subscribe(seriesId);
      ref.invalidate(isSubscribedProvider(seriesId));
      ref.invalidate(mySubscriptionsProvider);
    } catch (_) {
      state = state.copyWith(error: 'تعذّر الاشتراك');
    }
  }

  Future<void> unsubscribe(String seriesId) async {
    try {
      await ref.read(seriesRepositoryProvider).unsubscribe(seriesId);
      ref.invalidate(isSubscribedProvider(seriesId));
      ref.invalidate(mySubscriptionsProvider);
    } catch (_) {
      state = state.copyWith(error: 'تعذّر إلغاء الاشتراك');
    }
  }
}

final seriesProvider =
    NotifierProvider.autoDispose<SeriesNotifier, SeriesState>(
      SeriesNotifier.new,
    );
