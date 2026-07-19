class Group {
  final String id;
  final String name;
  final String? avatarUrl;
  final String createdBy;
  final int createdAt;
  final String groupKey;
  final String lastMessage;
  final int lastMessageTs;

  const Group({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.createdBy,
    required this.createdAt,
    required this.groupKey,
    this.lastMessage = '',
    this.lastMessageTs = 0,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      createdBy: map['createdBy'] as String,
      createdAt: map['createdAt'] as int,
      groupKey: map['groupKey'] as String,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTs: map['lastMessageTs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'groupKey': groupKey,
      'lastMessage': lastMessage,
      'lastMessageTs': lastMessageTs,
    };
  }
}
