import 'dart:async';
import 'package:livekit_client/livekit_client.dart';
import 'package:bayan/core/models/room_participant.dart';
import 'package:bayan/core/services/audio_service.dart';
import 'package:bayan/features/diwan/domain/models/room_role.dart';

/// LiveKit-backed implementation of [AudioService].
///
/// Native setup required before first use:
///   Android — minSdk 21 already set; permissions added to AndroidManifest.xml
///   iOS     — NSMicrophoneUsageDescription added to Info.plist
///
/// Server — set LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET in the
///   Supabase project's Edge Function secrets.
class LiveKitAudioService implements AudioService {
  final Room _room;
  final StreamController<List<RoomParticipant>> _participantsCtrl;
  final StreamController<Set<String>> _speakersCtrl;

  bool _isMicEnabled = false;
  EventsListener<RoomEvent>? _listener;

  LiveKitAudioService()
    : _room = Room(
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      ),
      _participantsCtrl = StreamController<List<RoomParticipant>>.broadcast(),
      _speakersCtrl = StreamController<Set<String>>.broadcast();

  // -------------------------------------------------------------------------
  // AudioService implementation
  // -------------------------------------------------------------------------

  @override
  Future<void> joinRoom({required String url, required String token}) async {
    await _room.connect(
      url,
      token,
      connectOptions: const ConnectOptions(autoSubscribe: true),
    );
    _setupListeners();

    // Auto-enable mic; role-based muting is enforced by the LiveKit token
    await _room.localParticipant?.setMicrophoneEnabled(true);
    _isMicEnabled = true;
    _emitParticipants();
  }

  @override
  Future<void> leaveRoom() async {
    _listener?.dispose();
    await _room.disconnect();
    _isMicEnabled = false;
    _emitParticipants();
  }

  @override
  Future<bool> toggleMic() async {
    _isMicEnabled = !_isMicEnabled;
    await _room.localParticipant?.setMicrophoneEnabled(_isMicEnabled);
    _emitParticipants();
    return _isMicEnabled;
  }

  @override
  Future<void> setMicEnabled(bool enabled) async {
    _isMicEnabled = enabled;
    await _room.localParticipant?.setMicrophoneEnabled(enabled);
    _emitParticipants();
  }

  @override
  List<RoomParticipant> getParticipants() => _buildParticipantList();

  @override
  Stream<List<RoomParticipant>> get participantsStream =>
      _participantsCtrl.stream;

  @override
  Stream<Set<String>> get activeSpeakersStream => _speakersCtrl.stream;

  @override
  bool get isMicEnabled => _isMicEnabled;

  @override
  bool get isConnected => _room.connectionState == ConnectionState.connected;

  @override
  void dispose() {
    _listener?.dispose();
    _room.disconnect();
    _participantsCtrl.close();
    _speakersCtrl.close();
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  void _setupListeners() {
    _listener = _room.createListener();
    _listener!
      ..on<ParticipantConnectedEvent>((_) => _emitParticipants())
      ..on<ParticipantDisconnectedEvent>((_) => _emitParticipants())
      ..on<TrackMutedEvent>((_) => _emitParticipants())
      ..on<TrackUnmutedEvent>((_) => _emitParticipants())
      ..on<ActiveSpeakersChangedEvent>((event) {
        final ids = event.speakers.map((p) => p.identity).toSet();
        if (!_speakersCtrl.isClosed) _speakersCtrl.add(ids);
      });
  }

  List<RoomParticipant> _buildParticipantList() {
    final all = <RoomParticipant>[];

    final local = _room.localParticipant;
    if (local != null) {
      all.add(
        RoomParticipant(
          id: local.identity,
          name: local.name.isEmpty ? local.identity : local.name,
          role: RoomRole.listener,
          isMicEnabled: _isMicEnabled,
          isSpeaking: local.isSpeaking,
          isLocal: true,
        ),
      );
    }

    for (final p in _room.remoteParticipants.values) {
      final audioMuted = p.audioTrackPublications.any((pub) => pub.muted);
      all.add(
        RoomParticipant(
          id: p.identity,
          name: p.name.isEmpty ? p.identity : p.name,
          role: RoomRole.listener,
          isMicEnabled: !audioMuted,
          isSpeaking: p.isSpeaking,
        ),
      );
    }

    return all;
  }

  void _emitParticipants() {
    if (!_participantsCtrl.isClosed) {
      _participantsCtrl.add(_buildParticipantList());
    }
  }
}
