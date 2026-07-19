import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../security/secure_prefs.dart';
import '../../core/constants.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _readReceipts = true;
  bool _showLastSeen = true;
  bool _typingIndicators = true;
  bool _linkPreviews = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final readReceipts = await SecurePrefs.instance.getBool(AppConstants.prefReadReceiptsEnabled, defaultValue: true);
    final lastSeen = await SecurePrefs.instance.getBool(AppConstants.prefShowLastSeen, defaultValue: true);
    final typing = await SecurePrefs.instance.getBool(AppConstants.prefTypingIndicators, defaultValue: true);
    final previews = await SecurePrefs.instance.getBool(AppConstants.prefLinkPreviews, defaultValue: true);
    if (!mounted) return;
    setState(() {
      _readReceipts = readReceipts;
      _showLastSeen = lastSeen;
      _typingIndicators = typing;
      _linkPreviews = previews;
      _loading = false;
    });
  }

  Future<void> _save(String key, bool val) async {
    await SecurePrefs.instance.setBool(key, val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(title: const Text('Privacy'), backgroundColor: colorSurface),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: colorAccent))
          : ListView(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.done_all, color: colorTextPrimary),
                  title: const Text('Read Receipts', style: TextStyle(color: colorTextPrimary)),
                  subtitle: const Text('Show when you\'ve read messages', style: TextStyle(color: colorTextSecondary, fontSize: 12)),
                  value: _readReceipts,
                  activeColor: colorAccent,
                  onChanged: (v) {
                    setState(() => _readReceipts = v);
                    _save(AppConstants.prefReadReceiptsEnabled, v);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.access_time, color: colorTextPrimary),
                  title: const Text('Show Last Seen', style: TextStyle(color: colorTextPrimary)),
                  subtitle: const Text('Show others when you were last active', style: TextStyle(color: colorTextSecondary, fontSize: 12)),
                  value: _showLastSeen,
                  activeColor: colorAccent,
                  onChanged: (v) {
                    setState(() => _showLastSeen = v);
                    _save(AppConstants.prefShowLastSeen, v);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.keyboard_outlined, color: colorTextPrimary),
                  title: const Text('Typing Indicators', style: TextStyle(color: colorTextPrimary)),
                  subtitle: const Text('Show when you\'re typing', style: TextStyle(color: colorTextSecondary, fontSize: 12)),
                  value: _typingIndicators,
                  activeColor: colorAccent,
                  onChanged: (v) {
                    setState(() => _typingIndicators = v);
                    _save(AppConstants.prefTypingIndicators, v);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.link, color: colorTextPrimary),
                  title: const Text('Link Previews', style: TextStyle(color: colorTextPrimary)),
                  subtitle: const Text('Generate previews for links in messages', style: TextStyle(color: colorTextSecondary, fontSize: 12)),
                  value: _linkPreviews,
                  activeColor: colorAccent,
                  onChanged: (v) {
                    setState(() => _linkPreviews = v);
                    _save(AppConstants.prefLinkPreviews, v);
                  },
                ),
              ],
            ),
    );
  }
}
