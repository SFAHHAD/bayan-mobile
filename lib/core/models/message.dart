class Message {
  final String id;
  final String diwanId;
  final String? senderId;
  final String content;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.diwanId,
    this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      diwanId: map['diwan_id'] as String,
      senderId: map['sender_id'] as String?,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {'diwan_id': diwanId, 'sender_id': senderId, 'content': content};
  }

  Message copyWith({
    String? id,
    String? diwanId,
    String? senderId,
    String? content,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      diwanId: diwanId ?? this.diwanId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
