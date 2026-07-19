import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../db/contact_dao.dart';
import '../../security/app_lock_manager.dart';

class ContactDetailScreen extends StatefulWidget {
  final String partnerUid;
  final String partnerName;
  final String conversationId;

  const ContactDetailScreen({
    super.key,
    required this.partnerUid,
    required this.partnerName,
    required this.conversationId,
  });

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  String _partnerUserId = '';

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
    _loadContact();
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    super.dispose();
  }

  Future<void> _loadContact() async {
    final contact = await ContactDao().getByUid(widget.partnerUid);
    if (mounted && contact != null) {
      setState(() => _partnerUserId = contact.userId);
    }
  }

  void _startCall(bool isVideo) {
    context.push('/call', extra: {
      'partnerUid': widget.partnerUid,
      'partnerName': widget.partnerName,
      'isVideo': isVideo,
    });
  }

  void _confirmBlock() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: colorSurface,
      title: const Text('Block Contact', style: TextStyle(color: colorTextPrimary)),
      content: Text('Block ${widget.partnerName}?', style: const TextStyle(color: colorTextSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: colorTextSecondary))),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          await ContactDao().update(widget.partnerUid, {'blocked': 1});
          if (!mounted) return;
          context.pop();
        }, child: const Text('Block', style: TextStyle(color: colorError))),
      ],
    ));
  }

  void _confirmDelete() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: colorSurface,
      title: const Text('Delete Contact', style: TextStyle(color: colorTextPrimary)),
      content: const Text('This will delete this contact.', style: TextStyle(color: colorTextSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: colorTextSecondary))),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          await ContactDao().delete(widget.partnerUid);
          if (!mounted) return;
          context.go('/conversations');
        }, child: const Text('Delete', style: TextStyle(color: colorError))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(title: Text(widget.partnerName), backgroundColor: colorSurface),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(radius: 52, backgroundColor: colorAccent,
                child: Icon(Icons.person, size: 48, color: Colors.white)),
            const SizedBox(height: 16),
            Text(widget.partnerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorTextPrimary)),
            Text(_partnerUserId, style: const TextStyle(fontSize: 13, color: colorTextSecondary)),
            const SizedBox(height: 32),
            _buildTile(Icons.message, 'Send Message', () => context.push('/chat/${widget.conversationId}', extra: {'partnerUid': widget.partnerUid})),
            const Divider(color: colorDivider),
            _buildTile(Icons.call, 'Voice Call', () => _startCall(false)),
            const Divider(color: colorDivider),
            _buildTile(Icons.videocam, 'Video Call', () => _startCall(true)),
            const Divider(color: colorDivider),
            _buildTile(Icons.security, 'Verify Safety Numbers',
                () => context.push('/safety-numbers', extra: widget.partnerUid)),
            const Divider(color: colorDivider),
            ListTile(
              leading: const Icon(Icons.block, color: colorError),
              title: const Text('Block Contact', style: TextStyle(color: colorError)),
              onTap: _confirmBlock,
            ),
            const Divider(color: colorDivider),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: colorError),
              title: const Text('Delete Contact', style: TextStyle(color: colorError)),
              onTap: _confirmDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: colorTextPrimary),
      title: Text(title, style: const TextStyle(color: colorTextPrimary)),
      onTap: onTap,
    );
  }
}
