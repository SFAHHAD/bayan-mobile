class Question {
  final String id;
  final String diwanId;
  final String userId;
  final String text;
  final int upvotesCount;
  final bool isAnswered;
  final bool isHidden;
  final DateTime createdAt;

  const Question({
    required this.id,
    required this.diwanId,
    required this.userId,
    required this.text,
    this.upvotesCount = 0,
    this.isAnswered = false,
    this.isHidden = false,
    required this.createdAt,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as String,
      diwanId: map['diwan_id'] as String,
      userId: map['user_id'] as String,
      text: map['text'] as String,
      upvotesCount: (map['upvotes_count'] as int?) ?? 0,
      isAnswered: (map['is_answered'] as bool?) ?? false,
      isHidden: (map['is_hidden'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Question copyWith({int? upvotesCount, bool? isAnswered, bool? isHidden}) {
    return Question(
      id: id,
      diwanId: diwanId,
      userId: userId,
      text: text,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      isAnswered: isAnswered ?? this.isAnswered,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
