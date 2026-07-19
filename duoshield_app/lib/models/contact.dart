class Contact {
  final String uid;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? conversationId;
  final int addedAt;
  final bool blocked;

  const Contact({
    required this.uid,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.conversationId,
    required this.addedAt,
    this.blocked = false,
  });

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      uid: map['uid'] as String,
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      conversationId: map['conversationId'] as String?,
      addedAt: map['addedAt'] as int,
      blocked: (map['blocked'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'conversationId': conversationId,
      'addedAt': addedAt,
      'blocked': blocked ? 1 : 0,
    };
  }
}
