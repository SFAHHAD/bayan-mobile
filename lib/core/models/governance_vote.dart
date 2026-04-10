enum VoteChoice { yes, no, abstain }

class GovernanceVote {
  final String id;
  final String proposalId;
  final String userId;
  final VoteChoice vote;
  final DateTime createdAt;

  const GovernanceVote({
    required this.id,
    required this.proposalId,
    required this.userId,
    required this.vote,
    required this.createdAt,
  });

  static VoteChoice _voteFromString(String? s) {
    switch (s) {
      case 'yes':
        return VoteChoice.yes;
      case 'no':
        return VoteChoice.no;
      default:
        return VoteChoice.abstain;
    }
  }

  static String voteToString(VoteChoice v) {
    switch (v) {
      case VoteChoice.yes:
        return 'yes';
      case VoteChoice.no:
        return 'no';
      case VoteChoice.abstain:
        return 'abstain';
    }
  }

  factory GovernanceVote.fromMap(Map<String, dynamic> map) {
    return GovernanceVote(
      id: map['id'] as String,
      proposalId: map['proposal_id'] as String,
      userId: map['user_id'] as String,
      vote: _voteFromString(map['vote'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GovernanceVote &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
