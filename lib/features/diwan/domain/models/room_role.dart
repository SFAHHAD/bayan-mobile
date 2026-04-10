enum RoomRole { host, speaker, listener }

extension RoomRoleX on RoomRole {
  String get value {
    switch (this) {
      case RoomRole.host:
        return 'host';
      case RoomRole.speaker:
        return 'speaker';
      case RoomRole.listener:
        return 'listener';
    }
  }

  bool get canPublishAudio => this == RoomRole.host || this == RoomRole.speaker;

  bool get canManageParticipants => this == RoomRole.host;

  static RoomRole fromString(String value) {
    switch (value) {
      case 'host':
        return RoomRole.host;
      case 'speaker':
        return RoomRole.speaker;
      default:
        return RoomRole.listener;
    }
  }
}
