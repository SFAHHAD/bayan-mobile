import 'dart:convert';

enum ConfigType { bool, int, double, string, json }

class RemoteConfig {
  final String id;
  final String key;
  final String value;
  final ConfigType type;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RemoteConfig({
    required this.id,
    required this.key,
    required this.value,
    required this.type,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  static ConfigType _typeFromString(String? s) {
    switch (s) {
      case 'bool':
        return ConfigType.bool;
      case 'int':
        return ConfigType.int;
      case 'double':
        return ConfigType.double;
      case 'json':
        return ConfigType.json;
      default:
        return ConfigType.string;
    }
  }

  static String typeToString(ConfigType t) {
    switch (t) {
      case ConfigType.bool:
        return 'bool';
      case ConfigType.int:
        return 'int';
      case ConfigType.double:
        return 'double';
      case ConfigType.json:
        return 'json';
      case ConfigType.string:
        return 'string';
    }
  }

  factory RemoteConfig.fromMap(Map<String, dynamic> map) {
    return RemoteConfig(
      id: map['id'] as String,
      key: map['key'] as String,
      value: map['value'] as String,
      type: _typeFromString(map['type'] as String?),
      description: map['description'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // -------------------------------------------------------------------------
  // Typed value accessors
  // -------------------------------------------------------------------------

  bool get asBool {
    final v = value.toLowerCase().trim();
    return v == 'true' || v == '1' || v == 'yes';
  }

  int get asInt => int.tryParse(value) ?? 0;

  double get asDouble => double.tryParse(value) ?? 0.0;

  String get asString => value;

  Map<String, dynamic> get asJson {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  RemoteConfig copyWith({String? value, bool? isActive, DateTime? updatedAt}) {
    return RemoteConfig(
      id: id,
      key: key,
      value: value ?? this.value,
      type: type,
      description: description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get typeString => typeToString(type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteConfig &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}
