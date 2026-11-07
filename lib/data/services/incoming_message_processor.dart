import 'blocklist_store.dart';
import 'message_store.dart';
import 'protection_settings.dart';
import '../../domain/inspect_message.dart';
import '../../domain/signals/link_signals.dart';

abstract interface class WarningNotifier {
  Future<void> show(StoredMessage record);
}

abstract interface class RemovableWarningNotifier implements WarningNotifier {
  Future<void> cancelFor(Iterable<StoredMessage> records);
}

class IncomingMessageProcessor {
  IncomingMessageProcessor({
    required this.settings,
    required this.store,
    required this.notifier,
    this.blocklist = const EmptyBlocklist(),
  });
  final ProtectionSettings settings;
  final MessageStore store;
  final WarningNotifier notifier;
  final Blocklist blocklist;
  Future<StoredMessage?> process(IncomingSms message) async {
    if (message.body.trim().isEmpty) return null;
    // A settings failure must not accidentally enable monitoring.
    try {
      if (!await settings.readArmed()) return null;
    } catch (_) {
      return null;
    }
    // Only the hosts this message names are looked up — never its text, and
    // one query rather than one per host: the receiver has nine seconds total.
    // The rule lowercases before matching, so the hosts must be lowercased too.
    var blocked = const <String>{};
    try {
      blocked = await blocklist.blockedAmong(
        linkedHosts(message.body.toLowerCase()),
      );
    } catch (_) {
      /* A blocklist failure must not stop the word-based rule. */
    }
    var record = StoredMessage(
      message: message,
      verdict: inspectMessage(
        message.body,
        sender: message.sender,
        blockedHosts: blocked,
      ),
    );
    var saved = false;
    try {
      record = await store.save(record);
      saved = true;
    } catch (_) {
      /* Still warn if storage is unavailable. */
    }
    if (record.verdict.block && !record.notified) {
      try {
        await notifier.show(record);
        final lookup = store;
        final removable = notifier;
        if (saved &&
            lookup is StoredMessageLookup &&
            removable is RemovableWarningNotifier &&
            await lookup.byKey(record.key) == null) {
          // Clear may finish while Android is posting. Withdraw the late
          // warning only when storage had actually accepted this record.
          await removable.cancelFor([record]);
        } else {
          await store.markNotified(record.key);
        }
      } catch (_) {
        /* A later redelivery may retry; never log SMS contents. */
      }
    }
    return record;
  }
}
