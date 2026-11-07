import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';

MessageVerdict scored(int score) =>
    MessageVerdict(score: score, signals: const []);

void main() {
  test('risk rises with the score at the documented thresholds', () {
    expect(scored(0).risk, MessageRisk.clear);
    expect(scored(2).risk, MessageRisk.clear);
    expect(scored(3).risk, MessageRisk.watch);
    expect(scored(4).risk, MessageRisk.warn);
    expect(scored(11).risk, MessageRisk.warn);
  });

  test('only the warn state notifies', () {
    expect(scored(3).block, isFalse);
    expect(scored(4).block, isTrue);
  });
}
