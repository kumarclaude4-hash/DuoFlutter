import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../widgets/ds_button.dart';
import '../../widgets/ds_text_field.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;
  bool _saving = false;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;
    setState(() {
      _nameController.text = doc.data()?['displayName'] as String? ?? '';
      _userId = doc.data()?['userId'] as String? ?? '';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'displayName': name});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: colorSurface),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: colorAccent))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        const CircleAvatar(radius: 48, backgroundColor: colorAccent,
                            child: Icon(Icons.person, size: 48, color: Colors.white)),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 28, height: 28,
                            decoration: const BoxDecoration(color: colorSurface, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 14, color: colorTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Display Name', style: TextStyle(color: colorTextSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  DSTextField(hint: 'Your name', controller: _nameController, maxLength: 32),
                  const SizedBox(height: 24),
                  const Text('DuoShield ID', style: TextStyle(color: colorTextSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _userId));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: colorSurface, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Text(_userId, style: const TextStyle(color: colorTextPrimary, fontFamily: 'monospace', fontSize: 15)),
                          const Spacer(),
                          const Icon(Icons.copy, color: colorTextMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  DSButton(text: 'Save', gradient: true, enabled: _nameController.text.trim().isNotEmpty && !_saving, onTap: _saveProfile),
                ],
              ),
            ),
    );
  }
}
