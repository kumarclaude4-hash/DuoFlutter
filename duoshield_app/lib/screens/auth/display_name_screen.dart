import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../crypto/seed_phrase_helper.dart';
import '../../network/push_server.dart';
import '../../services/auth_service.dart';
import '../../widgets/ds_button.dart';
import '../../widgets/ds_text_field.dart';

class DisplayNameScreen extends StatefulWidget {
  const DisplayNameScreen({super.key});

  @override
  State<DisplayNameScreen> createState() => _DisplayNameScreenState();
}

class _DisplayNameScreenState extends State<DisplayNameScreen> {
  final _nameController = TextEditingController();
  String _errorText = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() => _errorText = '');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Please enter a display name');
      return;
    }
    setState(() => _loading = true);
    try {
      final mnemonic = SeedPhraseHelper.generateMnemonic();
      final userId = SeedPhraseHelper.deriveUserId(mnemonic);
      final identityKeyBytes = SeedPhraseHelper.deriveIdentityKeyPrivate(mnemonic);
      final identityKey = base64.encode(identityKeyBytes);

<<<<<<< HEAD
<<<<<<< HEAD
      final token = await PushServer.mintToken(userId, 'f9ee71080e6574bfdafcd7b113b211632fa486f68ae37676123d66f099730cb7')
=======
      final token = await PushServer.mintToken(userId, 'AUTH_SECRET')
>>>>>>> f87dab5 (Add request validation middleware to API server routes)
=======
      final token = await PushServer.mintToken(userId, 'f9ee71080e6574bfdafcd7b113b211632fa486f68ae37676123d66f099730cb7')
>>>>>>> 8f89198 (Fix navigation route names in auth screens)
          .timeout(const Duration(seconds: 30));
      await AuthService.signInWithCustomToken(token);

      if (!mounted) return;
      context.push('/seed-phrase-display', extra: {
        'mnemonic': mnemonic,
        'displayName': name,
        'identityKey': identityKey,
        'userId': userId,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().contains('TimeoutException')
            ? 'Timed out. Check your connection.'
            : 'Sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _nameController.text.trim().isNotEmpty && !_loading;
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  const Text('Choose a Display Name',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorTextPrimary)),
                  const SizedBox(height: 8),
                  const Text('This is how others will see you.',
                      style: TextStyle(fontSize: 14, color: colorTextSecondary)),
                  const SizedBox(height: 32),
                  DSTextField(
                    hint: 'Your name',
                    controller: _nameController,
                    maxLength: 32,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  if (_errorText.isNotEmpty)
                    Text(_errorText, style: const TextStyle(fontSize: 13, color: colorError)),
                  const Spacer(),
                  DSButton(
                    text: 'Continue',
                    gradient: true,
                    enabled: canProceed,
                    onTap: _proceed,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (_loading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator(color: colorAccent)),
              ),
          ],
        ),
      ),
    );
  }
}
