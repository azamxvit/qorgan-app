import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/blocklist_store.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';

class FakeBlocklist implements Blocklist {
  FakeBlocklist(this.blocked);
  final Set<String> blocked;
  final asked = <String>[];

  @override
  Future<Set<String>> blockedAmong(Iterable<String> hosts) async {
    asked.addAll(hosts);
    return hosts.where(blocked.contains).toSet();
  }
}

class BrokenBlocklist implements Blocklist {
  @override
  Future<Set<String>> blockedAmong(Iterable<String> hosts) async =>
      throw StateError('database unavailable');
}

void main() {
  test('a pasted message is checked against the blocklist', () async {
    final blocklist = FakeBlocklist({'kaspi-bonus.top'});
    final repository = ProtectionRepository(blocklist: blocklist);

    final verdict = await repository.inspect('Смотри фото: kaspi-bonus.top/a');

    expect(verdict.signals, contains(MessageSignal.blockedHost));
    expect(verdict.risk, MessageRisk.warn);
    expect(blocklist.asked, ['kaspi-bonus.top']);
  });

  test('a pasted message can be judged by a sender the user typed', () async {
    final repository = ProtectionRepository(blocklist: FakeBlocklist(const {}));

    final verdict = await repository.inspect(
      'Halyk Bank: по вашей карте замечена операция. Перезвоните нам.',
      sender: '+7 701 123 45 67',
    );

    expect(verdict.signals, contains(MessageSignal.impersonation));
  });

  test('without a sender the message is judged on its text alone', () async {
    final repository = ProtectionRepository(blocklist: FakeBlocklist(const {}));

    final verdict = await repository.inspect(
      'Halyk Bank: по вашей карте замечена операция. Перезвоните нам.',
    );

    expect(verdict.signals, isNot(contains(MessageSignal.impersonation)));
  });

  test('a bank host is not flagged even if the blocklist names it', () async {
    final repository = ProtectionRepository(
      blocklist: FakeBlocklist({'kaspi.kz'}),
    );

    final verdict = await repository.inspect(
      'Kaspi.kz: Поступление 20 000 ₸. https://kaspi.kz/receipt',
    );

    expect(verdict.signals, isNot(contains(MessageSignal.blockedHost)));
    expect(verdict.block, isFalse);
  });

  test(
    'a blocklist failure still produces a verdict from the word rule',
    () async {
      final repository = ProtectionRepository(blocklist: BrokenBlocklist());

      final verdict = await repository.inspect(
        'KASPI: Счёт заблокируют через 15 минут. Срочно подтвердите код: '
        'http://kaspi-secure.xyz/login',
      );

      // Failing shut would leave the user with no answer at all.
      expect(verdict.risk, MessageRisk.warn);
      expect(verdict.signals, isNot(contains(MessageSignal.blockedHost)));
    },
  );

  test('the default repository checks text without a blocklist', () async {
    final verdict = await ProtectionRepository().inspect('обычное сообщение');

    expect(verdict.signals, isEmpty);
  });
}
