import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/diwan_summary.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/services/ai_service.dart';

// -------------------------------------------------------------------------
// Service provider
// -------------------------------------------------------------------------
final aiServiceProvider = Provider<AIService>(
  (ref) => AIService(ref.read(supabaseClientProvider)),
);

// -------------------------------------------------------------------------
// Summary for a specific diwan (real-time watch)
// -------------------------------------------------------------------------
final diwanSummaryStreamProvider = StreamProvider.autoDispose
    .family<DiwanSummary?, String>(
      (ref, diwanId) => ref.read(aiServiceProvider).watchSummary(diwanId),
    );

/// One-shot fetch of the summary (for display screens that don't need Realtime).
final diwanSummaryProvider = FutureProvider.autoDispose
    .family<DiwanSummary?, String>(
      (ref, diwanId) => ref.read(aiServiceProvider).getSummary(diwanId),
    );

// -------------------------------------------------------------------------
// Trigger generation notifier
// -------------------------------------------------------------------------
class SummaryGenerationNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;

  SummaryGenerationNotifier(this._ref) : super(const AsyncData(null));

  Future<void> generate(String diwanId) async {
    state = const AsyncLoading();
    try {
      final summary = await _ref
          .read(aiServiceProvider)
          .generateSummary(diwanId);
      state = AsyncData(summary);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final summaryGenerationProvider =
    StateNotifierProvider<SummaryGenerationNotifier, AsyncValue<String?>>(
      (ref) => SummaryGenerationNotifier(ref),
    );
