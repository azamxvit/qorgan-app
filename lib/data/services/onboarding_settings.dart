import 'package:shared_preferences/shared_preferences.dart';

/// Whether the person has been through the welcome screen.
///
/// Deliberately separate from [ProtectionSettings]: seeing the introduction is
/// not consent to monitor SMS. Finishing onboarding must never arm protection
/// — that only happens after the permissions are granted and the choice is
/// saved. `test/data/onboarding_settings_test.dart` holds that line.
abstract interface class OnboardingSettings {
  Future<bool> readCompleted();
  Future<void> writeCompleted();
}

class DeviceOnboardingSettings implements OnboardingSettings {
  final _preferences = SharedPreferencesAsync();
  static const _key = 'qorgan.onboarding.completed';

  @override
  Future<bool> readCompleted() async =>
      await _preferences.getBool(_key) ?? false;

  @override
  Future<void> writeCompleted() => _preferences.setBool(_key, true);
}

class MemoryOnboardingSettings implements OnboardingSettings {
  MemoryOnboardingSettings({this.completed = false});

  bool completed;

  @override
  Future<bool> readCompleted() async => completed;

  @override
  Future<void> writeCompleted() async => completed = true;
}
