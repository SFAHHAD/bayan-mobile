enum ActivityLogType {
  joinedDiwan,
  leftDiwan,
  purchasedTicket,
  followedUser,
  unfollowedUser,
  upvotedQuestion,
  votedPoll,
  sentGift,
  viewedProfile,
}

class ActivityLog {
  final String id;
  final String userId;
  final ActivityLogType actionType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.userId,
    required this.actionType,
    this.metadata = const {},
    required this.createdAt,
  });

  static ActivityLogType _typeFromString(String s) {
    switch (s) {
      case 'joined_diwan':
        return ActivityLogType.joinedDiwan;
      case 'left_diwan':
        return ActivityLogType.leftDiwan;
      case 'purchased_ticket':
        return ActivityLogType.purchasedTicket;
      case 'followed_user':
        return ActivityLogType.followedUser;
      case 'unfollowed_user':
        return ActivityLogType.unfollowedUser;
      case 'upvoted_question':
        return ActivityLogType.upvotedQuestion;
      case 'voted_poll':
        return ActivityLogType.votedPoll;
      case 'sent_gift':
        return ActivityLogType.sentGift;
      case 'viewed_profile':
        return ActivityLogType.viewedProfile;
      default:
        return ActivityLogType.viewedProfile;
    }
  }

  static String typeToString(ActivityLogType t) {
    switch (t) {
      case ActivityLogType.joinedDiwan:
        return 'joined_diwan';
      case ActivityLogType.leftDiwan:
        return 'left_diwan';
      case ActivityLogType.purchasedTicket:
        return 'purchased_ticket';
      case ActivityLogType.followedUser:
        return 'followed_user';
      case ActivityLogType.unfollowedUser:
        return 'unfollowed_user';
      case ActivityLogType.upvotedQuestion:
        return 'upvoted_question';
      case ActivityLogType.votedPoll:
        return 'voted_poll';
      case ActivityLogType.sentGift:
        return 'sent_gift';
      case ActivityLogType.viewedProfile:
        return 'viewed_profile';
    }
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    final rawMeta = map['metadata'];
    final Map<String, dynamic> meta;
    if (rawMeta is Map<String, dynamic>) {
      meta = rawMeta;
    } else if (rawMeta is Map) {
      meta = Map<String, dynamic>.from(rawMeta);
    } else {
      meta = {};
    }

    return ActivityLog(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      actionType: _typeFromString(map['action_type'] as String),
      metadata: meta,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get actionTypeString => typeToString(actionType);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
