import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayan/core/models/room_participant.dart';
import 'package:bayan/core/models/speak_request.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/services/audio_service.dart';
import 'package:bayan/core/services/livekit_audio_service.dart';
import 'package:bayan/features/diwan/domain/models/room_role.dart';
import 'package:bayan/features/auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class RoomState {
  final bool isConnected;
  final bool isLoading;
  final bool isMicEnabled;
  final RoomRole localRole;
  final List<RoomParticipant> participants;
  final Set<String> activeSpeakerIds;
  final List<SpeakRequest> pendingSpeakRequests;
  final String? error;
  final String? currentDiwanId;

  const RoomState({
    this.isConnected = false,
    this.isLoading = false,
    this.isMicEnabled = false,
    this.localRole = RoomRole.listener,
    this.participants = const [],
    this.activeSpeakerIds = const {},
    this.pendingSpeakRequests = const [],
    this.error,
    this.currentDiwanId,
  });

  List<RoomParticipant> get speakers =>
      participants.where((p) => p.role == RoomRole.speaker).toList();

  List<RoomParticipant> get hosts =>
      participants.where((p) => p.role == RoomRole.host).toList();

  RoomState copyWith({
    bool? isConnected,
    bool? isLoading,
    bool? isMicEnabled,
    RoomRole? localRole,
    List<RoomParticipant>? participants,
    Set<String>? activeSpeakerIds,
    List<SpeakRequest>? pendingSpeakRequests,
    String? error,
    String? currentDiwanId,
    bool clearError = false,
  }) {
    return RoomState(
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      localRole: localRole ?? this.localRole,
      participants: participants ?? this.participants,
      activeSpeakerIds: activeSpeakerIds ?? this.activeSpeakerIds,
      pendingSpeakRequests: pendingSpeakRequests ?? this.pendingSpeakRequests,
      error: clearError ? null : (error ?? this.error),
      currentDiwanId: currentDiwanId ?? this.currentDiwanId,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class RoomNotifier extends StateNotifier<RoomState> {
  final AudioService _audio;
  final Ref _ref;

  StreamSubscription<List<RoomParticipant>>? _participantsSub;
  StreamSubscription<Set<String>>? _speakersSub;
  StreamSubscription<List<SpeakRequest>>? _speakRequestsSub;

  RoomNotifier(this._audio, this._ref) : super(const RoomState());

  // -------------------------------------------------------------------------
  // Public actions
  // -------------------------------------------------------------------------

  /// Join a diwan's live room. Fetches a LiveKit token via Edge Function,
  /// then connects to the audio server and starts all real-time streams.
  Future<void> joinDiwan(String diwanId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final participantRepo = _ref.read(participantRepositoryProvider);
      final userId = _ref.read(userProvider).user?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Determine role before connecting
      final role = await participantRepo.getMyRole(diwanId, userId);

      // Register participation
      await participantRepo.joinDiwan(diwanId, userId, role);

      // Obtain LiveKit token from Edge Function
      final token = await participantRepo.getLiveKitToken(diwanId);
      final livekitUrl = _ref.read(livekitServerUrlProvider);

      // Connect to audio server
      await _audio.joinRoom(url: livekitUrl, token: token);

      // Subscribe to real-time streams
      _subscribeSpeakers();
      _subscribeParticipants(diwanId, role);
      _subscribeSpeakRequests(diwanId);

      state = state.copyWith(
        isConnected: true,
        isLoading: false,
        localRole: role,
        isMicEnabled: role.canPublishAudio,
        currentDiwanId: diwanId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر الانضمام إلى الديوانية',
      );
    }
  }

  Future<void> leaveDiwan() async {
    final diwanId = state.currentDiwanId;
    final userId = _ref.read(userProvider).user?.id;

    _participantsSub?.cancel();
    _speakersSub?.cancel();
    _speakRequestsSub?.cancel();

    await _audio.leaveRoom();

    if (diwanId != null && userId != null) {
      await _ref
          .read(participantRepositoryProvider)
          .leaveDiwan(diwanId, userId);
    }

    state = const RoomState();
  }

  Future<void> toggleMic() async {
    if (!state.localRole.canPublishAudio) return;
    final newState = await _audio.toggleMic();
    state = state.copyWith(isMicEnabled: newState);
  }

  /// Listener requests to speak (sends request to host).
  Future<void> requestToSpeak() async {
    final diwanId = state.currentDiwanId;
    final userId = _ref.read(userProvider).user?.id;
    if (diwanId == null || userId == null) return;
    await _ref
        .read(participantRepositoryProvider)
        .requestToSpeak(diwanId, userId);
  }

  /// Host approves a speaker request → role updated → new token needed.
  Future<void> approveSpeakRequest(SpeakRequest request) async {
    if (!state.localRole.canManageParticipants) return;
    await _ref
        .read(participantRepositoryProvider)
        .approveSpeakRequest(request.id, request.diwanId, request.userId);
  }

  /// Host rejects a speaker request.
  Future<void> rejectSpeakRequest(SpeakRequest request) async {
    if (!state.localRole.canManageParticipants) return;
    await _ref
        .read(participantRepositoryProvider)
        .rejectSpeakRequest(request.id);
  }

  /// Host mutes a speaker → role downgraded to listener.
  Future<void> muteSpeaker(String userId) async {
    if (!state.localRole.canManageParticipants) return;
    final diwanId = state.currentDiwanId;
    if (diwanId == null) return;
    await _ref
        .read(participantRepositoryProvider)
        .updateRole(diwanId, userId, RoomRole.listener);
  }

  // -------------------------------------------------------------------------
  // Internal subscriptions
  // -------------------------------------------------------------------------

  void _subscribeSpeakers() {
    _speakersSub = _audio.activeSpeakersStream.listen((ids) {
      final updated = state.participants.map((p) {
        return p.copyWith(isSpeaking: ids.contains(p.id));
      }).toList();
      state = state.copyWith(activeSpeakerIds: ids, participants: updated);
    });
  }

  void _subscribeParticipants(String diwanId, RoomRole localRole) {
    _participantsSub = _audio.participantsStream.listen((raw) {
      state = state.copyWith(participants: raw);
    });
  }

  void _subscribeSpeakRequests(String diwanId) {
    _speakRequestsSub = _ref
        .read(participantRepositoryProvider)
        .watchSpeakRequests(diwanId)
        .listen((requests) {
          state = state.copyWith(pendingSpeakRequests: requests);
        });
  }

  @override
  void dispose() {
    _participantsSub?.cancel();
    _speakersSub?.cancel();
    _speakRequestsSub?.cancel();
    _audio.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Override this in tests with a mock [AudioService].
final audioServiceProvider = Provider<AudioService>(
  (ref) => LiveKitAudioService(),
);

/// The LiveKit server URL — set via Supabase Edge Function env or hardcode
/// for development. In production, supply via remote config or env.
final livekitServerUrlProvider = Provider<String>(
  (ref) => const String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'wss://your-livekit-server.livekit.cloud',
  ),
);

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>(
  (ref) => RoomNotifier(ref.read(audioServiceProvider), ref),
);
