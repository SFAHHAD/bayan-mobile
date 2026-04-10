import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/voice_clip.dart';
import 'package:bayan/core/providers/core_providers.dart';

// -------------------------------------------------------------------------
// Clip stream — live updates via Realtime
// -------------------------------------------------------------------------

final clipStreamProvider = StreamProvider.autoDispose
    .family<VoiceClip?, String>((ref, clipId) {
      return ref.read(transcriptionRepositoryProvider).watchClip(clipId);
    });

// -------------------------------------------------------------------------
// Search transcripts
// -------------------------------------------------------------------------

class TranscriptSearchState {
  final List<VoiceClip> results;
  final bool isLoading;
  final String? error;

  const TranscriptSearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  TranscriptSearchState copyWith({
    List<VoiceClip>? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => TranscriptSearchState(
    results: results ?? this.results,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

class TranscriptSearchNotifier
    extends AutoDisposeNotifier<TranscriptSearchState> {
  @override
  TranscriptSearchState build() => const TranscriptSearchState();

  Future<void> search(String query, {String? diwanId}) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], clearError: true);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await ref
          .read(transcriptionRepositoryProvider)
          .searchByTranscript(query, diwanId: diwanId);
      state = state.copyWith(isLoading: false, results: results);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'تعذّر البحث في النصوص');
    }
  }

  void clear() => state = const TranscriptSearchState();
}

final transcriptSearchProvider =
    NotifierProvider.autoDispose<
      TranscriptSearchNotifier,
      TranscriptSearchState
    >(TranscriptSearchNotifier.new);

// -------------------------------------------------------------------------
// Trigger transcription for a single clip
// -------------------------------------------------------------------------

class TriggerTranscriptionState {
  final bool isLoading;
  final String? error;
  final bool success;

  const TriggerTranscriptionState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  TriggerTranscriptionState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    bool clearError = false,
  }) => TriggerTranscriptionState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    success: success ?? this.success,
  );
}

class TriggerTranscriptionNotifier
    extends AutoDisposeNotifier<TriggerTranscriptionState> {
  @override
  TriggerTranscriptionState build() => const TriggerTranscriptionState();

  Future<void> trigger(String clipId) async {
    state = state.copyWith(isLoading: true, clearError: true, success: false);
    try {
      await ref
          .read(transcriptionRepositoryProvider)
          .triggerTranscription(clipId);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'تعذّر بدء النسخ الصوتي');
    }
  }
}

final triggerTranscriptionProvider =
    NotifierProvider.autoDispose<
      TriggerTranscriptionNotifier,
      TriggerTranscriptionState
    >(TriggerTranscriptionNotifier.new);
