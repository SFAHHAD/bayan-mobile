import 'package:bayan/core/models/poll_option.dart';

enum PollStatus { draft, active, ended }

class Poll {
  final String id;
  final String diwanId;
  final String hostId;
  final String question;
  final PollStatus status;
  final int totalVotes;
  final List<PollOption> options;
  final DateTime createdAt;
  final DateTime? endedAt;

  const Poll({
    required this.id,
    required this.diwanId,
    required this.hostId,
    required this.question,
    required this.status,
    this.totalVotes = 0,
    this.options = const [],
    required this.createdAt,
    this.endedAt,
  });

  static PollStatus _statusFromString(String? s) {
    switch (s) {
      case 'active':
        return PollStatus.active;
      case 'ended':
        return PollStatus.ended;
      default:
        return PollStatus.draft;
    }
  }

  factory Poll.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['poll_options'];
    final List<PollOption> options;
    if (rawOptions is List) {
      options = rawOptions
          .map((o) => PollOption.fromMap(o as Map<String, dynamic>))
          .toList();
    } else {
      options = [];
    }

    return Poll(
      id: map['id'] as String,
      diwanId: map['diwan_id'] as String,
      hostId: map['host_id'] as String,
      question: map['question'] as String,
      status: _statusFromString(map['status'] as String?),
      totalVotes: (map['total_votes'] as int?) ?? 0,
      options: options,
      createdAt: DateTime.parse(map['created_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
    );
  }

  bool get isActive => status == PollStatus.active;
  bool get isEnded => status == PollStatus.ended;
  bool get isDraft => status == PollStatus.draft;

  /// Returns the option with the most votes, or null if no votes have been cast.
  PollOption? get winningOption {
    if (options.isEmpty || totalVotes == 0) return null;
    return options.reduce((a, b) => a.votesCount >= b.votesCount ? a : b);
  }

  Poll copyWith({
    PollStatus? status,
    int? totalVotes,
    List<PollOption>? options,
    DateTime? endedAt,
  }) {
    return Poll(
      id: id,
      diwanId: diwanId,
      hostId: hostId,
      question: question,
      status: status ?? this.status,
      totalVotes: totalVotes ?? this.totalVotes,
      options: options ?? this.options,
      createdAt: createdAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Poll && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
