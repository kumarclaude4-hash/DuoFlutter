import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/colors.dart';
import '../../db/group_dao.dart';
import '../../db/message_dao.dart';
import '../../models/group_member.dart';
import '../../models/message.dart';
import '../../security/app_lock_manager.dart';
import '../../widgets/ds_text_field.dart';
import '../../widgets/ds_bottom_sheet.dart';
import '../../widgets/message_bubble.dart';
import '../../network/push_server.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final MessageDao _messageDao = MessageDao();
  final GroupDao _groupDao = GroupDao();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  List<GroupMember> _members = [];
  StreamSubscription? _msgSub;
  String? _myUid;
  String _groupName = '';
  bool _sendingEnabled = true;

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _loadGroup();
    _listenMessages();
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    _msgSub?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    final group = await _groupDao.getGroupById(widget.groupId);
    final members = await _groupDao.getMembersByGroup(widget.groupId);
    if (!mounted) return;
    setState(() {
      _groupName = group?.name ?? 'Group';
      _members = members;
    });
  }

  void _listenMessages() {
    _msgSub = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snap) async {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          final id = data['id'] as String? ?? change.doc.id;
          final msg = Message(
            id: id,
            chatId: widget.groupId,
            senderId: data['senderId'] as String? ?? '',
            text: data['ciphertext'] as String? ?? '',
            timestamp: (data['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            sigType: 1,
          );
          await _messageDao.insert(msg);
          if (!mounted) return;
          setState(() {
            _messages.add(msg);
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || !_sendingEnabled) return;
    setState(() => _sendingEnabled = false);
    _msgController.clear();
    final id = const Uuid().v4();
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .doc(id)
          .set({
        'id': id,
        'senderId': _myUid,
        'ciphertext': base64.encode(text.codeUnits),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'lastMessage': text.length > 80 ? text.substring(0, 80) : text,
        'lastMessageTs': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')));
    } finally {
      if (mounted) setState(() => _sendingEnabled = true);
    }
  }

  String _senderNameFor(String uid) {
    try {
      return _members.firstWhere((m) => m.memberUid == uid).displayName;
    } catch (_) {
      return uid;
    }
  }

  void _showGroupMenu() async {
    final result = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 56, 0, 0),
      color: colorSurface,
      items: [
        const PopupMenuItem(value: 'info', child: Text('Group Info', style: TextStyle(color: colorTextPrimary))),
        const PopupMenuItem(value: 'add', child: Text('Add Member', style: TextStyle(color: colorTextPrimary))),
        const PopupMenuItem(value: 'leave', child: Text('Leave Group', style: TextStyle(color: colorError))),
      ],
    );
    if (result == 'info') _showMemberList();
    else if (result == 'leave') _leaveGroup();
  }

  void _showMemberList() {
    DSBottomSheet.show(context, title: 'Members', children: _members.map((m) => ListTile(
      leading: CircleAvatar(backgroundColor: colorAccent,
          child: Text(m.displayName.isNotEmpty ? m.displayName[0] : '?',
              style: const TextStyle(color: Colors.white))),
      title: Text(m.displayName, style: const TextStyle(color: colorTextPrimary)),
    )).toList());
  }

  Future<void> _leaveGroup() async {
    final myUid = _myUid;
    if (myUid == null) return;
    try {
      final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();
      await PushServer.removeGroupMember(widget.groupId, myUid, idToken!);
      await _groupDao.deleteMember(widget.groupId, myUid);
      if (!mounted) return;
      context.go('/conversations');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: colorSurface,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: colorTextPrimary),
                      onPressed: () => context.pop()),
                  Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_groupName, style: const TextStyle(color: colorTextPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('${_members.length} members', style: const TextStyle(fontSize: 11, color: colorTextSecondary)),
                    ],
                  )),
                  IconButton(icon: const Icon(Icons.more_vert, color: colorIconDefault), onPressed: _showGroupMenu),
                ],
              ),
            ),
            Expanded(child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isMe = msg.senderId == _myUid;
                return MessageBubble(
                  message: msg, isMe: isMe,
                  senderName: isMe ? null : _senderNameFor(msg.senderId),
                );
              },
            )),
            Container(
              color: colorSurface,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: DSTextField(hint: 'Message', controller: _msgController, maxLines: 6, minLines: 1)),
                  IconButton(icon: Icon(Icons.send, color: _sendingEnabled ? colorAccent : colorTextMuted),
                      onPressed: _sendingEnabled ? _sendMessage : null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
