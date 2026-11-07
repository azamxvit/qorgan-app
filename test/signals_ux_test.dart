import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';
import 'package:qorgan_app/ui/core/light_components.dart';
import 'package:qorgan_app/ui/core/theme.dart';
import 'package:qorgan_app/ui/messages/signals_page.dart';

void main() {
  testWidgets('signal details do not claim an obsolete eleven-point maximum', (
    tester,
  ) async {
    const record = StoredMessage(
      message: IncomingSms(sender: 'Sender', body: 'Text', timestamp: 1),
      verdict: MessageVerdict(score: 22, signals: MessageSignal.values),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: qorganTheme(),
        home: SignalsPage(
          record: record,
          header: SmsHeader(onBack: () {}, onMenu: () {}, onProfile: () {}),
        ),
      ),
    );
    expect(find.textContaining('Из 11'), findsNothing);
    expect(find.text('Баллы по правилу: 22'), findsOneWidget);
  });
}
