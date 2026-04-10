class PollOption {
  final String id;
  final String pollId;
  final String text;
  final int votesCount;
  final DateTime createdAt;

  const PollOption({
    required this.id,
    required this.pollId,
    required this.text,
    this.votesCount = 0,
    required this.createdAt,
  });

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'] as String,
      pollId: map['poll_id'] as String,
      text: map['text'] as String,
      votesCount: (map['votes_count'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Percentage of total votes this option has received.
  /// Returns 0.0 when [totalVotes] is 0 to avoid division by zero.
  double percentage(int totalVotes) {
    if (totalVotes <= 0) return 0.0;
    return (votesCount / totalVotes) * 100.0;
  }

  PollOption copyWith({int? votesCount}) {
    return PollOption(
      id: id,
      pollId: pollId,
      text: text,
      votesCount: votesCount ?? this.votesCount,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PollOption && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
