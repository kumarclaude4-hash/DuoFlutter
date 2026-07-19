import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/colors.dart';
import '../../security/secure_prefs.dart';
import '../../core/constants.dart';
import '../../widgets/ds_button.dart';

class SeedPhraseDisplayScreen extends StatefulWidget {
  final String mnemonic;
  final String displayName;
  final String identityKey;
  final String userId;

  const SeedPhraseDisplayScreen({
    super.key,
    required this.mnemonic,
    required this.displayName,
    required this.identityKey,
    required this.userId,
  });

  @override
  State<SeedPhraseDisplayScreen> createState() => _SeedPhraseDisplayScreenState();
}

class _SeedPhraseDisplayScreenState extends State<SeedPhraseDisplayScreen> {
  bool _cbSavedChecked = false;
  bool _loading = false;
  String _statusText = '';

  List<String> get _words => widget.mnemonic.split(' ');

  Future<void> _deriveAndStore() async {
    setState(() {
      _loading = true;
      _statusText = 'Registering identity...';
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final fs = FirebaseFirestore.instance;

      await fs.collection('identities').doc(widget.userId).set(
          {'uid': user.uid}, SetOptions(merge: true));

      setState(() => _statusText = 'Saving profile...');
      await fs.collection('users').doc(user.uid).set({
        'displayName': widget.displayName,
        'userId': widget.userId,
      }, SetOptions(merge: true));

      setState(() => _statusText = 'Setting up encryption...');
      await SecurePrefs.instance.set(AppConstants.prefSignalPreKeyNextId, '26');

      final preKeys = List.generate(25, (i) => {
        'id': i + 1,
        'publicKey': base64.encode(List.generate(32, (j) => (i * j + 1) % 256)),
      });

      await fs.collection('identities').doc(widget.userId).set({
        'identityKey': widget.identityKey,
        'signedPreKey': {
          'id': 1,
          'publicKey': widget.identityKey,
          'signature': widget.identityKey,
        },
        'preKeys': preKeys,
      }, SetOptions(merge: true));

      setState(() => _statusText = 'Done!');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.go('/conversations');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusText = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload your keys. Please try again.')),
      );
    }
  }

  void _showMnemonicQrDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorSurface,
        title: const Text('Scan to Restore', style: TextStyle(color: colorTextPrimary)),
        content: Center(
          child: QrImageView(data: widget.mnemonic, size: 240),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: colorAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorTextPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Recovery Phrase',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorTextPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Write down these 12 words in order and keep them safe.\nAnyone with these words can access your account.',
                style: TextStyle(fontSize: 13, color: colorTextSecondary),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(_words.length, (i) => _WordTile(i + 1, _words[i])),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_outlined, color: colorAccent),
                      label: const Text('Copy', style: TextStyle(color: colorAccent)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.mnemonic));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: colorAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_outlined, color: colorAccent),
                      label: const Text('Show QR', style: TextStyle(color: colorAccent)),
                      onPressed: _showMnemonicQrDialog,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: colorAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _cbSavedChecked,
                    onChanged: (v) => setState(() => _cbSavedChecked = v!),
                    activeColor: colorAccent,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _cbSavedChecked = !_cbSavedChecked),
                      child: const Text(
                        "I've written down my recovery phrase",
                        style: TextStyle(fontSize: 13, color: colorTextPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_statusText.isNotEmpty)
                Text(_statusText, style: const TextStyle(fontSize: 12, color: colorTextMuted),
                    textAlign: TextAlign.center),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(color: colorAccent),
                ),
              const SizedBox(height: 16),
              DSButton(
                text: 'Continue',
                gradient: true,
                enabled: _cbSavedChecked && !_loading,
                onTap: _deriveAndStore,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  final int index;
  final String word;

  const _WordTile(this.index, this.word);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Text('#$index', style: const TextStyle(fontSize: 10, color: colorTextMuted)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(word,
                style: const TextStyle(fontWeight: FontWeight.bold, color: colorTextPrimary),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
