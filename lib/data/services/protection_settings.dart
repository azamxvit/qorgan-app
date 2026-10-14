import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ProtectionSettings {
  Future<bool> readArmed();
  Future<void> writeArmed(bool value);
}

class DeviceProtectionSettings implements ProtectionSettings {
  final _preferences = SharedPreferencesAsync();
  static const _key = 'qorgan.protection.armed';
  @override
  Future<bool> readArmed() async => await _preferences.getBool(_key) ?? false;
  @override
  Future<void> writeArmed(bool value) => _preferences.setBool(_key, value);
}

class MemoryProtectionSettings implements ProtectionSettings {
  MemoryProtectionSettings({this.armed = false});
  bool armed;
  @override
  Future<bool> readArmed() async => armed;
  @override
  Future<void> writeArmed(bool value) async {
    armed = value;
  }
}
