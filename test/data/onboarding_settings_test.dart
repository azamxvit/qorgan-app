import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/onboarding_settings.dart';
import 'package:qorgan_app/data/services/protection_settings.dart';
// Test the device adapters against the preference plugin's platform contract.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test(
    'device onboarding survives a new instance independently of protection',
    () async {
      final original = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = original);
      final onboarding = DeviceOnboardingSettings();
      final protection = DeviceProtectionSettings();
      expect(await onboarding.readCompleted(), isFalse);
      expect(await protection.hasSavedSetting(), isFalse);
      await protection.writeArmed(false);
      expect(await DeviceProtectionSettings().hasSavedSetting(), isTrue);
      expect(await onboarding.readCompleted(), isFalse);
      await onboarding.writeCompleted();
      expect(await DeviceOnboardingSettings().readCompleted(), isTrue);
      expect(await protection.readArmed(), isFalse);
    },
  );

  test('completing onboarding does not enable protection', () async {
    final onboarding = MemoryOnboardingSettings();
    final protection = MemoryProtectionSettings();
    expect(await onboarding.readCompleted(), isFalse);
    await onboarding.writeCompleted();
    expect(await onboarding.readCompleted(), isTrue);
    expect(await protection.readArmed(), isFalse);
    expect(await protection.hasSavedSetting(), isFalse);
  });

  test(
    'migration distinguishes a saved disabled setting from a new install',
    () async {
      final fresh = ProtectionRepository();
      expect(await fresh.hasSavedProtectionSetting(), isFalse);
      await fresh.setArmed(false);
      expect(await fresh.hasSavedProtectionSetting(), isTrue);
      expect(fresh.armed, isFalse);
      final disabled = ProtectionRepository(
        settings: MemoryProtectionSettings(armed: false),
      );
      expect(await disabled.hasSavedProtectionSetting(), isTrue);
    },
  );
}
