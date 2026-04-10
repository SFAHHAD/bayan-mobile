enum MessageType { text, system }

class Message {
  final String id;
  final String diwanId;
  final String? senderId;
  final String content;
  final MessageType type;
  final String? senderName;
  final bool isEncrypted;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.diwanId,
    this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.senderName,
    this.isEncrypted = false,
    required this.createdAt,
  });

  static MessageType _typeFromString(String? s) {
    if (s == 'system') return MessageType.system;
    return MessageType.text;
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      diwanId: map['diwan_id'] as String,
      senderId: map['sender_id'] as String?,
      content: map['content'] as String,
      type: _typeFromString(map['type'] as String?),
      senderName: map['sender_name'] as String?,
      isEncrypted: (map['is_encrypted'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'diwan_id': diwanId,
      'sender_id': senderId,
      'content': content,
      'type': type.name,
      'sender_name': senderName,
      'is_encrypted': isEncrypted,
    };
  }

  Message copyWith({
    String? id,
    String? diwanId,
    String? senderId,
    String? content,
    MessageType? type,
    String? senderName,
    bool? isEncrypted,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      diwanId: diwanId ?? this.diwanId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      senderName: senderName ?? this.senderName,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
