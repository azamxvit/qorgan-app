import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/incoming_message_processor.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/data/services/protection_settings.dart';
import 'package:qorgan_app/ui/core/copy.dart';

void main() {
  late MemoryProtectionSettings settings;
  late FakeStore store;
  late FakeNotifier notifier;
  late IncomingMessageProcessor processor;
  const phishing = IncomingSms(
    sender: 'KASPI',
    body: AppCopy.phishingText,
    timestamp: 1234,
  );

  setUp(() {
    settings = MemoryProtectionSettings(armed: true);
    store = FakeStore();
    notifier = FakeNotifier();
    processor = IncomingMessageProcessor(
      settings: settings,
      store: store,
      notifier: notifier,
    );
  });

  test('incoming phishing is scored by Qorgan and warns immediately', () async {
    final result = await processor.process(phishing);
    expect(result?.verdict.score, 11);
    expect(notifier.warnings.single.message.body, AppCopy.phishingText);
    expect((await store.latest())?.notified, isTrue);
  });
  test('ordinary bank notice is saved without warning', () async {
    final result = await processor.process(
      const IncomingSms(
        sender: 'Halyk',
        body: AppCopy.ordinaryText,
        timestamp: 10,
      ),
    );
    expect(result?.verdict.score, 1);
    expect(notifier.warnings, isEmpty);
    expect(await store.latest(), isNotNull);
  });
  test('disabled protection ignores incoming SMS', () async {
    await settings.writeArmed(false);
    expect(await processor.process(phishing), isNull);
    expect(notifier.warnings, isEmpty);
    expect(await store.latest(), isNull);
  });
  test('empty body is ignored', () async {
    await processor.process(
      const IncomingSms(sender: 'x', body: '  ', timestamp: 1),
    );
    expect(await store.latest(), isNull);
  });
  test('redelivery of an already warned message does not warn again', () async {
    await processor.process(phishing);
    await processor.process(phishing);
    expect(notifier.warnings, hasLength(1));
  });
  test('failed notification is retried on redelivery', () async {
    notifier.fail = true;
    await processor.process(phishing);
    expect((await store.latest())?.notified, isFalse);
    notifier.fail = false;
    await processor.process(phishing);
    expect(notifier.warnings, hasLength(1));
  });
  test('storage failure does not suppress phishing warning', () async {
    store.fail = true;
    await processor.process(phishing);
    expect(notifier.warnings, hasLength(1));
  });
  test('notification ID stays the same after restarting processing', () async {
    await processor.process(phishing);
    final first = notifier.warnings.single.notificationId;
    store = FakeStore();
    await IncomingMessageProcessor(
      settings: settings,
      store: store,
      notifier: notifier,
    ).process(phishing);
    expect(notifier.warnings.last.notificationId, first);
  });
}

class FakeStore implements MessageStore {
  final records = <String, StoredMessage>{};
  bool fail = false;
  @override
  Future<StoredMessage> save(StoredMessage record) async {
    if (fail) throw StateError('storage unavailable');
    return records.putIfAbsent(record.key, () => record);
  }

  @override
  Future<void> markNotified(String key) async {
    records[key] = records[key]!.withNotified();
  }

  @override
  Future<StoredMessage?> latest() async => records.values.lastOrNull;
}

class FakeNotifier implements WarningNotifier {
  final warnings = <StoredMessage>[];
  bool fail = false;
  @override
  Future<void> show(StoredMessage record) async {
    if (fail) throw StateError('notifications unavailable');
    warnings.add(record);
  }
}
