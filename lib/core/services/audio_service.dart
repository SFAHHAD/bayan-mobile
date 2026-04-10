import 'package:bayan/core/models/room_participant.dart';

/// Abstract contract for the live-audio engine.
/// Concrete implementation: [LiveKitAudioService].
abstract class AudioService {
  /// Connect to a room using the server [url] and a signed [token].
  Future<void> joinRoom({required String url, required String token});

  /// Gracefully disconnect from the current room.
  Future<void> leaveRoom();

  /// Toggle the local microphone. Returns the new enabled state.
  Future<bool> toggleMic();

  /// Enable or disable the local microphone explicitly.
  Future<void> setMicEnabled(bool enabled);

  /// Snapshot of all participants currently in the room.
  List<RoomParticipant> getParticipants();

  /// Live stream of participant list (updates on join / leave / mute change).
  Stream<List<RoomParticipant>> get participantsStream;

  /// Live stream of the set of participant IDs that are actively speaking.
  Stream<Set<String>> get activeSpeakersStream;

  /// Whether the local microphone is currently enabled.
  bool get isMicEnabled;

  /// Whether a room connection is currently established.
  bool get isConnected;

  /// Release resources.
  void dispose();
}
