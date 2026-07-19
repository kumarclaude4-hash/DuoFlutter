class GroupMember {
  final String groupId;
  final String memberUid;
  final String displayName;
  final int joinedAt;

  const GroupMember({
    required this.groupId,
    required this.memberUid,
    required this.displayName,
    required this.joinedAt,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      groupId: map['groupId'] as String,
      memberUid: map['memberUid'] as String,
      displayName: map['displayName'] as String? ?? '',
      joinedAt: map['joinedAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'memberUid': memberUid,
      'displayName': displayName,
      'joinedAt': joinedAt,
    };
  }
}
