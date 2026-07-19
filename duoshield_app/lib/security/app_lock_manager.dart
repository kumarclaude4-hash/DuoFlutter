import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import 'secure_prefs.dart';

class AppLockManager {
  static final AppLockManager _instance = AppLockManager._();
  static AppLockManager get instance => _instance;

  AppLockManager._();

  int _activeScreenCount = 0;
  int? _backgroundTs;
  bool lockScreenActive = false;

  void onScreenStarted() {
    _activeScreenCount++;
  }

  void onScreenStopped() {
    _activeScreenCount--;
    if (_activeScreenCount <= 0) {
      _activeScreenCount = 0;
    }
  }

  void onAppBackgrounded() {
    _backgroundTs = DateTime.now().millisecondsSinceEpoch;
    SecurePrefs.instance.set(AppConstants.prefBackgroundTs, _backgroundTs.toString());
  }

  void onAppResumed(GoRouter router) {
    if (lockScreenActive) return;
    if (_backgroundTs == null) return;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _backgroundTs!;
    if (elapsed > AppConstants.autoSignOutMs) {
      SecurePrefs.instance.set(AppConstants.prefSignedOutReasonInactivity, 'true');
      router.go('/sign-in');
    } else if (elapsed > AppConstants.lockDelayMs) {
      router.push('/lock');
    }
  }

  Future<void> loadBackgroundTs() async {
    final stored = await SecurePrefs.instance.get(AppConstants.prefBackgroundTs);
    if (stored != null) {
      _backgroundTs = int.tryParse(stored);
    }
  }

  bool shouldLock() {
    if (lockScreenActive) return false;
    if (_backgroundTs == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _backgroundTs!;
    return elapsed > AppConstants.lockDelayMs;
  }

  bool shouldAutoSignOut() {
    if (_backgroundTs == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _backgroundTs!;
    return elapsed > AppConstants.autoSignOutMs;
  }

  void clearBackgroundTs() {
    _backgroundTs = null;
    SecurePrefs.instance.remove(AppConstants.prefBackgroundTs);
  }
}
