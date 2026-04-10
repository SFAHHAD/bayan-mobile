import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/voice_clip.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class VoiceState {
  final List<VoiceClip> clips;
  final bool isUploading;
  final double uploadProgress;
  final String? error;

  const VoiceState({
    this.clips = const [],
    this.isUploading = false,
    this.uploadProgress = 0,
    this.error,
  });

  VoiceState copyWith({
    List<VoiceClip>? clips,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    bool clearError = false,
  }) {
    return VoiceState(
      clips: clips ?? this.clips,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class VoiceNotifier extends StateNotifier<VoiceState> {
  final Ref _ref;

  VoiceNotifier(this._ref) : super(const VoiceState());

  /// Called by the host to record and persist a highlight clip.
  Future<VoiceClip?> uploadHighlight({
    required String diwanId,
    required String title,
    required Uint8List bytes,
    required int durationSeconds,
  }) async {
    final speakerId = _ref.read(userProvider).user?.id;
    if (speakerId == null) return null;

    state = state.copyWith(isUploading: true, clearError: true);
    try {
      final clip = await _ref
          .read(voiceRepositoryProvider)
          .uploadHighlight(
            diwanId: diwanId,
            speakerId: speakerId,
            title: title,
            bytes: bytes,
            durationSeconds: durationSeconds,
          );
      state = state.copyWith(isUploading: false, clips: [clip, ...state.clips]);
      return clip;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'تعذّر رفع المقطع الصوتي',
      );
      return null;
    }
  }

  Future<void> loadForDiwan(String diwanId) async {
    try {
      final clips = await _ref
          .read(voiceRepositoryProvider)
          .getVoicesForDiwan(diwanId);
      state = state.copyWith(clips: clips);
    } catch (_) {
      state = state.copyWith(error: 'تعذّر تحميل المقاطع الصوتية');
    }
  }

  Future<void> deleteVoice(VoiceClip clip) async {
    await _ref.read(voiceRepositoryProvider).deleteVoice(clip);
    state = state.copyWith(
      clips: state.clips.where((c) => c.id != clip.id).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>(
  (ref) => VoiceNotifier(ref),
);

/// Streams voice clips for a specific diwan (real-time).
final diwanVoiceClipsProvider = StreamProvider.autoDispose
    .family<List<VoiceClip>, String>((ref, diwanId) {
      return ref.read(voiceRepositoryProvider).watchVoicesForDiwan(diwanId);
    });
