import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/ui/messages/message_presentation.dart';

StoredMessage record(String sender, String body) => StoredMessage(
  message: IncomingSms(sender: sender, body: body, timestamp: 1),
  verdict: inspectMessage(body, sender: sender),
);

void main() {
  test('the sender is shown as the network reported it', () {
    expect(senderName(record('BCC', 'Поступление 1000')), 'BCC');
    expect(senderName(record('KASPI', 'Поступление 1000')), 'KASPI');
    expect(
      senderName(record('  ', 'Поступление 1000')),
      'Неизвестный отправитель',
    );
  });

  test('a suspicious message never gets a reassuring title', () {
    final phishing = record(
      '+7 701 222 33 44',
      'Вам поступление 150 000 тг, получите на halyk-bonus.ru',
    );

    expect(phishing.verdict.block, isTrue);
    expect(messageTitle(phishing), isNot('Поступление на счёт'));
  });
}
