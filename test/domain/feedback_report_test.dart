import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/feedback_report.dart';
import 'package:qorgan_app/domain/inspect_message.dart';

StoredMessage record(
  String sender,
  String body, {
  MessageFeedback feedback = MessageFeedback.none,
}) => StoredMessage(
  message: IncomingSms(sender: sender, body: body, timestamp: 1762500000000),
  verdict: inspectMessage(body, sender: sender),
  feedback: feedback,
);

void main() {
  test('only messages the user marked are included', () {
    final report = buildFeedbackReport([
      record('KASPI', 'Kaspi.kz: код 8123 для входа'),
      record(
        'HALYK',
        'Halyk: срочно подтвердите код',
        feedback: MessageFeedback.wrong,
      ),
    ]);

    expect(report, contains('Halyk: срочно подтвердите код'));
    expect(report, isNot(contains('код 8123')));
  });

  test('each entry carries the verdict the rule produced', () {
    final marked = record(
      '+7 701 222 33 44',
      'Вам перевод 150 000 тг, получите на halyk-bonus.ru',
      feedback: MessageFeedback.fraud,
    );

    final report = buildFeedbackReport([marked]);

    expect(report, contains('score ${marked.verdict.score}'));
    expect(report, contains('warn'));
    expect(report, contains('unofficialLink'));
    expect(report, contains('+7 701 222 33 44'));
  });

  test('the two kinds of correction are told apart', () {
    final report = buildFeedbackReport([
      record('A', 'ложная тревога тут', feedback: MessageFeedback.wrong),
      record('B', 'настоящий развод тут', feedback: MessageFeedback.fraud),
    ]);

    expect(report, contains('не мошенничество'));
    expect(report, contains('мошенничество'));
  });

  test('nothing marked produces an empty report, not a header alone', () {
    expect(buildFeedbackReport([record('KASPI', 'обычное')]), isEmpty);
    expect(buildFeedbackReport(const []), isEmpty);
  });

  test('the report says what it contains before anyone sends it', () {
    final report = buildFeedbackReport([
      record('A', 'что-то', feedback: MessageFeedback.wrong),
    ]);

    // The user is about to hand this to someone. It has to state plainly that
    // the message text is inside.
    expect(report.toLowerCase(), contains('текст'));
  });
}
