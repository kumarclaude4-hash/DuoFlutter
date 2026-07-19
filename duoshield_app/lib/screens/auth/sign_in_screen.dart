import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../security/secure_prefs.dart';
import '../../widgets/matrix_rain_view.dart';
import '../../widgets/ds_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  void initState() {
    super.initState();
    _checkInactivity();
  }

  Future<void> _checkInactivity() async {
    final reason = await SecurePrefs.instance.get(AppConstants.prefSignedOutReasonInactivity);
    if (reason == 'true' && mounted) {
      await SecurePrefs.instance.remove(AppConstants.prefSignedOutReasonInactivity);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You were signed out due to inactivity'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          Opacity(
            opacity: 0.3,
            child: const MatrixRainView(),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: colorSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.shield, color: colorAccent, size: 48),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'DuoShield',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Private. Secure. Yours.',
                          style: TextStyle(fontSize: 14, color: colorTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        DSButton(
                          text: 'Create New Account',
                          gradient: true,
                          height: 52,
                          onTap: () => context.push('/display-name'),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.push('/restore-from-seed'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: colorAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Restore from Seed Phrase',
                              style: TextStyle(color: colorAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'By continuing, you agree to our Terms of Service',
                          style: TextStyle(fontSize: 11, color: colorTextMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
