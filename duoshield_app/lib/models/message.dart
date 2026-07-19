class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final String? mediaKey;
  final int timestamp;
  final String status;
  final bool deletedForAll;
  final String? replyToId;
  final String? reactionBy;
  final bool edited;
  final String? editedText;
  final bool starred;
  final bool pinned;
  final int? disappearMs;
  final int sigType;
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewImage;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    this.mediaKey,
    required this.timestamp,
    this.status = 'sent',
    this.deletedForAll = false,
    this.replyToId,
    this.reactionBy,
    this.edited = false,
    this.editedText,
    this.starred = false,
    this.pinned = false,
    this.disappearMs,
    this.sigType = 0,
    this.linkPreviewUrl,
    this.linkPreviewTitle,
    this.linkPreviewImage,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      text: map['text'] as String? ?? '',
      mediaUrl: map['mediaUrl'] as String?,
      mediaType: map['mediaType'] as String?,
      mediaKey: map['mediaKey'] as String?,
      timestamp: map['timestamp'] as int,
      status: map['status'] as String? ?? 'sent',
      deletedForAll: (map['deletedForAll'] as int? ?? 0) == 1,
      replyToId: map['replyToId'] as String?,
      reactionBy: map['reactionBy'] as String?,
      edited: (map['edited'] as int? ?? 0) == 1,
      editedText: map['editedText'] as String?,
      starred: (map['starred'] as int? ?? 0) == 1,
      pinned: (map['pinned'] as int? ?? 0) == 1,
      disappearMs: map['disappearMs'] as int?,
      sigType: map['sigType'] as int? ?? 0,
      linkPreviewUrl: map['linkPreviewUrl'] as String?,
      linkPreviewTitle: map['linkPreviewTitle'] as String?,
      linkPreviewImage: map['linkPreviewImage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'mediaKey': mediaKey,
      'timestamp': timestamp,
      'status': status,
      'deletedForAll': deletedForAll ? 1 : 0,
      'replyToId': replyToId,
      'reactionBy': reactionBy,
      'edited': edited ? 1 : 0,
      'editedText': editedText,
      'starred': starred ? 1 : 0,
      'pinned': pinned ? 1 : 0,
      'disappearMs': disappearMs,
      'sigType': sigType,
      'linkPreviewUrl': linkPreviewUrl,
      'linkPreviewTitle': linkPreviewTitle,
      'linkPreviewImage': linkPreviewImage,
    };
  }

  Message copyWith({
    String? text,
    String? status,
    bool? deletedForAll,
    bool? edited,
    String? editedText,
    bool? starred,
    bool? pinned,
    String? reactionBy,
  }) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text ?? this.text,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      mediaKey: mediaKey,
      timestamp: timestamp,
      status: status ?? this.status,
      deletedForAll: deletedForAll ?? this.deletedForAll,
      replyToId: replyToId,
      reactionBy: reactionBy ?? this.reactionBy,
      edited: edited ?? this.edited,
      editedText: editedText ?? this.editedText,
      starred: starred ?? this.starred,
      pinned: pinned ?? this.pinned,
      disappearMs: disappearMs,
      sigType: sigType,
      linkPreviewUrl: linkPreviewUrl,
      linkPreviewTitle: linkPreviewTitle,
      linkPreviewImage: linkPreviewImage,
    );
  }
}
