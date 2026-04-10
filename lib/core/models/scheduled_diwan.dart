class ScheduledDiwan {
  final String id;
  final String diwanId;
  final String hostId;
  final DateTime startTime;
  final int estimatedDurationMinutes;
  final bool reminderSent;
  final bool isCancelled;
  final DateTime createdAt;

  const ScheduledDiwan({
    required this.id,
    required this.diwanId,
    required this.hostId,
    required this.startTime,
    this.estimatedDurationMinutes = 60,
    this.reminderSent = false,
    this.isCancelled = false,
    required this.createdAt,
  });

  factory ScheduledDiwan.fromMap(Map<String, dynamic> map) {
    return ScheduledDiwan(
      id: map['id'] as String,
      diwanId: map['diwan_id'] as String,
      hostId: map['host_id'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      estimatedDurationMinutes:
          (map['estimated_duration_minutes'] as int?) ?? 60,
      reminderSent: (map['reminder_sent'] as bool?) ?? false,
      isCancelled: (map['is_cancelled'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'diwan_id': diwanId,
      'host_id': hostId,
      'start_time': startTime.toIso8601String(),
      'estimated_duration_minutes': estimatedDurationMinutes,
    };
  }

  /// Returns true if this session is still in the future and not cancelled.
  bool get isUpcoming => !isCancelled && startTime.isAfter(DateTime.now());

  /// Minutes until the session starts (negative if in the past).
  int get minutesUntilStart => startTime.difference(DateTime.now()).inMinutes;

  ScheduledDiwan copyWith({
    bool? reminderSent,
    bool? isCancelled,
    DateTime? startTime,
    int? estimatedDurationMinutes,
  }) {
    return ScheduledDiwan(
      id: id,
      diwanId: diwanId,
      hostId: hostId,
      startTime: startTime ?? this.startTime,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      reminderSent: reminderSent ?? this.reminderSent,
      isCancelled: isCancelled ?? this.isCancelled,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledDiwan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
