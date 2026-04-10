import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/semantic_result.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/repositories/semantic_search_repository.dart';

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------
class SemanticSearchState {
  final bool isLoading;
  final List<SemanticResult> results;
  final String query;
  final String? error;

  const SemanticSearchState({
    this.isLoading = false,
    this.results = const [],
    this.query = '',
    this.error,
  });

  SemanticSearchState copyWith({
    bool? isLoading,
    List<SemanticResult>? results,
    String? query,
    String? error,
    bool clearError = false,
  }) => SemanticSearchState(
    isLoading: isLoading ?? this.isLoading,
    results: results ?? this.results,
    query: query ?? this.query,
    error: clearError ? null : (error ?? this.error),
  );

  bool get hasResults => results.isNotEmpty;
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------
class SemanticSearchNotifier extends AutoDisposeNotifier<SemanticSearchState> {
  @override
  SemanticSearchState build() => const SemanticSearchState();

  Future<void> search(
    String query, {
    double threshold = 0.70,
    int limit = 10,
    SemanticSearchType type = SemanticSearchType.diwan,
  }) async {
    if (query.trim().isEmpty) {
      state = const SemanticSearchState();
      return;
    }
    state = state.copyWith(isLoading: true, query: query, clearError: true);
    try {
      final results = await ref
          .read(semanticSearchRepositoryProvider)
          .search(query, threshold: threshold, limit: limit, type: type);
      state = state.copyWith(isLoading: false, results: results);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'تعذّر البحث الدلالي');
    }
  }

  void clear() => state = const SemanticSearchState();
}

final semanticSearchProvider =
    NotifierProvider.autoDispose<SemanticSearchNotifier, SemanticSearchState>(
      SemanticSearchNotifier.new,
    );
