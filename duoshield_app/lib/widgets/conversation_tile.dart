import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/colors.dart';
import '../models/conversation.dart';
import '../core/extensions.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onArchive;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colorError,
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      onDismissed: (_) => onArchive(),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: _buildAvatar(),
          title: Text(
            conversation.partnerName,
            style: TextStyle(
              color: colorTextPrimary,
              fontWeight: conversation.unreadCount > 0
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            conversation.lastMessage,
            style: const TextStyle(color: colorTextSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                conversation.lastMessageTs > 0
                    ? conversation.lastMessageTs
                        .toDateTime()
                        .toConversationTime()
                    : '',
                style: const TextStyle(color: colorTextMuted, fontSize: 11),
              ),
              const SizedBox(height: 4),
              if (conversation.unreadCount > 0)
                CircleAvatar(
                  radius: 10,
                  backgroundColor: colorAccent,
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10),
                  ),
                )
              else if (conversation.muted)
                const Icon(Icons.volume_off,
                    color: colorTextMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (conversation.partnerAvatar != null &&
        conversation.partnerAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundImage:
            CachedNetworkImageProvider(conversation.partnerAvatar!),
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: colorSurface,
      child: Text(
        conversation.partnerName.initials,
        style: const TextStyle(
            color: colorAccent, fontWeight: FontWeight.bold),
      ),
    );
  }
}
