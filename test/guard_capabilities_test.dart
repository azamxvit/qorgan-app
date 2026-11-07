import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/incoming_message_service.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/data/services/protection_settings.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/ui/guard/view_models/guard_view_model.dart';

void main() {
  test('history read failure leaves confirmed protection active', () async {
    final service = CapabilityService()..failHistory = true;
    final vm = GuardViewModel(
      repository: ProtectionRepository(
        settings: MemoryProtectionSettings(armed: true),
      ),
      incomingMessages: service,
    );
    addTearDown(vm.dispose);
    await vm.refresh();
    expect(vm.active, isTrue);
    expect(vm.access.ready, isTrue);
    expect(vm.loaded, isTrue);
    expect(vm.historyError, isNotNull);
    expect(vm.statusError, isNull);
    service.failHistory = false;
    await vm.refresh();
    expect(vm.error, isNull);
  });

  test('old active status is not presented during a new status read', () async {
    final service = CapabilityService();
    final vm = GuardViewModel(
      repository: ProtectionRepository(
        settings: MemoryProtectionSettings(armed: true),
      ),
      incomingMessages: service,
    );
    addTearDown(vm.dispose);
    await vm.refresh();
    expect(vm.active, isTrue);
    service.pendingStatus = Completer<ProtectionAccess>();
    final refresh = vm.refresh();
    expect(vm.active, isFalse);
    service.pendingStatus!.complete(service.access);
    await refresh;
    expect(vm.active, isTrue);
  });

  test(
    'failed status keeps readable history and recovers independently',
    () async {
      final service = CapabilityService()
        ..records = [record(1)]
        ..failStatus = true;
      final vm = GuardViewModel(
        repository: ProtectionRepository(
          settings: MemoryProtectionSettings(armed: true),
        ),
        incomingMessages: service,
      );
      addTearDown(vm.dispose);
      expect(vm.loaded, isFalse);
      expect(vm.active, isFalse);
      await vm.refresh();
      expect(vm.loaded, isTrue);
      expect(vm.active, isFalse);
      expect(vm.statusError, isNotNull);
      expect(vm.historyError, isNull);
      expect(vm.checkedCount, 1);
      service.failStatus = false;
      await vm.refresh();
      expect(vm.active, isTrue);
      expect(vm.error, isNull);
    },
  );

  test('each permission step requests only its explicit capability', () async {
    final service = CapabilityService()
      ..access = const ProtectionAccess(supported: true);
    final vm = GuardViewModel(
      repository: ProtectionRepository(),
      incomingMessages: service,
    );
    addTearDown(vm.dispose);
    await vm.requestSmsAccess();
    expect(service.requests, ['sms']);
    expect(vm.armed, isFalse);
    expect(vm.error, isNotNull);
    await vm.requestNotificationAccess();
    expect(service.requests, ['sms', 'notifications']);
    expect(vm.armed, isFalse);
    expect(vm.error, isNotNull);
    service.access = const ProtectionAccess(
      supported: true,
      sms: true,
      notifications: true,
    );
    await vm.requestNotificationAccess();
    expect(vm.error, isNull);
  });

  test(
    'enable verifies capabilities without requesting any permission',
    () async {
      final service = CapabilityService()
        ..access = const ProtectionAccess(supported: true, sms: true);
      final vm = GuardViewModel(
        repository: ProtectionRepository(),
        incomingMessages: service,
      );
      addTearDown(vm.dispose);
      expect(await vm.enable(), isFalse);
      expect(vm.armed, isFalse);
      expect(service.requests, isEmpty);
      expect(vm.error, isNotNull);
      service.access = const ProtectionAccess(
        supported: true,
        sms: true,
        notifications: true,
      );
      expect(await vm.enable(), isTrue);
      expect(vm.active, isTrue);
      expect(vm.error, isNull);
      expect(service.requests, isEmpty);
      expect(await vm.disable(), isTrue);
      expect(vm.armed, isFalse);
    },
  );

  test(
    'failed enabling persistence preserves disabled intent then recovers',
    () async {
      final settings = FailingWriteSettings();
      final service = CapabilityService();
      final vm = GuardViewModel(
        repository: ProtectionRepository(settings: settings),
        incomingMessages: service,
      );
      addTearDown(vm.dispose);
      expect(await vm.enable(), isFalse);
      expect(vm.active, isFalse);
      expect(vm.armed, isFalse);
      expect(vm.error, isNotNull);
      settings.failWrite = false;
      expect(await vm.enable(), isTrue);
      expect(vm.error, isNull);
      expect(service.requests, isEmpty);
    },
  );

  test('failed disabling persistence preserves the armed setting', () async {
    final settings = FailingWriteSettings(armed: true);
    final vm = GuardViewModel(
      repository: ProtectionRepository(settings: settings),
      incomingMessages: CapabilityService(),
    );
    addTearDown(vm.dispose);
    await vm.refresh();
    expect(await vm.disable(), isFalse);
    expect(vm.armed, isTrue);
    expect(vm.error, isNotNull);
  });

  test('clear refreshes a message received during deletion without changing protection', () async {
    final service = CapabilityService()..records = [record(1)];
    final vm = GuardViewModel(
      repository: ProtectionRepository(
        settings: MemoryProtectionSettings(armed: true),
      ),
      incomingMessages: service,
    );
    addTearDown(vm.dispose);
    await vm.refresh();
    final clearStarted = Completer<void>();
    service.clearStarted = clearStarted;
    service.clearFinished = Completer<void>();
    final clearing = vm.clearHistory();
    await clearStarted.future;
    service.records.add(record(2));
    service.listener?.call(record(2).message.body);
    service.clearFinished!.complete();
    expect(await clearing, isTrue);
    expect(vm.messages.map((r) => r.message.timestamp), [2]);
    expect(vm.armed, isTrue);
    expect(vm.active, isTrue);
    expect(await vm.clearHistory(), isTrue);
    expect(vm.received, isFalse);
    expect(vm.message, isNull);
  });
}

StoredMessage record(int timestamp) {
  final sms = IncomingSms(
    sender: 'Bank',
    body: 'Сообщение $timestamp',
    timestamp: timestamp,
  );
  return StoredMessage(message: sms, verdict: inspectMessage(sms.body));
}

class CapabilityService extends UnboundIncomingMessageService {
  ProtectionAccess access = const ProtectionAccess(
    supported: true,
    sms: true,
    notifications: true,
  );
  bool failHistory = false;
  bool failStatus = false;
  Completer<ProtectionAccess>? pendingStatus;
  List<StoredMessage> records = [];
  final requests = <String>[];
  void Function(String)? listener;
  Completer<void>? clearStarted;
  Completer<void>? clearFinished;

  @override
  void listen(void Function(String) onMessage) => listener = onMessage;

  @override
  Future<ProtectionAccess> requestSmsAccess() async {
    requests.add('sms');
    return access;
  }

  @override
  Future<ProtectionAccess> requestNotificationAccess() async {
    requests.add('notifications');
    return access;
  }

  @override
  Future<void> clearHistory() async {
    final keys = records.map((record) => record.key).toSet();
    if (clearStarted != null) {
      clearStarted!.complete();
      clearStarted = null;
      await clearFinished!.future;
    }
    records.removeWhere((record) => keys.contains(record.key));
  }

  @override
  Future<ProtectionAccess> status() async {
    if (failStatus) throw StateError('Status unavailable');
    return pendingStatus == null ? access : pendingStatus!.future;
  }

  @override
  Future<List<StoredMessage>> recent() async {
    if (failHistory) throw StateError('History unavailable');
    return records;
  }
}

class FailingWriteSettings extends MemoryProtectionSettings {
  FailingWriteSettings({super.armed});
  bool failWrite = true;
  @override
  Future<void> writeArmed(bool value) async {
    if (failWrite) throw StateError('Write failed');
    await super.writeArmed(value);
  }
}
