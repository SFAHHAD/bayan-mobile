class Invitation {
  final String id;
  final String code;
  final String createdBy;
  final String? usedBy;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const Invitation({
    required this.id,
    required this.code,
    required this.createdBy,
    this.usedBy,
    this.isUsed = false,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isRedeemable => !isUsed && !isExpired;

  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['id'] as String,
      code: map['code'] as String,
      createdBy: map['created_by'] as String,
      usedBy: map['used_by'] as String?,
      isUsed: (map['is_used'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'code': code,
    'created_by': createdBy,
    'used_by': usedBy,
    'is_used': isUsed,
    'created_at': createdAt.toIso8601String(),
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
  };

  Invitation copyWith({
    String? id,
    String? code,
    String? createdBy,
    String? usedBy,
    bool? isUsed,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Invitation(
      id: id ?? this.id,
      code: code ?? this.code,
      createdBy: createdBy ?? this.createdBy,
      usedBy: usedBy ?? this.usedBy,
      isUsed: isUsed ?? this.isUsed,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
