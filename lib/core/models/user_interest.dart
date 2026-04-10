enum InterestSource { explicit, implicit, admin }

class UserInterest {
  final String id;
  final String userId;
  final String category;
  final double weight;
  final InterestSource source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserInterest({
    required this.id,
    required this.userId,
    required this.category,
    this.weight = 1.0,
    this.source = InterestSource.explicit,
    required this.createdAt,
    required this.updatedAt,
  });

  static InterestSource _sourceFromString(String? s) {
    switch (s) {
      case 'implicit':
        return InterestSource.implicit;
      case 'admin':
        return InterestSource.admin;
      default:
        return InterestSource.explicit;
    }
  }

  static String _sourceToString(InterestSource s) {
    switch (s) {
      case InterestSource.implicit:
        return 'implicit';
      case InterestSource.admin:
        return 'admin';
      case InterestSource.explicit:
        return 'explicit';
    }
  }

  factory UserInterest.fromMap(Map<String, dynamic> map) {
    final rawWeight = map['weight'];
    final double w;
    if (rawWeight is double) {
      w = rawWeight;
    } else if (rawWeight is int) {
      w = rawWeight.toDouble();
    } else if (rawWeight is String) {
      w = double.tryParse(rawWeight) ?? 1.0;
    } else {
      w = 1.0;
    }

    return UserInterest(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      category: map['category'] as String,
      weight: w.clamp(0.0, 10.0),
      source: _sourceFromString(map['source'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String get sourceString => _sourceToString(source);

  bool get isExplicit => source == InterestSource.explicit;
  bool get isImplicit => source == InterestSource.implicit;

  UserInterest copyWith({
    double? weight,
    InterestSource? source,
    DateTime? updatedAt,
  }) {
    return UserInterest(
      id: id,
      userId: userId,
      category: category,
      weight: (weight ?? this.weight).clamp(0.0, 10.0),
      source: source ?? this.source,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserInterest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
