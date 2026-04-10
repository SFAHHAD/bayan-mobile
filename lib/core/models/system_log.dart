enum LogSeverity { debug, info, warning, error, fatal }

class SystemLog {
  final String id;
  final LogSeverity severity;
  final String source;
  final String message;
  final String? stackTrace;
  final String? userId;
  final Map<String, dynamic> metadata;
  final String? appVersion;
  final String? platform;
  final String? sessionId;
  final DateTime createdAt;

  const SystemLog({
    required this.id,
    required this.severity,
    required this.source,
    required this.message,
    this.stackTrace,
    this.userId,
    this.metadata = const {},
    this.appVersion,
    this.platform,
    this.sessionId,
    required this.createdAt,
  });

  static LogSeverity _severityFromString(String? s) {
    switch (s) {
      case 'debug':
        return LogSeverity.debug;
      case 'info':
        return LogSeverity.info;
      case 'warning':
        return LogSeverity.warning;
      case 'error':
        return LogSeverity.error;
      case 'fatal':
        return LogSeverity.fatal;
      default:
        return LogSeverity.info;
    }
  }

  static String severityToString(LogSeverity s) {
    switch (s) {
      case LogSeverity.debug:
        return 'debug';
      case LogSeverity.info:
        return 'info';
      case LogSeverity.warning:
        return 'warning';
      case LogSeverity.error:
        return 'error';
      case LogSeverity.fatal:
        return 'fatal';
    }
  }

  factory SystemLog.fromMap(Map<String, dynamic> map) {
    final rawMeta = map['metadata'];
    final Map<String, dynamic> meta;
    if (rawMeta is Map<String, dynamic>) {
      meta = rawMeta;
    } else if (rawMeta is Map) {
      meta = Map<String, dynamic>.from(rawMeta);
    } else {
      meta = {};
    }

    return SystemLog(
      id: map['id'] as String,
      severity: _severityFromString(map['severity'] as String?),
      source: map['source'] as String,
      message: map['message'] as String,
      stackTrace: map['stack_trace'] as String?,
      userId: map['user_id'] as String?,
      metadata: meta,
      appVersion: map['app_version'] as String?,
      platform: map['platform'] as String?,
      sessionId: map['session_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get severityString => severityToString(severity);

  bool get isError =>
      severity == LogSeverity.error || severity == LogSeverity.fatal;
  bool get isFatal => severity == LogSeverity.fatal;
  bool get isWarning => severity == LogSeverity.warning;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemLog && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
