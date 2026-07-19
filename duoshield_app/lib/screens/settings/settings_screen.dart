import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../providers/settings_provider.dart';
import '../../security/app_lock_manager.dart';
import '../../security/duress_manager.dart';
import '../../security/secure_prefs.dart';
import '../../core/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _displayName = '';
  String _userId = '';
  bool _hasPIN = false;

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
    _loadProfile();
    _checkPIN();
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;
    setState(() {
      _displayName = doc.data()?['displayName'] as String? ?? '';
      _userId = doc.data()?['userId'] as String? ?? '';
    });
  }

  Future<void> _checkPIN() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final hash = await SecurePrefs.instance.get('${AppConstants.prefAppPinHash}$uid');
    if (mounted) setState(() => _hasPIN = hash != null);
  }

  void _confirmWipeAndExit() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: colorSurface,
      title: const Text('Wipe & Exit', style: TextStyle(color: colorTextPrimary)),
      content: const Text('This will erase all local data and sign out.', style: TextStyle(color: colorTextSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: colorTextSecondary))),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          await DuressManager.performWipe();
          if (!mounted) return;
          context.go('/sign-in');
        }, child: const Text('Wipe', style: TextStyle(color: colorError))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(title: const Text('Settings'), backgroundColor: colorSurface),
      body: ListView(
        children: [
          _sectionHeader('Account'),
          ListTile(
            leading: const CircleAvatar(radius: 22, backgroundColor: colorAccent,
                child: Icon(Icons.person, color: Colors.white)),
            title: Text(_displayName.isEmpty ? 'Loading...' : _displayName,
                style: const TextStyle(color: colorTextPrimary)),
            subtitle: Text(_userId, style: const TextStyle(fontSize: 11, color: colorTextSecondary)),
            onTap: () => context.push('/settings/profile'),
          ),
          const Divider(color: colorDivider, indent: 16, endIndent: 16),

          _sectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: colorTextPrimary),
            title: const Text('App PIN', style: TextStyle(color: colorTextPrimary)),
            subtitle: Text(_hasPIN ? 'Set' : 'Not set', style: const TextStyle(fontSize: 12, color: colorTextSecondary)),
            trailing: const Icon(Icons.chevron_right, color: colorTextMuted),
            onTap: () => context.push('/settings/pin'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: colorTextPrimary),
            title: const Text('Biometric Unlock', style: TextStyle(color: colorTextPrimary)),
            value: settings.biometricEnabled,
            activeColor: colorAccent,
            onChanged: (v) => ref.read(settingsProvider.notifier).setBiometricEnabled(v),
          ),
          ListTile(
            leading: const Icon(Icons.warning_outlined, color: colorTextPrimary),
            title: const Text('Duress PIN', style: TextStyle(color: colorTextPrimary)),
            subtitle: const Text('Wipes data on entry', style: TextStyle(fontSize: 12, color: colorTextSecondary)),
            trailing: const Icon(Icons.chevron_right, color: colorTextMuted),
            onTap: () => context.push('/settings/duress-pin'),
          ),
          const Divider(color: colorDivider, indent: 16, endIndent: 16),

          _sectionHeader('Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: colorTextPrimary),
            title: const Text('Notification Settings', style: TextStyle(color: colorTextPrimary)),
            trailing: const Icon(Icons.chevron_right, color: colorTextMuted),
            onTap: () => context.push('/settings/notifications'),
          ),
          const Divider(color: colorDivider, indent: 16, endIndent: 16),

          _sectionHeader('Storage & Backup'),
          ListTile(
            leading: const Icon(Icons.backup_outlined, color: colorTextPrimary),
            title: const Text('Backup & Restore', style: TextStyle(color: colorTextPrimary)),
            trailing: const Icon(Icons.chevron_right, color: colorTextMuted),
            onTap: () => context.push('/settings/backup'),
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined, color: colorTextPrimary),
            title: const Text('Manage Storage', style: TextStyle(color: colorTextPrimary)),
            trailing: const Icon(Icons.chevron_right, color: colorTextMuted),
            onTap: () {},
          ),
          const Divider(color: colorDivider, indent: 16, endIndent: 16),

          _sectionHeader('Privacy'),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined, color: colorTextPrimary),
            title: const Text('Privacy Settings', style: TextStyle(color: colorTextPrimary)),
            trailing: const Icon(Icons.chevron_right, color: colorTextMuted),
            onTap: () => context.push('/settings/privacy'),
          ),
          const Divider(color: colorDivider, indent: 16, endIndent: 16),

          _sectionHeader('Danger Zone'),
          ListTile(
            leading: const Icon(Icons.logout, color: colorError),
            title: const Text('Sign Out', style: TextStyle(color: colorError)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              context.go('/sign-in');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: colorError),
            title: const Text('Wipe & Exit', style: TextStyle(color: colorError)),
            subtitle: const Text('Erase all data immediately', style: TextStyle(fontSize: 11, color: colorTextMuted)),
            onTap: _confirmWipeAndExit,
          ),
          const SizedBox(height: 32),
          const Center(child: Text('DuoShield v1.0.0', style: TextStyle(color: colorTextMuted, fontSize: 12))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title.toUpperCase(),
          style: const TextStyle(fontSize: 11, color: colorTextMuted, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
    );
  }
}
