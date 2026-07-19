import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/colors.dart';
import '../../db/message_dao.dart';
import '../../models/message.dart';
import '../../security/app_lock_manager.dart';
import '../../security/secure_prefs.dart';
import '../../core/constants.dart';
import '../../widgets/ds_text_field.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_dots_view.dart';
import '../../widgets/ds_bottom_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String partnerUid;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.partnerUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageDao _messageDao = MessageDao();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  StreamSubscription? _msgSub;
  StreamSubscription? _chatSub;
  String? _myUid;
  String _partnerName = '';
  String _partnerStatus = '';
  bool _partnerTyping = false;
  Message? _replyTo;
  bool _sendingEnabled = true;
  bool _safetyBannerVisible = false;
  Timer? _typingTimer;
  final Set<String> _knownIds = {};

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _loadLocal();
    _listenMessages();
    _listenChatMeta();
    _listenPresence();
    _checkSafetyBanner();
    _msgController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    _msgSub?.cancel();
    _chatSub?.cancel();
    _typingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLocal() async {
    final msgs = await _messageDao.getByChat(widget.conversationId);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      for (final m in msgs) _knownIds.add(m.id);
    });
  }

  void _listenMessages() {
    _msgSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snap) async {
      for (final change in snap.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        if (change.type == DocumentChangeType.added) {
          final id = data['id'] as String? ?? change.doc.id;
          if (_knownIds.contains(id)) continue;
          _knownIds.add(id);
          final msg = Message(
            id: id,
            chatId: widget.conversationId,
            senderId: data['senderId'] as String? ?? '',
            text: data['ciphertext'] as String? ?? '',
            timestamp: (data['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            status: data['status'] as String? ?? 'sent',
            sigType: data['sigType'] as int? ?? 0,
            replyToId: data['replyToId'] as String?,
            mediaType: data['mediaType'] as String?,
            mediaUrl: data['path'] as String?,
            mediaKey: data['mediaKey'] as String?,
          );
          await _messageDao.insert(msg);
          if (!mounted) return;
          setState(() {
            _messages.add(msg);
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
          if (msg.senderId != _myUid) {
            FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.conversationId)
                .collection('messages')
                .doc(id)
                .update({'status': 'read'});
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        } else if (change.type == DocumentChangeType.modified) {
          final id = data['id'] as String? ?? change.doc.id;
          if (data['deletedForAll'] == true) {
            await _messageDao.delete(id);
            setState(() => _messages.removeWhere((m) => m.id == id));
          }
        }
      }
    });
  }

  void _listenChatMeta() {
    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.conversationId)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      if (data == null || !mounted) return;
      final typingKey = 'typing_${widget.partnerUid}';
      setState(() => _partnerTyping = data[typingKey] as bool? ?? false);
    });
  }

  void _listenPresence() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.partnerUid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      if (data == null) return;
      final online = data['online'] as bool? ?? false;
      final name = data['displayName'] as String? ?? '';
      setState(() {
        _partnerName = name;
        _partnerStatus = online ? 'Online' : 'Last seen recently';
      });
    });
  }

  Future<void> _checkSafetyBanner() async {
    final changed = await SecurePrefs.instance.getBool(
        '${AppConstants.prefSafetyNumChanged}${widget.partnerUid}');
    if (mounted) setState(() => _safetyBannerVisible = changed);
  }

  void _onTypingChanged() {
    final myUid = _myUid;
    if (myUid == null) return;
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.conversationId)
        .update({'typing_$myUid': true});
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.conversationId)
          .update({'typing_$myUid': false});
    });
    setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || !_sendingEnabled) return;
    setState(() => _sendingEnabled = false);
    _msgController.clear();

    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final msg = Message(
      id: id,
      chatId: widget.conversationId,
      senderId: _myUid!,
      text: text,
      timestamp: now,
      status: 'sending',
      replyToId: _replyTo?.id,
    );
    setState(() {
      _messages.add(msg);
      _replyTo = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(id)
          .set({
        'id': id,
        'senderId': _myUid,
        'ciphertext': base64.encode(text.codeUnits),
        'sigType': 1,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'deletedForAll': false,
        'type': 'text',
        'replyToId': _replyTo?.id,
      });
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.conversationId)
          .set({
        'lastMessage': text.length > 80 ? text.substring(0, 80) : text,
        'lastMessageTs': now,
      }, SetOptions(merge: true));
      await _messageDao.insert(msg.copyWith(status: 'sent'));
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == id);
        if (idx != -1) _messages[idx] = msg.copyWith(status: 'sent');
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')));
    } finally {
      if (mounted) setState(() => _sendingEnabled = true);
    }
  }

  void _showMessageOptions(Message msg) {
    final emojis = ['❤️', '😂', '😮', '😢', '👍', '👎'];
    DSBottomSheet.show(context, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis.map((e) => GestureDetector(
            onTap: () {
              Navigator.pop(context);
              FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .doc(msg.id)
                  .update({'reactions.${_myUid}': e});
            },
            child: Text(e, style: const TextStyle(fontSize: 28)),
          )).toList(),
        ),
      ),
      const Divider(color: colorDivider),
      ListTile(leading: const Icon(Icons.reply, color: colorTextPrimary),
          title: const Text('Reply', style: TextStyle(color: colorTextPrimary)),
          onTap: () { Navigator.pop(context); setState(() => _replyTo = msg); }),
      ListTile(leading: const Icon(Icons.copy, color: colorTextPrimary),
          title: const Text('Copy', style: TextStyle(color: colorTextPrimary)),
          onTap: () { Navigator.pop(context); }),
      if (msg.senderId == _myUid)
        ListTile(leading: const Icon(Icons.edit, color: colorTextPrimary),
            title: const Text('Edit', style: TextStyle(color: colorTextPrimary)),
            onTap: () { Navigator.pop(context); _showEditDialog(msg); }),
      ListTile(leading: const Icon(Icons.delete_outline, color: colorError),
          title: const Text('Delete locally', style: TextStyle(color: colorError)),
          onTap: () async {
            Navigator.pop(context);
            await _messageDao.delete(msg.id);
            setState(() => _messages.removeWhere((m) => m.id == msg.id));
          }),
      if (msg.senderId == _myUid)
        ListTile(leading: const Icon(Icons.delete_forever, color: colorError),
            title: const Text('Delete for everyone', style: TextStyle(color: colorError)),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('chats').doc(widget.conversationId)
                  .collection('messages').doc(msg.id)
                  .update({'deletedForAll': true});
            }),
    ]);
  }

  void _showEditDialog(Message msg) {
    final ctrl = TextEditingController(text: msg.text);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: colorSurface,
      title: const Text('Edit Message', style: TextStyle(color: colorTextPrimary)),
      content: TextField(controller: ctrl, maxLines: null,
          style: const TextStyle(color: colorTextPrimary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: colorTextSecondary))),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          final newText = ctrl.text.trim();
          await FirebaseFirestore.instance
              .collection('chats').doc(widget.conversationId)
              .collection('messages').doc(msg.id)
              .update({'editedCiphertext': newText, 'edited': true});
          await _messageDao.update(msg.id, {'edited': 1, 'editedText': newText});
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msg.id);
            if (idx != -1) _messages[idx] = msg.copyWith(edited: true, editedText: newText);
          });
        }, child: const Text('Save', style: TextStyle(color: colorAccent))),
      ],
    ));
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: colorTextPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const CircleAvatar(radius: 18, backgroundColor: colorAccent,
                      child: Icon(Icons.person, size: 18, color: Colors.white)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_partnerName.isNotEmpty ? _partnerName : 'Chat',
                            style: const TextStyle(color: colorTextPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(_partnerStatus, style: const TextStyle(fontSize: 11, color: colorTextSecondary)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.timer_outlined, color: colorIconDefault), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.security_outlined, color: colorIconDefault),
                      onPressed: () => context.push('/safety-numbers', extra: widget.partnerUid)),
                  IconButton(icon: const Icon(Icons.more_vert, color: colorIconDefault), onPressed: () {}),
                ],
              ),
            ),
            if (_safetyBannerVisible)
              Container(
                color: colorWarning.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: colorWarning, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text("Security codes changed. Verify your contact.",
                        style: TextStyle(color: colorWarning, fontSize: 12))),
                    TextButton(onPressed: () => context.push('/safety-numbers', extra: widget.partnerUid),
                        child: const Text('Verify', style: TextStyle(color: colorWarning))),
                    IconButton(icon: const Icon(Icons.close, color: colorWarning, size: 16),
                        onPressed: () => setState(() => _safetyBannerVisible = false)),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) => GestureDetector(
                  onLongPress: () => _showMessageOptions(_messages[i]),
                  child: MessageBubble(
                    message: _messages[i],
                    isMe: _messages[i].senderId == _myUid,
                  ),
                ),
              ),
            ),
            if (_partnerTyping)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(alignment: Alignment.centerLeft, child: TypingDotsView()),
              ),
            if (_replyTo != null)
              Container(
                color: colorSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Container(width: 3, height: 40, color: colorAccent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_replyTo!.text,
                        style: const TextStyle(color: colorTextSecondary, fontSize: 12),
                        maxLines: 1)),
                    IconButton(icon: const Icon(Icons.close, color: colorTextMuted, size: 18),
                        onPressed: () => setState(() => _replyTo = null)),
                  ],
                ),
              ),
            Container(
              color: colorSurface,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.attach_file, color: colorIconDefault), onPressed: () {}),
                  Expanded(
                    child: DSTextField(
                      hint: 'Message',
                      controller: _msgController,
                      maxLines: 6,
                      minLines: 1,
                    ),
                  ),
                  if (_msgController.text.isEmpty)
                    IconButton(icon: const Icon(Icons.mic, color: colorAccent), onPressed: () {})
                  else
                    IconButton(
                      icon: Icon(Icons.send, color: _sendingEnabled ? colorAccent : colorTextMuted),
                      onPressed: _sendingEnabled ? _sendMessage : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
