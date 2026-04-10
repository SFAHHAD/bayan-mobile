enum ReportContentType { diwan, voice, user, message }

enum ReportStatus { pending, reviewed, resolved, dismissed }

class Report {
  final String id;
  final String reporterId;
  final ReportContentType contentType;
  final String contentId;
  final String reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.contentType,
    required this.contentId,
    required this.reason,
    this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
  });

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      reporterId: map['reporter_id'] as String,
      contentType: _contentTypeFromString(map['content_type'] as String? ?? ''),
      contentId: map['content_id'] as String,
      reason: map['reason'] as String,
      description: map['description'] as String?,
      status: _statusFromString(map['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static ReportContentType _contentTypeFromString(String s) {
    switch (s) {
      case 'voice':
        return ReportContentType.voice;
      case 'user':
        return ReportContentType.user;
      case 'message':
        return ReportContentType.message;
      default:
        return ReportContentType.diwan;
    }
  }

  static ReportStatus _statusFromString(String s) {
    switch (s) {
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }

  Map<String, dynamic> toMap() => {
    'reporter_id': reporterId,
    'content_type': contentType.name,
    'content_id': contentId,
    'reason': reason,
    'description': description,
  };
}
