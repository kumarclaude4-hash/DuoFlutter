import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/colors.dart';
import '../../db/contact_dao.dart';
import '../../db/group_dao.dart';
import '../../models/contact.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../security/app_lock_manager.dart';
import '../../widgets/ds_button.dart';
import '../../widgets/ds_text_field.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  List<Contact> _contacts = [];
  final Set<String> _selectedUids = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
    _loadContacts();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactDao().getAll();
    setState(() => _contacts = contacts);
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedUids.length < 2) return;
    setState(() => _loading = true);
    try {
      final myUid = FirebaseAuth.instance.currentUser!.uid;
      final groupId = const Uuid().v4();
      final rng = Random.secure();
      final groupKey = Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
      final groupKeyB64 = base64.encode(groupKey);
      final members = [myUid, ..._selectedUids];
      final fs = FirebaseFirestore.instance;

      for (final uid in members) {
        await fs.collection('groups').doc(groupId).collection('keys').doc(uid).set({
          'encryptedKey': groupKeyB64,
        });
      }
      await fs.collection('groups').doc(groupId).set({
        'name': name,
        'createdBy': myUid,
        'createdAt': FieldValue.serverTimestamp(),
        'members': members,
        'lastMessage': '',
        'lastMessageTs': 0,
      });

      final groupDao = GroupDao();
      await groupDao.insertGroup(Group(
        id: groupId, name: name, createdBy: myUid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        groupKey: groupKeyB64,
      ));
      for (final uid in members) {
        final contact = _contacts.firstWhere((c) => c.uid == uid, orElse: () => Contact(uid: uid, userId: '', displayName: uid, addedAt: 0));
        await groupDao.insertMember(GroupMember(
          groupId: groupId, memberUid: uid,
          displayName: uid == myUid ? 'Me' : contact.displayName,
          joinedAt: DateTime.now().millisecondsSinceEpoch,
        ));
      }

      if (!mounted) return;
      context.push('/group-chat/$groupId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _nameController.text.trim().isNotEmpty && _selectedUids.length >= 2;
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(title: const Text('New Group'), backgroundColor: colorSurface),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CircleAvatar(radius: 44, backgroundColor: colorSurface,
                    child: Icon(Icons.camera_alt, color: colorTextMuted)),
                const SizedBox(height: 16),
                DSTextField(hint: 'Group Name', maxLength: 64, controller: _nameController),
                const SizedBox(height: 24),
                const Align(alignment: Alignment.centerLeft,
                    child: Text('Select Members',
                        style: TextStyle(fontWeight: FontWeight.bold, color: colorTextPrimary))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (_, i) {
                final c = _contacts[i];
                return CheckboxListTile(
                  title: Text(c.displayName, style: const TextStyle(color: colorTextPrimary)),
                  subtitle: Text(c.userId, style: const TextStyle(fontSize: 11, color: colorTextSecondary)),
                  value: _selectedUids.contains(c.uid),
                  activeColor: colorAccent,
                  onChanged: (v) => setState(() {
                    if (v == true) _selectedUids.add(c.uid);
                    else _selectedUids.remove(c.uid);
                  }),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: DSButton(
              text: 'Create Group (${_selectedUids.length} selected)',
              gradient: true,
              enabled: canCreate && !_loading,
              onTap: _createGroup,
            ),
          ),
        ],
      ),
    );
  }
}
