import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../models/message.dart';
import '../core/extensions.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String? senderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.75;

    if (message.deletedForAll) {
      return _buildTombstone(isMe);
    }

    if (message.sigType == 0) {
      return _buildLegacy(isMe);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: isMe ? colorBubbleMine : colorBubbleTheirs,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (senderName != null && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  senderName!,
                  style: const TextStyle(
                    color: colorAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (message.replyToId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: const Border(left: BorderSide(color: colorAccent, width: 3)),
                ),
                child: const Text('Replied message',
                    style: TextStyle(color: colorTextSecondary, fontSize: 12)),
              ),
            if (message.mediaType != null)
              _buildMediaPreview(message.mediaType!),
            Text(
              message.editedText != null && message.edited
                  ? message.editedText!
                  : message.text,
              style: const TextStyle(color: colorTextPrimary, fontSize: 14),
            ),
            if (message.edited)
              const Text('edited',
                  style: TextStyle(
                      color: colorTextMuted, fontSize: 10, fontStyle: FontStyle.italic)),
            if (message.linkPreviewUrl != null)
              _buildLinkPreview(),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  message.timestamp.toDateTime().toConversationTime(),
                  style: const TextStyle(color: colorTextMuted, fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
            if (message.reactionBy != null && message.reactionBy!.isNotEmpty)
              _buildReactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTombstone(bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const Text(
          '🚫 This message was deleted',
          style: TextStyle(
            color: colorTextMuted,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildLegacy(bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const Text(
          '[Legacy message — not decryptable]',
          style: TextStyle(
            color: colorTextMuted,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(String mediaType) {
    return Container(
      height: 120,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: colorSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        mediaType == 'image'
            ? Icons.image_outlined
            : mediaType == 'video'
                ? Icons.videocam_outlined
                : mediaType == 'audio'
                    ? Icons.audiotrack_outlined
                    : Icons.attach_file,
        color: colorTextSecondary,
        size: 40,
      ),
    );
  }

  Widget _buildLinkPreview() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message.linkPreviewTitle ?? message.linkPreviewUrl ?? '',
        style: const TextStyle(color: colorAccent, fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildReactions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.reactionBy ?? '',
                style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'sending':
        return const Icon(Icons.access_time, size: 12, color: colorTextMuted);
      case 'sent':
        return const Icon(Icons.check, size: 12, color: colorTextMuted);
      case 'delivered':
        return const Icon(Icons.done_all, size: 12, color: colorTextMuted);
      case 'read':
        return const Icon(Icons.done_all, size: 12, color: colorAccent);
      default:
        return const SizedBox.shrink();
    }
  }
}
