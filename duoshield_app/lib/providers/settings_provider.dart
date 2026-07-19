import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/secure_prefs.dart';
import '../core/constants.dart';

class SettingsState {
  final bool biometricEnabled;
  final bool hasPIN;
  final bool readReceiptsEnabled;
  final bool showLastSeen;

  const SettingsState({
    this.biometricEnabled = false,
    this.hasPIN = false,
    this.readReceiptsEnabled = true,
    this.showLastSeen = true,
  });

  SettingsState copyWith({
    bool? biometricEnabled,
    bool? hasPIN,
    bool? readReceiptsEnabled,
    bool? showLastSeen,
  }) => SettingsState(
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    hasPIN: hasPIN ?? this.hasPIN,
    readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
    showLastSeen: showLastSeen ?? this.showLastSeen,
  );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final biometric = await SecurePrefs.instance.getBool(AppConstants.prefBiometricEnabled);
    state = state.copyWith(biometricEnabled: biometric);
  }

  Future<void> setBiometricEnabled(bool value) async {
    await SecurePrefs.instance.setBool(AppConstants.prefBiometricEnabled, value);
    state = state.copyWith(biometricEnabled: value);
  }

  void setHasPIN(bool value) {
    state = state.copyWith(hasPIN: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
    (ref) => SettingsNotifier());
