import 'message_store.dart';

/// SMS that arrive on the device.
///
/// Platform monitoring lives independently of the screen subscription.
abstract class IncomingMessageService {
  void Function()? onOpenMessage;
  Future<ProtectionAccess> status() async => const ProtectionAccess();
  Future<ProtectionAccess> requestSmsAccess() async => status();
  Future<ProtectionAccess> requestNotificationAccess() async => status();
  Future<ProtectionAccess> requestAccess() async {
    final access = await requestSmsAccess();
    if (!access.supported || !access.sms) return access;
    return access.notifications ? access : requestNotificationAccess();
  }

  bool get hasNotificationSelection => false;
  Future<StoredMessage?> latest() async => null;
  Future<StoredMessage?> openedMessage() async => null;
  Future<List<StoredMessage>> recent() async {
    final record = await latest();
    return record == null ? [] : [record];
  }

  Future<void> openSettings() async {}
  Future<void> clearHistory() async {}
  Future<void> recordFeedback(String key, MessageFeedback feedback) async =>
      throw UnsupportedError(
        'Message feedback is unavailable on this platform.',
      );
  void listen(void Function(String text) onMessage);
  void dispose();
}

class UnboundIncomingMessageService extends IncomingMessageService {
  @override
  void listen(void Function(String text) onMessage) {}

  @override
  void dispose() {}
}

class ProtectionAccess {
  const ProtectionAccess({
    this.supported = false,
    this.sms = false,
    this.notifications = false,
  });
  final bool supported;
  final bool sms;
  final bool notifications;
  bool get ready => supported && sms && notifications;
}
