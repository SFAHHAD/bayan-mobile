enum VerificationStatus { pending, underReview, approved, rejected }

class VerificationRequest {
  final String id;
  final String userId;
  final VerificationStatus status;
  final List<String> documentsUrls;
  final String? professionalTitle;
  final String? verifiedCategory;
  final String? reviewerNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.status,
    required this.documentsUrls,
    this.professionalTitle,
    this.verifiedCategory,
    this.reviewerNotes,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static VerificationStatus _statusFromString(String? s) {
    switch (s) {
      case 'under_review':
        return VerificationStatus.underReview;
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }

  static String _statusToString(VerificationStatus s) {
    switch (s) {
      case VerificationStatus.underReview:
        return 'under_review';
      case VerificationStatus.approved:
        return 'approved';
      case VerificationStatus.rejected:
        return 'rejected';
      case VerificationStatus.pending:
        return 'pending';
    }
  }

  factory VerificationRequest.fromMap(Map<String, dynamic> map) {
    final rawDocs = map['documents_urls'];
    final List<String> docs;
    if (rawDocs is List) {
      docs = rawDocs.map((e) => e as String).toList();
    } else {
      docs = [];
    }

    return VerificationRequest(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      status: _statusFromString(map['status'] as String?),
      documentsUrls: docs,
      professionalTitle: map['professional_title'] as String?,
      verifiedCategory: map['verified_category'] as String?,
      reviewerNotes: map['reviewer_notes'] as String?,
      reviewedBy: map['reviewed_by'] as String?,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String get statusString => _statusToString(status);

  bool get isPending => status == VerificationStatus.pending;
  bool get isUnderReview => status == VerificationStatus.underReview;
  bool get isApproved => status == VerificationStatus.approved;
  bool get isRejected => status == VerificationStatus.rejected;
  bool get isActive => isPending || isUnderReview;

  VerificationRequest copyWith({
    VerificationStatus? status,
    List<String>? documentsUrls,
    String? professionalTitle,
    String? verifiedCategory,
    String? reviewerNotes,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? updatedAt,
  }) {
    return VerificationRequest(
      id: id,
      userId: userId,
      status: status ?? this.status,
      documentsUrls: documentsUrls ?? this.documentsUrls,
      professionalTitle: professionalTitle ?? this.professionalTitle,
      verifiedCategory: verifiedCategory ?? this.verifiedCategory,
      reviewerNotes: reviewerNotes ?? this.reviewerNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
