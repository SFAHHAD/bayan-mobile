enum BugSeverity { low, medium, high, critical }

enum BugStatus { open, inProgress, resolved, closed, duplicate }

class BugReport {
  final String id;
  final String? reporterId;
  final String title;
  final String? description;
  final BugSeverity severity;
  final String? screenName;
  final Map<String, dynamic> screenState;
  final String? appVersion;
  final String? platform;
  final String? sessionId;
  final Map<String, dynamic> deviceInfo;
  final List<dynamic> recentLogs;
  final BugStatus status;
  final DateTime createdAt;

  const BugReport({
    required this.id,
    this.reporterId,
    required this.title,
    this.description,
    this.severity = BugSeverity.medium,
    this.screenName,
    this.screenState = const {},
    this.appVersion,
    this.platform,
    this.sessionId,
    this.deviceInfo = const {},
    this.recentLogs = const [],
    this.status = BugStatus.open,
    required this.createdAt,
  });

  bool get isOpen => status == BugStatus.open;
  bool get isCritical => severity == BugSeverity.critical;

  static BugSeverity _severityFromString(String? s) {
    switch (s) {
      case 'low':
        return BugSeverity.low;
      case 'high':
        return BugSeverity.high;
      case 'critical':
        return BugSeverity.critical;
      default:
        return BugSeverity.medium;
    }
  }

  static String severityToString(BugSeverity s) {
    switch (s) {
      case BugSeverity.low:
        return 'low';
      case BugSeverity.medium:
        return 'medium';
      case BugSeverity.high:
        return 'high';
      case BugSeverity.critical:
        return 'critical';
    }
  }

  static BugStatus _statusFromString(String? s) {
    switch (s) {
      case 'in_progress':
        return BugStatus.inProgress;
      case 'resolved':
        return BugStatus.resolved;
      case 'closed':
        return BugStatus.closed;
      case 'duplicate':
        return BugStatus.duplicate;
      default:
        return BugStatus.open;
    }
  }

  static String statusToString(BugStatus s) {
    switch (s) {
      case BugStatus.open:
        return 'open';
      case BugStatus.inProgress:
        return 'in_progress';
      case BugStatus.resolved:
        return 'resolved';
      case BugStatus.closed:
        return 'closed';
      case BugStatus.duplicate:
        return 'duplicate';
    }
  }

  factory BugReport.fromMap(Map<String, dynamic> map) {
    return BugReport(
      id: map['id'] as String,
      reporterId: map['reporter_id'] as String?,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      severity: _severityFromString(map['severity'] as String?),
      screenName: map['screen_name'] as String?,
      screenState: map['screen_state'] != null
          ? Map<String, dynamic>.from(map['screen_state'] as Map)
          : const {},
      appVersion: map['app_version'] as String?,
      platform: map['platform'] as String?,
      sessionId: map['session_id'] as String?,
      deviceInfo: map['device_info'] != null
          ? Map<String, dynamic>.from(map['device_info'] as Map)
          : const {},
      recentLogs: map['recent_logs'] != null
          ? List.from(map['recent_logs'] as List)
          : const [],
      status: _statusFromString(map['status'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'severity': severityToString(severity),
    'screen_name': screenName,
    'screen_state': screenState,
    'app_version': appVersion,
    'platform': platform,
    'session_id': sessionId,
    'device_info': deviceInfo,
    'recent_logs': recentLogs,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BugReport && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
