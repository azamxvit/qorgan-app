import 'message_store.dart';
import 'protection_settings.dart';
import '../../domain/inspect_message.dart';

abstract interface class WarningNotifier {
  Future<void> show(StoredMessage record);
}

class IncomingMessageProcessor {
  IncomingMessageProcessor({
    required this.settings,
    required this.store,
    required this.notifier,
  });
  final ProtectionSettings settings;
  final MessageStore store;
  final WarningNotifier notifier;
  Future<StoredMessage?> process(IncomingSms message) async {
    if (message.body.trim().isEmpty) return null;
    // A settings failure must not accidentally enable monitoring.
    try {
      if (!await settings.readArmed()) return null;
    } catch (_) {
      return null;
    }
    var record = StoredMessage(
      message: message,
      verdict: inspectMessage(message.body),
    );
    try {
      record = await store.save(record);
    } catch (_) {
      /* Still warn if storage is unavailable. */
    }
    if (record.verdict.block && !record.notified) {
      try {
        await notifier.show(record);
        await store.markNotified(record.key);
      } catch (_) {
        /* A later redelivery may retry; never log SMS contents. */
      }
    }
    return record;
  }
}
