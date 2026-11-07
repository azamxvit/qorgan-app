import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/ui/core/theme.dart';
import 'package:qorgan_app/ui/messages/message_detail_page.dart';
import 'package:qorgan_app/ui/core/light_components.dart';

StoredMessage record({MessageFeedback feedback = MessageFeedback.none}) {
  const sms = IncomingSms(
    sender: 'KASPI',
    body: 'Kaspi.kz: код 8123 для входа. Никому его не сообщайте.',
    timestamp: 1762500000000,
  );
  return StoredMessage(
    message: sms,
    verdict: inspectMessage(sms.body, sender: sms.sender),
    feedback: feedback,
  );
}

void main() {
  Future<List<MessageFeedback>> open(
    WidgetTester tester, {
    MessageFeedback feedback = MessageFeedback.none,
  }) async {
    final given = <MessageFeedback>[];
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: qorganTheme(),
        home: SmsDetailPage(
          record: record(feedback: feedback),
          header: SmsHeader(onBack: () {}, onMenu: () {}, onProfile: () {}),
          onSignals: () {},
          onFeedback: (value) async => given.add(value),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return given;
  }

  testWidgets('the user can say the warning was wrong', (tester) async {
    final given = await open(tester);

    await tester.scrollUntilVisible(
      find.text('Это не мошенничество'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Это не мошенничество'));
    await tester.pumpAndSettle();

    expect(given, [MessageFeedback.wrong]);
  });

  testWidgets('the user can confirm it really was fraud', (tester) async {
    final given = await open(tester);

    await tester.scrollUntilVisible(
      find.text('Это мошенничество'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Это мошенничество'));
    await tester.pumpAndSettle();

    expect(given, [MessageFeedback.fraud]);
  });

  testWidgets('a recorded answer is shown instead of asking again', (
    tester,
  ) async {
    await open(tester, feedback: MessageFeedback.fraud);
    await tester.scrollUntilVisible(
      find.textContaining('Вы отметили'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Вы отметили'), findsOneWidget);
    expect(find.text('Это мошенничество'), findsNothing);
  });

  testWidgets('failed feedback is not acknowledged and can be retried', (
    tester,
  ) async {
    var fails = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: qorganTheme(),
        home: SmsDetailPage(
          record: record(),
          header: SmsHeader(onBack: () {}, onMenu: () {}, onProfile: () {}),
          onSignals: () {},
          onFeedback: (_) async {
            if (fails) throw StateError('storage');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Это мошенничество'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Это мошенничество'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Вы отметили'), findsNothing);
    expect(
      find.text('Не удалось сохранить отметку. Попробуйте ещё раз.'),
      findsOneWidget,
    );
    fails = false;
    await tester.ensureVisible(find.text('Это мошенничество'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Это мошенничество'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Вы отметили'), findsOneWidget);
  });

  testWidgets('tapping records the answer and stops asking', (tester) async {
    await open(tester);

    await tester.scrollUntilVisible(
      find.text('Это мошенничество'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Это мошенничество'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Вы отметили'), findsOneWidget);
  });
}
