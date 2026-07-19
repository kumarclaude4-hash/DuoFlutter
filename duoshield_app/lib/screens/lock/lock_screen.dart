import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../crypto/pin_hasher.dart';
import '../../security/app_lock_manager.dart';
import '../../security/duress_manager.dart';
import '../../security/secure_prefs.dart';
import '../../widgets/ds_button.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pinInput = '';
  String? _errorText;
  int _failedAttempts = 0;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.lockScreenActive = true;
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    _biometricEnabled = await SecurePrefs.instance.getBool(AppConstants.prefBiometricEnabled);
    if (_biometricEnabled && mounted) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      if (!canAuth) return;
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock DuoShield',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated && mounted) _unlock();
    } catch (_) {}
  }

  void _onDigitTap(String digit) {
    if (_pinInput.length >= 4) return;
    setState(() => _pinInput += digit);
    if (_pinInput.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_pinInput.isEmpty) return;
    setState(() => _pinInput = _pinInput.substring(0, _pinInput.length - 1));
  }

  Future<void> _verifyPin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final storedHash = await SecurePrefs.instance.get('${AppConstants.prefAppPinHash}$uid');
    if (storedHash == null) {
      _unlock();
      return;
    }

    final isCorrect = PinHasher.verifyPin(_pinInput, storedHash);
    if (isCorrect) {
      final duressHash = await SecurePrefs.instance.get('${AppConstants.prefDuressPinHash}$uid');
      if (duressHash != null && PinHasher.verifyPin(_pinInput, duressHash)) {
        await DuressManager.performWipe();
        if (!mounted) return;
        context.go('/sign-in');
        return;
      }
      _unlock();
    } else {
      _failedAttempts++;
      setState(() {
        _errorText = 'Incorrect PIN';
        _pinInput = '';
      });
      if (_failedAttempts >= 5) {
        _confirmSignOut();
      }
    }
  }

  void _unlock() {
    AppLockManager.instance.lockScreenActive = false;
    AppLockManager.instance.clearBackgroundTs();
    if (mounted) Navigator.of(context).pop();
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorSurface,
        title: const Text('Sign Out', style: TextStyle(color: colorTextPrimary)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: colorTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: colorTextSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              context.go('/sign-in');
            },
            child: const Text('Sign Out', style: TextStyle(color: colorError)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield, color: colorAccent, size: 40),
              ),
              const SizedBox(height: 24),
              const Text('DuoShield',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorTextPrimary)),
              const SizedBox(height: 8),
              const Text('Enter your PIN',
                  style: TextStyle(fontSize: 14, color: colorTextSecondary)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pinInput.length ? colorAccent : colorSurfaceVariant,
                  ),
                )),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.6,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  children: [
                    for (final digit in ['1','2','3','4','5','6','7','8','9'])
                      _PinKey(digit, _onDigitTap),
                    if (_biometricEnabled)
                      GestureDetector(
                        onTap: _tryBiometric,
                        child: const Icon(Icons.fingerprint, color: colorAccent, size: 32),
                      )
                    else
                      const SizedBox.shrink(),
                    _PinKey('0', _onDigitTap),
                    GestureDetector(
                      onTap: _onBackspace,
                      child: const Icon(Icons.backspace_outlined, color: colorTextPrimary, size: 24),
                    ),
                  ],
                ),
              ),
              if (_errorText != null)
                Text(_errorText!, style: const TextStyle(color: colorError, fontSize: 13)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _confirmSignOut,
                child: const Text('Sign out', style: TextStyle(color: colorTextMuted)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
        decoration: BoxDecoration(
          color: colorSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(digit,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorTextPrimary)),
        ),
      ),
    );
  }
}
