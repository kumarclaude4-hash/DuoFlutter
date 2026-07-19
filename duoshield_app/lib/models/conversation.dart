class Conversation {
  final String id;
  final String partnerUid;
  final String partnerName;
  final String? partnerAvatar;
  final String lastMessage;
  final int lastMessageTs;
  final int unreadCount;
  final bool muted;
  final bool archived;
  final bool disappearing;
  final int? disappearMs;
  final bool isGroup;

  const Conversation({
    required this.id,
    required this.partnerUid,
    required this.partnerName,
    this.partnerAvatar,
    this.lastMessage = '',
    this.lastMessageTs = 0,
    this.unreadCount = 0,
    this.muted = false,
    this.archived = false,
    this.disappearing = false,
    this.disappearMs,
    this.isGroup = false,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      partnerUid: map['partnerUid'] as String,
      partnerName: map['partnerName'] as String? ?? '',
      partnerAvatar: map['partnerAvatar'] as String?,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTs: map['lastMessageTs'] as int? ?? 0,
      unreadCount: map['unreadCount'] as int? ?? 0,
      muted: (map['muted'] as int? ?? 0) == 1,
      archived: (map['archived'] as int? ?? 0) == 1,
      disappearing: (map['disappearing'] as int? ?? 0) == 1,
      disappearMs: map['disappearMs'] as int?,
      isGroup: (map['isGroup'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partnerUid': partnerUid,
      'partnerName': partnerName,
      'partnerAvatar': partnerAvatar,
      'lastMessage': lastMessage,
      'lastMessageTs': lastMessageTs,
      'unreadCount': unreadCount,
      'muted': muted ? 1 : 0,
      'archived': archived ? 1 : 0,
      'disappearing': disappearing ? 1 : 0,
      'disappearMs': disappearMs,
      'isGroup': isGroup ? 1 : 0,
    };
  }

  Conversation copyWith({
    String? partnerName,
    String? lastMessage,
    int? lastMessageTs,
    int? unreadCount,
    bool? muted,
    bool? archived,
    bool? disappearing,
    int? disappearMs,
  }) {
    return Conversation(
      id: id,
      partnerUid: partnerUid,
      partnerName: partnerName ?? this.partnerName,
      partnerAvatar: partnerAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTs: lastMessageTs ?? this.lastMessageTs,
      unreadCount: unreadCount ?? this.unreadCount,
      muted: muted ?? this.muted,
      archived: archived ?? this.archived,
      disappearing: disappearing ?? this.disappearing,
      disappearMs: disappearMs ?? this.disappearMs,
      isGroup: isGroup,
    );
  }
}
