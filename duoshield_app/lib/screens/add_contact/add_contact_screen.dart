import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/colors.dart';
import '../../db/contact_dao.dart';
import '../../db/conversation_dao.dart';
import '../../models/contact.dart';
import '../../models/conversation.dart';
import '../../network/push_server.dart';
import '../../security/app_lock_manager.dart';
import '../../widgets/ds_button.dart';
import '../../widgets/ds_text_field.dart';

class AddContactScreen extends StatefulWidget {
  final String? prefill;

  const AddContactScreen({super.key, this.prefill});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _idController = TextEditingController();
  bool _loading = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
    _loadMyUserId();
    if (widget.prefill != null) {
      _idController.text = widget.prefill!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _addByUserId(widget.prefill!));
    }
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _loadMyUserId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() => _myUserId = doc.data()?['userId'] as String?);
  }

  Future<void> _addByUserId(String userId) async {
    final cleaned = userId.trim().toUpperCase();
    final regex = RegExp(r'^[A-Z2-9]{5}-[A-Z2-9]{5}-[A-Z2-9]{3}$');
    if (!regex.hasMatch(cleaned)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid DuoShield ID format')));
      return;
    }
    setState(() => _loading = true);
    try {
      final idDoc = await FirebaseFirestore.instance
          .collection('identities')
          .doc(cleaned)
          .get();
      if (!idDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')));
        return;
      }
      final partnerUid = idDoc.data()?['uid'] as String?;
      if (partnerUid == null) return;

      final myUid = FirebaseAuth.instance.currentUser!.uid;
      final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();
      final chatId = await PushServer.createChat(myUid, partnerUid, idToken!);

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(partnerUid).get();
      final displayName = userDoc.data()?['displayName'] as String? ?? 'Unknown';

      await ContactDao().insert(Contact(
        uid: partnerUid,
        userId: cleaned,
        displayName: displayName,
        conversationId: chatId,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      await ConversationDao().insert(Conversation(
        id: chatId,
        partnerUid: partnerUid,
        partnerName: displayName,
      ));

      if (!mounted) return;
      context.go('/chat/$chatId', extra: {'partnerUid': partnerUid});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: const Text('Add Contact'),
        backgroundColor: colorSurface,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(tabs: [
              Tab(text: 'Enter ID'),
              Tab(text: 'Scan QR'),
              Tab(text: 'Paste Link'),
            ]),
            Expanded(
              child: TabBarView(children: [
                _buildEnterIdTab(),
                _buildScanQrTab(),
                _buildShareTab(),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterIdTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          DSTextField(
            hint: 'XXXXX-XXXXX-XXX',
            controller: _idController,
            maxLength: 17,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          DSButton(
            text: 'Add Contact',
            gradient: true,
            enabled: !_loading,
            onTap: () => _addByUserId(_idController.text),
          ),
          if (_loading) const Padding(
            padding: EdgeInsets.only(top: 16),
            child: CircularProgressIndicator(color: colorAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildScanQrTab() {
    return MobileScanner(
      onDetect: (capture) {
        final code = capture.barcodes.firstOrNull?.rawValue;
        if (code != null && code.startsWith('duoshield://add/')) {
          _addByUserId(code.replaceFirst('duoshield://add/', ''));
        }
      },
    );
  }

  Widget _buildShareTab() {
    final myId = _myUserId ?? '...';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Share your DuoShield ID', style: TextStyle(color: colorTextSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              myId,
              style: const TextStyle(
                color: colorAccent,
                fontFamily: 'monospace',
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, color: colorAccent),
                  label: const Text('Copy', style: TextStyle(color: colorAccent)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: 'duoshield://add/$myId'));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied!')));
                  },
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: colorAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share, color: colorAccent),
                  label: const Text('Share', style: TextStyle(color: colorAccent)),
                  onPressed: () => Share.share('duoshield://add/$myId'),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: colorAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
