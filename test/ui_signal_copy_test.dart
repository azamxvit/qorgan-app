import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';
import 'package:qorgan_app/ui/core/copy.dart';
import 'package:qorgan_app/ui/messages/message_presentation.dart';

void main() {
  // The signal screens read these maps with `!`. A signal without an entry
  // crashes the app on the first message that carries it.
  test('every signal has a name, a reason, a weight and a verdict line', () {
    for (final signal in MessageSignal.values) {
      expect(signalNames[signal], isNotNull, reason: 'no name for $signal');
      expect(signalReasons[signal], isNotNull, reason: 'no reason for $signal');
      expect(signalWeights[signal], isNotNull, reason: 'no weight for $signal');
      expect(
        AppCopy.signalText[signal],
        isNotNull,
        reason: 'no verdict line for $signal',
      );
    }
  });

  test('the signal rows show every signal the rule actually found', () {
    final verdict = inspectMessage(
      'Halyk Bank: по вашей карте замечена операция. Перезвоните нам.',
      sender: '+7 701 123 45 67',
    );

    expect(verdict.signals, contains(MessageSignal.impersonation));
    expect(signalRows(verdict), containsAll(verdict.signals));
  });
}
