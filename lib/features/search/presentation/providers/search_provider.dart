import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/search_result.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class SearchState {
  final String query;
  final List<SearchResult> results;
  final bool isSearching;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.error,
  });

  List<SearchResult> get profiles =>
      results.where((r) => r.entityType == SearchEntityType.profile).toList();
  List<SearchResult> get diwans =>
      results.where((r) => r.entityType == SearchEntityType.diwan).toList();
  List<SearchResult> get voices =>
      results.where((r) => r.entityType == SearchEntityType.voice).toList();

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isSearching,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------
class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;
  Timer? _debounce;

  SearchNotifier(this._ref) : super(const SearchState());

  /// Debounced search — waits 350 ms after the last keystroke.
  void onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(query: trimmed, isSearching: true, clearError: true);
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(trimmed),
    );
  }

  Future<void> _search(String query) async {
    try {
      final results = await _ref
          .read(searchRepositoryProvider)
          .globalSearch(query);
      if (!mounted) return;
      state = state.copyWith(results: results, isSearching: false);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isSearching: false, error: 'تعذّر إجراء البحث');
    }
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// -------------------------------------------------------------------------
// Providers
// -------------------------------------------------------------------------
final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>(
      (ref) => SearchNotifier(ref),
    );
