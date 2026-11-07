import '../../domain/inspect_message.dart';
import '../../domain/models/message_verdict.dart';
import '../../domain/signals/link_signals.dart';
import '../services/blocklist_store.dart';
import '../services/protection_settings.dart';

/// Source of truth for the on-device SMS rule and the background switch.
class ProtectionRepository {
  ProtectionRepository({ProtectionSettings? settings, Blocklist? blocklist})
    : _settings = settings ?? MemoryProtectionSettings(),
      _blocklist = blocklist ?? const EmptyBlocklist();
  final ProtectionSettings _settings;
  final Blocklist _blocklist;
  var _armed = false;

  bool get armed => _armed;
  Future<bool> hasSavedProtectionSetting() => _settings.hasSavedSetting();

  Future<void> initialize() async => _armed = await _settings.readArmed();
  Future<void> setArmed(bool value) async {
    await _settings.writeArmed(value);
    _armed = value;
  }

  /// Checks a message the user pasted by hand, through the same rule, the
  /// same blocklist and the same sender logic as an SMS that arrived on its
  /// own. A manual check used to see only the word lists, which made the
  /// answer weaker than for the identical message received by SMS.
  ///
  /// Asynchronous because the blocklist lives in a database. The synchronous
  /// version was removed rather than kept alongside: leaving it would let a
  /// caller quietly go back to the weaker check.
  ///
  /// [sender] is what the user typed, when they typed anything. An empty
  /// sender simply leaves the sender signals unused.
  // NEEDS (UI): a sender field on the manual check screen so this argument can
  // be filled. Without it `impersonation` can never fire for a pasted message.
  Future<MessageVerdict> inspect(String text, {String sender = ''}) async {
    var blocked = const <String>{};
    try {
      blocked = await _blocklist.blockedAmong(linkedHosts(text.toLowerCase()));
    } catch (_) {
      // Failing shut would leave the user with no answer at all; the word
      // rule alone is still worth more than an error message.
    }
    return inspectMessage(text, sender: sender, blockedHosts: blocked);
  }
}
