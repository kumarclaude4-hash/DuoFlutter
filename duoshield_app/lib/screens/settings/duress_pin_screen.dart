import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../crypto/pin_hasher.dart';
import '../../security/secure_prefs.dart';

class DuressPinScreen extends StatefulWidget {
  const DuressPinScreen({super.key});

  @override
  State<DuressPinScreen> createState() => _DuressPinScreenState();
}

class _DuressPinScreenState extends State<DuressPinScreen> {
  String _pinInput = '';
  String _newPin = '';
  bool _confirming = false;
  String? _errorText;
  bool _hasDuressPin = false;

  @override
  void initState() {
    super.initState();
    _checkDuressPin();
  }

  Future<void> _checkDuressPin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final hash = await SecurePrefs.instance.get('${AppConstants.prefDuressPinHash}$uid');
    setState(() => _hasDuressPin = hash != null);
  }

  void _onDigitTap(String d) {
    if (_pinInput.length >= 4) return;
    setState(() => _pinInput += d);
    if (_pinInput.length == 4) {
      Future.delayed(const Duration(milliseconds: 100), _handlePinComplete);
    }
  }

  void _onBackspace() {
    if (_pinInput.isEmpty) return;
    setState(() => _pinInput = _pinInput.substring(0, _pinInput.length - 1));
  }

  Future<void> _handlePinComplete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!_confirming) {
      setState(() { _newPin = _pinInput; _confirming = true; _pinInput = ''; _errorText = null; });
    } else {
      if (_pinInput == _newPin) {
        final hash = PinHasher.hashPin(_pinInput);
        await SecurePrefs.instance.set('${AppConstants.prefDuressPinHash}$uid', hash);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duress PIN saved')));
        context.pop();
      } else {
        setState(() { _errorText = 'PINs do not match.'; _pinInput = ''; _confirming = false; });
      }
    }
  }

  Future<void> _removeDuressPin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await SecurePrefs.instance.remove('${AppConstants.prefDuressPinHash}$uid');
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: const Text('Duress PIN'),
        backgroundColor: colorSurface,
        actions: [
          if (_hasDuressPin)
            TextButton(onPressed: _removeDuressPin,
                child: const Text('Remove', style: TextStyle(color: colorError))),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.warning_amber, color: colorWarning, size: 48),
                const SizedBox(height: 12),
                Text(_confirming ? 'Confirm Duress PIN' : 'Set Duress PIN',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorTextPrimary)),
                const SizedBox(height: 8),
                const Text(
                  'Entering this PIN will immediately wipe all data and sign you out. Use in emergency situations.',
                  style: TextStyle(color: colorTextSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Container(
            width: 16, height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pinInput.length ? colorError : colorSurfaceVariant,
            ),
          ))),
          const SizedBox(height: 16),
          if (_errorText != null)
            Text(_errorText!, style: const TextStyle(color: colorError, fontSize: 13)),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              children: [
                for (final d in ['1','2','3','4','5','6','7','8','9'])
                  GestureDetector(onTap: () => _onDigitTap(d), child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: colorSurface, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(d, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorTextPrimary))),
                  )),
                const SizedBox.shrink(),
                GestureDetector(onTap: () => _onDigitTap('0'), child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: colorSurface, borderRadius: BorderRadius.circular(8)),
                  child: const Center(child: Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorTextPrimary))),
                )),
                GestureDetector(onTap: _onBackspace,
                    child: const Icon(Icons.backspace_outlined, color: colorTextPrimary, size: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
