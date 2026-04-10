class Tag {
  final String id;
  final String name;
  final String slug;
  final String color;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    required this.slug,
    this.color = '#B8973F',
    required this.createdAt,
  });

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      slug: map['slug'] as String,
      color: (map['color'] as String?) ?? '#B8973F',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'slug': slug, 'color': color};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Tag && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
