class Block {
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;

  const Block({
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  factory Block.fromMap(Map<String, dynamic> map) {
    return Block(
      blockerId: map['blocker_id'] as String,
      blockedId: map['blocked_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'blocker_id': blockerId,
    'blocked_id': blockedId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Block &&
          other.blockerId == blockerId &&
          other.blockedId == blockedId);

  @override
  int get hashCode => Object.hash(blockerId, blockedId);
}
