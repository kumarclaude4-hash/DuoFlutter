import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../security/secure_prefs.dart';
import '../../core/constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _messageSounds = true;
  bool _callSounds = true;
  bool _groupSounds = true;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final msgSounds = await SecurePrefs.instance.getBool(AppConstants.prefNotifMessageSounds, defaultValue: true);
    final callSounds = await SecurePrefs.instance.getBool(AppConstants.prefNotifCallSounds, defaultValue: true);
    final groupSounds = await SecurePrefs.instance.getBool(AppConstants.prefNotifGroupSounds, defaultValue: true);
    final preview = await SecurePrefs.instance.getBool(AppConstants.prefNotifShowPreview, defaultValue: false);
    if (!mounted) return;
    setState(() {
      _messageSounds = msgSounds;
      _callSounds = callSounds;
      _groupSounds = groupSounds;
      _showPreview = preview;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(title: const Text('Notifications'), backgroundColor: colorSurface),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: colorTextPrimary),
            title: const Text('Message Sounds', style: TextStyle(color: colorTextPrimary)),
            value: _messageSounds,
            activeColor: colorAccent,
            onChanged: (v) {
              setState(() => _messageSounds = v);
              SecurePrefs.instance.setBool(AppConstants.prefNotifMessageSounds, v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.call_outlined, color: colorTextPrimary),
            title: const Text('Call Sounds', style: TextStyle(color: colorTextPrimary)),
            value: _callSounds,
            activeColor: colorAccent,
            onChanged: (v) {
              setState(() => _callSounds = v);
              SecurePrefs.instance.setBool(AppConstants.prefNotifCallSounds, v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.group_outlined, color: colorTextPrimary),
            title: const Text('Group Sounds', style: TextStyle(color: colorTextPrimary)),
            value: _groupSounds,
            activeColor: colorAccent,
            onChanged: (v) {
              setState(() => _groupSounds = v);
              SecurePrefs.instance.setBool(AppConstants.prefNotifGroupSounds, v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.preview_outlined, color: colorTextPrimary),
            title: const Text('Show Message Preview', style: TextStyle(color: colorTextPrimary)),
            subtitle: const Text('Reveal message content in notifications', style: TextStyle(color: colorTextSecondary, fontSize: 12)),
            value: _showPreview,
            activeColor: colorAccent,
            onChanged: (v) {
              setState(() => _showPreview = v);
              SecurePrefs.instance.setBool(AppConstants.prefNotifShowPreview, v);
            },
          ),
        ],
      ),
    );
  }
}
