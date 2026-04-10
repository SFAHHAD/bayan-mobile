/// Health status for a single production secret/key.
class SecretStatus {
  final String key;
  final bool isSet;
  final String? maskedHint;

  const SecretStatus({required this.key, required this.isSet, this.maskedHint});

  factory SecretStatus.fromMap(Map<String, dynamic> map) => SecretStatus(
    key: map['key'] as String,
    isSet: (map['is_set'] as bool?) ?? (map['isSet'] as bool?) ?? false,
    maskedHint:
        (map['masked_hint'] as String?) ?? (map['maskedHint'] as String?),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecretStatus &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          isSet == other.isSet;

  @override
  int get hashCode => Object.hash(key, isSet);
}

/// Aggregate result of the [verify-production-secrets] Edge Function.
class ProductionHealth {
  final bool allSecretsConfigured;
  final List<SecretStatus> secrets;
  final DateTime checkedAt;
  final String environment;

  const ProductionHealth({
    required this.allSecretsConfigured,
    required this.secrets,
    required this.checkedAt,
    required this.environment,
  });

  List<SecretStatus> get missingSecrets =>
      secrets.where((s) => !s.isSet).toList();

  bool get isProductionReady => allSecretsConfigured && environment != 'test';

  factory ProductionHealth.fromMap(Map<String, dynamic> map) {
    final rawSecrets = map['secrets'] as List? ?? [];
    return ProductionHealth(
      allSecretsConfigured: (map['allSecretsConfigured'] as bool?) ?? false,
      secrets: rawSecrets
          .map((s) => SecretStatus.fromMap(s as Map<String, dynamic>))
          .toList(),
      checkedAt: map['checkedAt'] != null
          ? DateTime.tryParse(map['checkedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      environment: (map['environment'] as String?) ?? 'production',
    );
  }

  factory ProductionHealth.notReady(List<String> missingKeys) =>
      ProductionHealth(
        allSecretsConfigured: false,
        secrets: missingKeys
            .map((k) => SecretStatus(key: k, isSet: false))
            .toList(),
        checkedAt: DateTime.now(),
        environment: 'production',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionHealth &&
          runtimeType == other.runtimeType &&
          allSecretsConfigured == other.allSecretsConfigured;

  @override
  int get hashCode => allSecretsConfigured.hashCode;
}
