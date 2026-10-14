import '../../domain/inspect_message.dart';
import '../../domain/models/message_verdict.dart';
import '../services/protection_settings.dart';

/// Source of truth for the on-device SMS rule and the background switch.
class ProtectionRepository {
  ProtectionRepository({ProtectionSettings? settings})
    : _settings = settings ?? MemoryProtectionSettings();
  final ProtectionSettings _settings;
  var _armed = false;

  bool get armed => _armed;

  Future<void> initialize() async => _armed = await _settings.readArmed();
  Future<void> setArmed(bool value) async {
    await _settings.writeArmed(value);
    _armed = value;
  }

  MessageVerdict inspect(String text) => inspectMessage(text);
}
