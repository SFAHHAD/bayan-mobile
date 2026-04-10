enum ProposalType { feature, rule, moderation, other }

enum ProposalStatus { proposed, voting, approved, rejected, withdrawn }

class Proposal {
  final String id;
  final String creatorId;
  final String title;
  final String body;
  final ProposalType type;
  final ProposalStatus status;
  final int yesVotes;
  final int noVotes;
  final int abstainVotes;
  final DateTime? votingStartsAt;
  final DateTime? votingEndsAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Proposal({
    required this.id,
    required this.creatorId,
    required this.title,
    this.body = '',
    this.type = ProposalType.feature,
    this.status = ProposalStatus.proposed,
    this.yesVotes = 0,
    this.noVotes = 0,
    this.abstainVotes = 0,
    this.votingStartsAt,
    this.votingEndsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static ProposalType _typeFromString(String? s) {
    switch (s) {
      case 'feature':
        return ProposalType.feature;
      case 'rule':
        return ProposalType.rule;
      case 'moderation':
        return ProposalType.moderation;
      default:
        return ProposalType.other;
    }
  }

  static String typeToString(ProposalType t) {
    switch (t) {
      case ProposalType.feature:
        return 'feature';
      case ProposalType.rule:
        return 'rule';
      case ProposalType.moderation:
        return 'moderation';
      case ProposalType.other:
        return 'other';
    }
  }

  static ProposalStatus _statusFromString(String? s) {
    switch (s) {
      case 'proposed':
        return ProposalStatus.proposed;
      case 'voting':
        return ProposalStatus.voting;
      case 'approved':
        return ProposalStatus.approved;
      case 'rejected':
        return ProposalStatus.rejected;
      case 'withdrawn':
        return ProposalStatus.withdrawn;
      default:
        return ProposalStatus.proposed;
    }
  }

  static String statusToString(ProposalStatus s) {
    switch (s) {
      case ProposalStatus.proposed:
        return 'proposed';
      case ProposalStatus.voting:
        return 'voting';
      case ProposalStatus.approved:
        return 'approved';
      case ProposalStatus.rejected:
        return 'rejected';
      case ProposalStatus.withdrawn:
        return 'withdrawn';
    }
  }

  factory Proposal.fromMap(Map<String, dynamic> map) {
    return Proposal(
      id: map['id'] as String,
      creatorId: map['creator_id'] as String,
      title: map['title'] as String,
      body: (map['body'] as String?) ?? '',
      type: _typeFromString(map['type'] as String?),
      status: _statusFromString(map['status'] as String?),
      yesVotes: (map['yes_votes'] as int?) ?? 0,
      noVotes: (map['no_votes'] as int?) ?? 0,
      abstainVotes: (map['abstain_votes'] as int?) ?? 0,
      votingStartsAt: map['voting_starts_at'] == null
          ? null
          : DateTime.parse(map['voting_starts_at'] as String),
      votingEndsAt: map['voting_ends_at'] == null
          ? null
          : DateTime.parse(map['voting_ends_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // -------------------------------------------------------------------------
  // Computed
  // -------------------------------------------------------------------------

  int get totalVotes => yesVotes + noVotes + abstainVotes;

  double get approvalRate {
    final decisive = yesVotes + noVotes;
    if (decisive == 0) return 0.0;
    return yesVotes / decisive;
  }

  bool get isVotingOpen {
    if (status != ProposalStatus.voting) return false;
    final now = DateTime.now();
    if (votingStartsAt != null && now.isBefore(votingStartsAt!)) return false;
    if (votingEndsAt != null && now.isAfter(votingEndsAt!)) return false;
    return true;
  }

  bool get isFinalized =>
      status == ProposalStatus.approved ||
      status == ProposalStatus.rejected ||
      status == ProposalStatus.withdrawn;

  bool get isVotingExpired =>
      votingEndsAt != null && DateTime.now().isAfter(votingEndsAt!);

  Proposal copyWith({
    ProposalStatus? status,
    int? yesVotes,
    int? noVotes,
    int? abstainVotes,
    DateTime? votingStartsAt,
    DateTime? votingEndsAt,
  }) => Proposal(
    id: id,
    creatorId: creatorId,
    title: title,
    body: body,
    type: type,
    status: status ?? this.status,
    yesVotes: yesVotes ?? this.yesVotes,
    noVotes: noVotes ?? this.noVotes,
    abstainVotes: abstainVotes ?? this.abstainVotes,
    votingStartsAt: votingStartsAt ?? this.votingStartsAt,
    votingEndsAt: votingEndsAt ?? this.votingEndsAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Proposal && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Proposal(id: $id, title: $title, status: ${statusToString(status)})';
}
