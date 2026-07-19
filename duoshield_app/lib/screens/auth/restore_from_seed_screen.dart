import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../crypto/seed_phrase_helper.dart';
import '../../network/push_server.dart';
import '../../services/auth_service.dart';
import '../../widgets/ds_button.dart';
import '../../widgets/ds_text_field.dart';

class RestoreFromSeedScreen extends StatefulWidget {
  const RestoreFromSeedScreen({super.key});

  @override
  State<RestoreFromSeedScreen> createState() => _RestoreFromSeedScreenState();
}

class _RestoreFromSeedScreenState extends State<RestoreFromSeedScreen> {
  final _accountIdController = TextEditingController();
  final _seedWordsController = TextEditingController();
  String _errorText = '';
  String _stepText = '';
  bool _loading = false;

  Future<void> _attemptRestore() async {
    final accountId = _accountIdController.text.trim();
    final seedWords = _seedWordsController.text.trim();

    if (accountId.isEmpty || seedWords.isEmpty) {
      setState(() => _errorText = 'Please fill in all fields.');
      return;
    }

    final words = seedWords.split(RegExp(r'\s+'));
    if (words.length != 12) {
      setState(() => _errorText = 'Please enter exactly 12 words.');
      return;
    }

    for (final word in words) {
      final validation = SeedPhraseHelper.validateMnemonicDetailed(words.join(' '));
      if (!validation.valid) {
        setState(() => _errorText = validation.error ?? 'Invalid word.');
        return;
      }
      break;
    }

    setState(() {
      _loading = true;
      _stepText = 'Validating phrase...';
      _errorText = '';
    });

    try {
      final mnemonic = words.join(' ');
      final derivedUserId = SeedPhraseHelper.deriveUserId(mnemonic);

      if (derivedUserId.toUpperCase() != accountId.toUpperCase()) {
        setState(() {
          _loading = false;
          _errorText = 'Account ID does not match this recovery phrase.';
          _stepText = '';
        });
        return;
      }

      setState(() => _stepText = 'Signing in...');
      final token = await PushServer.mintToken(derivedUserId, 'AUTH_SECRET')
      final token = await PushServer.mintToken(derivedUserId, 'f9ee71080e6574bfdafcd7b113b211632fa486f68ae37676123d66f099730cb7')
          .timeout(const Duration(seconds: 60));
      final cred = await AuthService.signInWithCustomToken(token);
      final user = cred.user!;

      setState(() => _stepText = 'Fetching account data...');
      final idDoc = await FirebaseFirestore.instance
          .collection('identities')
          .doc(derivedUserId)
          .get();
      final idData = idDoc.data();
      if (idData != null && idData['uid'] != user.uid) {
        final idToken = await user.getIdToken();
        await PushServer.migrateUid(idData['uid'] as String, user.uid, idToken!);
      }

      setState(() => _stepText = 'Restoring messages...');
      setState(() => _stepText = 'Done!');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.go('/conversations');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('TimeoutException')
          ? 'Restore timed out. Check your connection.'
          : 'Restore failed: ${e.toString()}';
      setState(() {
        _loading = false;
        _stepText = '';
        _errorText = msg;
      });
    }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Restore Account',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorTextPrimary)),
              const SizedBox(height: 8),
              const Text('Enter your DuoShield ID and 12-word recovery phrase.',
                  style: TextStyle(fontSize: 13, color: colorTextSecondary)),
              const SizedBox(height: 32),
              DSTextField(
                hint: 'Account ID (XXXXX-XXXXX-XXX)',
                controller: _accountIdController,
                maxLength: 17,
                keyboardType: TextInputType.visiblePassword,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              DSTextField(
                hint: 'Enter 12 recovery words separated by spaces',
                controller: _seedWordsController,
                maxLines: 4,
                minLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 8),
              if (_errorText.isNotEmpty)
                Text(_errorText, style: const TextStyle(fontSize: 13, color: colorError)),
              const SizedBox(height: 8),
              if (_stepText.isNotEmpty)
                Text(_stepText, style: const TextStyle(fontSize: 12, color: colorTextMuted)),
              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(color: colorAccent),
              const Spacer(),
              DSButton(
                text: 'Restore Account',
                gradient: true,
                enabled: !_loading,
                onTap: _attemptRestore,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
