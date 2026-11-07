import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';

import 'sms_corpus.dart';

/// The gate for the SMS rule. Precision is absolute on purpose: a warning on a
/// real bank SMS teaches the user to ignore Qorgan, while a missed message only
/// leaves them where they already were.
///
/// Adding a message that the rule gets wrong is supposed to turn this test red.
/// That is the point: fix the rule, do not lower the gate.
const minPrecision = 1.0;
const minRecall = 0.85;

void main() {
  test('warns about phishing without crying wolf on real bank traffic', () {
    var truePositives = 0;
    var falsePositives = 0;
    var falseNegatives = 0;
    final mistakes = <String>[];

    for (final sms in smsCorpus) {
      final verdict = inspectMessage(sms.body, sender: sms.sender);
      if (sms.phishing && verdict.block) {
        truePositives += 1;
      } else if (sms.phishing) {
        falseNegatives += 1;
        mistakes.add('пропущен фишинг (${verdict.score}): ${sms.body}');
      } else if (verdict.block) {
        falsePositives += 1;
        mistakes.add('ложная тревога (${verdict.score}): ${sms.body}');
      }
    }

    final precision = truePositives / (truePositives + falsePositives);
    final recall = truePositives / (truePositives + falseNegatives);
    // Printed on every run, not just on failure: these two numbers are the
    // only readable answer to "did the rule get better or worse?".
    // ignore: avoid_print
    print(
      'detector: precision ${precision.toStringAsFixed(2)} '
      '(порог $minPrecision), recall ${recall.toStringAsFixed(2)} '
      '(порог $minRecall) — ложных тревог $falsePositives из '
      '${legitimateSms.length}, пропущено $falseNegatives из '
      '${phishingSms.length}'
      '${mistakes.isEmpty ? '' : '\n  ${mistakes.join('\n  ')}'}',
    );

    expect(precision, greaterThanOrEqualTo(minPrecision));
    expect(recall, greaterThanOrEqualTo(minRecall));
  });

  test('never warns about a one-time code delivered by a bank', () {
    final codeMessages = legitimateSms.where(
      (sms) => RegExp(r'код|пароль').hasMatch(sms.body.toLowerCase()),
    );

    expect(codeMessages, isNotEmpty);
    for (final sms in codeMessages) {
      expect(
        inspectMessage(sms.body, sender: sms.sender).block,
        isFalse,
        reason: 'ложная тревога на коде: ${sms.body}',
      );
    }
  });

  test('the score always equals the weights the breakdown shows', () {
    for (final sms in smsCorpus) {
      final verdict = inspectMessage(sms.body, sender: sms.sender);
      final shown = verdict.signals.fold(
        0,
        (total, signal) => total + signalWeights[signal]!,
      );

      expect(verdict.score, shown, reason: 'разошлось на: ${sms.body}');
    }
  });

  test('the watch state stays rare on legitimate traffic', () {
    final clear = legitimateSms
        .where(
          (sms) =>
              inspectMessage(sms.body, sender: sms.sender).risk ==
              MessageRisk.clear,
        )
        .length;
    final share = clear / legitimateSms.length;
    // ignore: avoid_print
    print(
      'detector: ${(share * 100).round()}% легитимных сообщений — clear '
      '(${legitimateSms.length - clear} помечено watch)',
    );

    expect(share, greaterThanOrEqualTo(0.8));
  });
}
