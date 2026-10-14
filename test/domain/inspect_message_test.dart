import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';
import 'package:qorgan_app/ui/core/copy.dart';

void main() {
  test('blocks urgency, pressure, a code request and a foreign link', () {
    final verdict = inspectMessage(AppCopy.phishingText);

    expect(verdict.block, isTrue);
    expect(verdict.signals, contains(MessageSignal.unofficialLink));
    expect(verdict.signals, contains(MessageSignal.secret));
  });

  test('lets an ordinary bank notice through', () {
    final verdict = inspectMessage(AppCopy.ordinaryText);

    expect(verdict.block, isFalse);
    expect(verdict.signals, [MessageSignal.bank]);
  });

  test('treats an official bank host as a safe link', () {
    final verdict = inspectMessage('Поступление: https://halykbank.kz/receipt');

    expect(verdict.signals, isNot(contains(MessageSignal.unofficialLink)));
  });
}
