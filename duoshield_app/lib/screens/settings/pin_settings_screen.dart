import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../crypto/pin_hasher.dart';
import '../../security/secure_prefs.dart';
import '../../widgets/ds_button.dart';

enum _PinStep { enterCurrent, enterNew, confirmNew }

class PinSettingsScreen extends StatefulWidget {
  const PinSettingsScreen({super.key});

  @override
  State<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends State<PinSettingsScreen> {
  _PinStep _step = _PinStep.enterCurrent;
  String _pinInput = '';
  String _newPin = '';
  String? _errorText;
  bool _hasPIN = false;

  @override
  void initState() {
    super.initState();
    _checkPIN();
  }

  Future<void> _checkPIN() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final hash = await SecurePrefs.instance.get('${AppConstants.prefAppPinHash}$uid');
    setState(() {
      _hasPIN = hash != null;
      _step = hash == null ? _PinStep.enterNew : _PinStep.enterCurrent;
    });
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

    switch (_step) {
      case _PinStep.enterCurrent:
        final storedHash = await SecurePrefs.instance.get('${AppConstants.prefAppPinHash}$uid');
        if (storedHash != null && PinHasher.verifyPin(_pinInput, storedHash)) {
          setState(() { _step = _PinStep.enterNew; _pinInput = ''; _errorText = null; });
        } else {
          setState(() { _errorText = 'Incorrect PIN'; _pinInput = ''; });
        }
      case _PinStep.enterNew:
        setState(() { _newPin = _pinInput; _step = _PinStep.confirmNew; _pinInput = ''; _errorText = null; });
      case _PinStep.confirmNew:
        if (_pinInput == _newPin) {
          final hash = PinHasher.hashPin(_pinInput);
          await SecurePrefs.instance.set('${AppConstants.prefAppPinHash}$uid', hash);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN saved')));
          context.pop();
        } else {
          setState(() { _errorText = 'PINs do not match. Try again.'; _pinInput = ''; _step = _PinStep.enterNew; });
        }
    }
  }

  Future<void> _removePIN() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await SecurePrefs.instance.remove('${AppConstants.prefAppPinHash}$uid');
    if (!mounted) return;
    context.pop();
  }

  String get _title {
    switch (_step) {
      case _PinStep.enterCurrent: return 'Enter Current PIN';
      case _PinStep.enterNew: return 'Enter New PIN';
      case _PinStep.confirmNew: return 'Confirm New PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: const Text('App PIN'),
        backgroundColor: colorSurface,
        actions: [
          if (_hasPIN)
            TextButton(
              onPressed: _removePIN,
              child: const Text('Remove PIN', style: TextStyle(color: colorError)),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 48),
          Text(_title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorTextPrimary)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => Container(
              width: 16, height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pinInput.length ? colorAccent : colorSurfaceVariant,
              ),
            )),
          ),
          const SizedBox(height: 16),
          if (_errorText != null)
            Text(_errorText!, style: const TextStyle(color: colorError, fontSize: 13)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              children: [
                for (final d in ['1','2','3','4','5','6','7','8','9'])
                  _PinKey(d, _onDigitTap),
                const SizedBox.shrink(),
                _PinKey('0', _onDigitTap),
                GestureDetector(
                  onTap: _onBackspace,
                  child: const Icon(Icons.backspace_outlined, color: colorTextPrimary, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String digit;
  final ValueChanged<String> onTap;
  const _PinKey(this.digit, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(digit),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: colorSurface, borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(digit, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorTextPrimary))),
      ),
    );
  }
}
