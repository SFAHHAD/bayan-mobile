enum SpeakRequestStatus { pending, approved, rejected }

class SpeakRequest {
  final String id;
  final String diwanId;
  final String userId;
  final String userName;
  final SpeakRequestStatus status;
  final DateTime requestedAt;

  const SpeakRequest({
    required this.id,
    required this.diwanId,
    required this.userId,
    required this.userName,
    this.status = SpeakRequestStatus.pending,
    required this.requestedAt,
  });

  bool get isPending => status == SpeakRequestStatus.pending;

  factory SpeakRequest.fromMap(Map<String, dynamic> map) {
    return SpeakRequest(
      id: map['id'] as String,
      diwanId: map['diwan_id'] as String,
      userId: map['user_id'] as String,
      userName:
          (map['profiles'] as Map<String, dynamic>?)?['display_name']
              as String? ??
          map['user_id'] as String,
      status: _statusFromString(map['status'] as String? ?? 'pending'),
      requestedAt: DateTime.parse(map['requested_at'] as String),
    );
  }

  static SpeakRequestStatus _statusFromString(String s) {
    switch (s) {
      case 'approved':
        return SpeakRequestStatus.approved;
      case 'rejected':
        return SpeakRequestStatus.rejected;
      default:
        return SpeakRequestStatus.pending;
    }
  }

  SpeakRequest copyWith({SpeakRequestStatus? status}) {
    return SpeakRequest(
      id: id,
      diwanId: diwanId,
      userId: userId,
      userName: userName,
      status: status ?? this.status,
      requestedAt: requestedAt,
    );
  }
}
