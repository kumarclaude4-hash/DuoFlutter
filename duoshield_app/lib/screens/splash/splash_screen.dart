import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../db/app_database.dart';
import '../../security/app_lock_manager.dart';
import '../../security/secure_prefs.dart';
import '../../core/constants.dart';
import '../../widgets/matrix_rain_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final wipe = await SecurePrefs.instance.get(AppConstants.prefDuressWipeInProgress);
    if (wipe == 'true') {
      await SecurePrefs.instance.remove(AppConstants.prefDuressWipeInProgress);
    }

    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2000)),
      AppLockManager.instance.loadBackgroundTs(),
    ]);

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/sign-in');
    } else {
      try {
        await AppDatabase.instance.init(user.uid);
      } catch (e) {
        // DB already initialised (on hot restart) — ignore
      }
      if (AppLockManager.instance.shouldLock()) {
        context.go('/lock');
      } else {
        context.go('/conversations');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          const MatrixRainView(
            color: colorAccent,
            opacity: 0.4,
            speedMs: 60,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.shield, color: colorAccent, size: 64),
                ),
                const SizedBox(height: 24),
                const Text(
                  'DuoShield',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorAccent,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Encrypted Messaging',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorTextSecondary,
                    fontFamily: 'Inter',
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
