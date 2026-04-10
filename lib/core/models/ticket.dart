class Ticket {
  final String id;
  final String userId;
  final String diwanId;
  final int purchasePrice;
  final DateTime purchasedAt;

  const Ticket({
    required this.id,
    required this.userId,
    required this.diwanId,
    required this.purchasePrice,
    required this.purchasedAt,
  });

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      diwanId: map['diwan_id'] as String,
      purchasePrice: (map['purchase_price'] as int?) ?? 0,
      purchasedAt: DateTime.parse(map['purchased_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'diwan_id': diwanId,
    'purchase_price': purchasePrice,
  };

  bool get isFree => purchasePrice == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ticket && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
