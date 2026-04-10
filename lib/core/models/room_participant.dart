import 'package:bayan/features/diwan/domain/models/room_role.dart';

class RoomParticipant {
  final String id;
  final String name;
  final RoomRole role;
  final bool isSpeaking;
  final bool isMicEnabled;
  final bool isLocal;

  const RoomParticipant({
    required this.id,
    required this.name,
    required this.role,
    this.isSpeaking = false,
    this.isMicEnabled = false,
    this.isLocal = false,
  });

  RoomParticipant copyWith({
    String? id,
    String? name,
    RoomRole? role,
    bool? isSpeaking,
    bool? isMicEnabled,
    bool? isLocal,
  }) {
    return RoomParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoomParticipant && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
