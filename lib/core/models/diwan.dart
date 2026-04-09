class Diwan {
  final String id;
  final String title;
  final String? description;
  final String? ownerId;
  final bool isPublic;
  final String? coverUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Diwan({
    required this.id,
    required this.title,
    this.description,
    this.ownerId,
    this.isPublic = true,
    this.coverUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Diwan.fromMap(Map<String, dynamic> map) {
    return Diwan(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      ownerId: map['owner_id'] as String?,
      isPublic: (map['is_public'] as bool?) ?? true,
      coverUrl: map['cover_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'owner_id': ownerId,
      'is_public': isPublic,
      'cover_url': coverUrl,
    };
  }

  Diwan copyWith({
    String? id,
    String? title,
    String? description,
    String? ownerId,
    bool? isPublic,
    String? coverUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Diwan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      isPublic: isPublic ?? this.isPublic,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
