import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';

import 'sms_corpus.dart';

void main() {
  test('blocks urgency, pressure, a code request and a foreign link', () {
    final verdict = inspectMessage(corpusPhishingSample);

    expect(verdict.block, isTrue);
    expect(verdict.signals, contains(MessageSignal.unofficialLink));
    expect(verdict.signals, contains(MessageSignal.secret));
  });

  test('lets an ordinary bank notice through', () {
    final verdict = inspectMessage(corpusOrdinarySample);

    expect(verdict.block, isFalse);
    expect(verdict.signals, [MessageSignal.bank]);
  });

  test('treats an official bank host as a safe link', () {
    final verdict = inspectMessage('Поступление: https://halykbank.kz/receipt');

    expect(verdict.signals, isNot(contains(MessageSignal.unofficialLink)));
  });

  test('a delivered one-time code without a link is not a secret request', () {
    final verdict = inspectMessage(
      'Kaspi.kz: код 8123 для входа. Никому его не сообщайте.',
    );

    expect(verdict.signals, isNot(contains(MessageSignal.secret)));
    expect(verdict.block, isFalse);
  });

  test('detects a host written without a scheme', () {
    final verdict = inspectMessage(
      'Вам перевод 150 000 тг, получите на halyk-bonus.ru',
    );

    expect(verdict.signals, contains(MessageSignal.unofficialLink));
    expect(verdict.block, isTrue);
  });

  test('accepts a link to a bank that the word list already knows', () {
    final verdict = inspectMessage(
      'BCC: Поступление 50 000 KZT. Подробнее https://bcc.kz/app',
    );

    expect(verdict.signals, isNot(contains(MessageSignal.unofficialLink)));
    expect(verdict.block, isFalse);
  });

  const bankClaim =
      'Halyk Bank: по вашей карте замечена операция. Перезвоните нам.';

  test(
    'a bank message sent from an ordinary mobile number is impersonation',
    () {
      final verdict = inspectMessage(bankClaim, sender: '+7 701 123 45 67');

      expect(verdict.signals, contains(MessageSignal.impersonation));
      expect(verdict.block, isTrue);
    },
  );

  test('the same message from the bank sender name is not impersonation', () {
    final verdict = inspectMessage(bankClaim, sender: 'Halyk');

    expect(verdict.signals, isNot(contains(MessageSignal.impersonation)));
    expect(verdict.block, isFalse);
  });

  test('a pasted message carries no sender and is not judged by one', () {
    final verdict = inspectMessage(bankClaim);

    expect(verdict.signals, isNot(contains(MessageSignal.impersonation)));
    expect(verdict.block, isFalse);
  });

  test('detects a schemed link whose domain ending is unknown', () {
    final verdict = inspectMessage(
      'Kaspi: Подтвердите код: https://verify-card.example/login',
    );

    expect(verdict.signals, contains(MessageSignal.unofficialLink));
  });

  test('does not read an email address as a link', () {
    final verdict = inspectMessage('Напишите нам на support@qorgan-help.ru');

    expect(verdict.signals, isNot(contains(MessageSignal.unofficialLink)));
  });

  test('a host known for phishing warns on its own', () {
    final verdict = inspectMessage(
      'Посмотрите фото: kaspi-bonus.top/album',
      blockedHosts: const {'kaspi-bonus.top'},
    );

    expect(verdict.signals, contains(MessageSignal.blockedHost));
    expect(verdict.risk, MessageRisk.warn);
  });

  test('a bank host stays official even if the blocklist names it', () {
    // A swapped or poisoned list must not be able to flag a real bank: that
    // would turn the update channel itself into an attack.
    final verdict = inspectMessage(
      'Kaspi.kz: Поступление 20 000 ₸. https://kaspi.kz/receipt',
      blockedHosts: const {'kaspi.kz'},
    );

    expect(verdict.signals, isNot(contains(MessageSignal.blockedHost)));
    expect(verdict.signals, isNot(contains(MessageSignal.unofficialLink)));
    expect(verdict.block, isFalse);
  });
}
