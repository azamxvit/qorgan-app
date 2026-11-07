import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ProtectionSettings {
  Future<bool> readArmed();
  Future<void> writeArmed(bool value);
  Future<bool> hasSavedSetting();
}

class DeviceProtectionSettings implements ProtectionSettings {
  final _preferences = SharedPreferencesAsync();
  static const _key = 'qorgan.protection.armed';
  @override
  Future<bool> readArmed() async => await _preferences.getBool(_key) ?? false;
  @override
  Future<void> writeArmed(bool value) => _preferences.setBool(_key, value);
  @override
  Future<bool> hasSavedSetting() => _preferences.containsKey(_key);
}

class MemoryProtectionSettings implements ProtectionSettings {
  MemoryProtectionSettings({bool? armed})
    : armed = armed ?? false,
      _saved = armed != null;
  bool armed;
  bool _saved;
  @override
  Future<bool> readArmed() async => armed;
  @override
  Future<void> writeArmed(bool value) async {
    armed = value;
    _saved = true;
  }

  @override
  Future<bool> hasSavedSetting() async => _saved;
}
