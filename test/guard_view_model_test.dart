import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/incoming_message_service.dart';
import 'package:qorgan_app/data/services/protection_settings.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/ui/core/copy.dart';
import 'package:qorgan_app/ui/guard/view_models/guard_view_model.dart';

void main() {
  test(
    'an incoming SMS during history refresh is not lost from the dashboard',
    () async {
      final service = UpdatingHistory();
      final vm = GuardViewModel(
        repository: ProtectionRepository(),
        incomingMessages: service,
        sample: AppCopy.phishingText,
      );
      final refresh = vm.refresh();
      await service.started.future;
      service.receive();
      service.snapshot.complete([]);
      await refresh;
      expect(vm.checkedCount, 1);
      vm.dispose();
    },
  );
  test('protection starts disabled until the user enables it', () {
    expect(ProtectionRepository().armed, isFalse);
  });
  test('denied SMS access does not enable protection', () async {
    final vm = GuardViewModel(
      repository: ProtectionRepository(),
      incomingMessages: UnboundIncomingMessageService(),
      sample: AppCopy.phishingText,
    );
    await vm.toggle();
    expect(vm.armed, isFalse);
    vm.dispose();
  });
  test(
    'enabled protection survives a new repository and turns off persistently',
    () async {
      final settings = MemoryProtectionSettings();
      final vm = GuardViewModel(
        repository: ProtectionRepository(settings: settings),
        incomingMessages: ReadyService(),
        sample: AppCopy.phishingText,
      );
      await vm.toggle();
      expect(vm.active, isTrue);
      final restored = ProtectionRepository(settings: settings);
      await restored.initialize();
      expect(restored.armed, isTrue);
      await vm.toggle();
      await restored.initialize();
      expect(restored.armed, isFalse);
      vm.dispose();
    },
  );
  test(
    'failed persistence does not claim protection has been enabled',
    () async {
      final vm = GuardViewModel(
        repository: ProtectionRepository(settings: FailedSettings()),
        incomingMessages: ReadyService(),
        sample: AppCopy.phishingText,
      );
      await vm.toggle();
      expect(vm.active, isFalse);
      expect(vm.error, isNotNull);
      vm.dispose();
    },
  );
  test(
    'revoked notification access removes the active status on resume',
    () async {
      final service = ReadyService();
      final vm = GuardViewModel(
        repository: ProtectionRepository(),
        incomingMessages: service,
        sample: AppCopy.phishingText,
      );
      await vm.toggle();
      service.allowed = false;
      await vm.refresh();
      expect(vm.armed, isTrue);
      expect(vm.active, isFalse);
      vm.dispose();
    },
  );
}

class UpdatingHistory extends UnboundIncomingMessageService {
  final started = Completer<void>();
  final snapshot = Completer<List<StoredMessage>>();
  List<StoredMessage> records = [];
  void Function(String)? callback;
  int calls = 0;
  @override
  void listen(void Function(String) onMessage) => callback = onMessage;
  @override
  Future<List<StoredMessage>> recent() {
    if (calls++ == 0) {
      started.complete();
      return snapshot.future;
    }
    return Future.value(records);
  }

  void receive() {
    const sms = IncomingSms(
      sender: 'KASPI',
      body: AppCopy.phishingText,
      timestamp: 1,
    );
    records = [StoredMessage(message: sms, verdict: inspectMessage(sms.body))];
    callback?.call(sms.body);
  }
}

class ReadyService extends UnboundIncomingMessageService {
  bool allowed = true;
  @override
  Future<ProtectionAccess> status() async =>
      ProtectionAccess(supported: true, sms: true, notifications: allowed);
}

class FailedSettings extends MemoryProtectionSettings {
  @override
  Future<void> writeArmed(bool value) async => throw StateError('write failed');
}
