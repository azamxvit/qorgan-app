import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';
import 'package:qorgan_app/ui/core/light_components.dart';
import 'package:qorgan_app/ui/core/theme.dart';
import 'package:qorgan_app/ui/messages/message_detail_page.dart';
import 'package:qorgan_app/ui/messages/messages_page.dart';
import 'package:qorgan_app/ui/sms/view_models/sms_view_model.dart';
import 'package:qorgan_app/ui/sms/widgets/sms_screen.dart';

class CountingRepository extends ProtectionRepository {
  int inspections = 0;
  bool fail = false;

  @override
  Future<MessageVerdict> inspect(String text, {String sender = ''}) async {
    inspections++;
    if (fail) throw StateError('Analysis unavailable');
    return super.inspect(text, sender: sender);
  }
}

const warningText = 'Срочно отправьте код: https://verify.example/login';

StoredMessage sample(String sender, int score) => StoredMessage(
  message: IncomingSms(sender: sender, body: warningText, timestamp: 1),
  verdict: MessageVerdict(
    score: score,
    signals: score == 0 ? [] : [MessageSignal.secret],
  ),
);

SmsHeader get header =>
    SmsHeader(onBack: () {}, onMenu: () {}, onProfile: () {});

Future<void> pumpContent(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: qorganTheme(),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('typing waits for explicit submission before inspecting', (
    tester,
  ) async {
    final repository = CountingRepository();
    final model = SmsViewModel(repository: repository);
    addTearDown(model.dispose);
    await pumpContent(tester, SmsScreen(viewModel: model));
    await tester.enterText(find.byType(TextField), warningText);
    await tester.pump();
    expect(repository.inspections, 0);
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();
    expect(repository.inspections, 1);
    expect(find.text('Подозрительное SMS'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Изменить текст'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Изменить текст'), findsOneWidget);
    await tester.tap(find.text('Изменить текст'));
    await tester.pumpAndSettle();
    expect(find.text(warningText), findsOneWidget);
  });

  testWidgets('whitespace cannot submit an empty assessment', (tester) async {
    final model = SmsViewModel(repository: ProtectionRepository());
    addTearDown(model.dispose);
    await pumpContent(tester, SmsScreen(viewModel: model));
    await tester.enterText(find.byType(TextField), '  \n  ');
    await tester.pump();
    expect(find.text('Проверить'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('draft survives rebuilding the manual tab', (tester) async {
    final model = SmsViewModel(repository: ProtectionRepository());
    addTearDown(model.dispose);
    await pumpContent(tester, SmsScreen(viewModel: model));
    await tester.enterText(find.byType(TextField), 'Черновик сообщения');
    await pumpContent(tester, const SizedBox());
    await pumpContent(tester, SmsScreen(viewModel: model));
    expect(find.text('Черновик сообщения'), findsOneWidget);
  });

  testWidgets('clipboard is read only after the paste action', (tester) async {
    var reads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') {
          reads++;
          return {'text': 'Текст из буфера'};
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    final model = SmsViewModel(repository: ProtectionRepository());
    addTearDown(model.dispose);
    await pumpContent(tester, SmsScreen(viewModel: model));
    expect(reads, 0);
    expect(find.text('Вставить текст'), findsOneWidget);
    await tester.tap(find.text('Вставить текст'));
    await tester.pumpAndSettle();
    expect(reads, 1);
    expect(find.text('Текст из буфера'), findsOneWidget);
  });

  testWidgets('history separates watch from clear and suspicious SMS', (
    tester,
  ) async {
    await pumpContent(
      tester,
      MessagesPage(
        messages: [sample('ALERT', 4), sample('CHECK', 3), sample('LOW', 0)],
        header: header,
        onMessage: (_) {},
        onManual: () {},
      ),
    );
    expect(find.byKey(const ValueKey('filter-watch')), findsOneWidget);
    for (final entry in {
      'watch': 'CHECK',
      'suspicious': 'ALERT',
      'normal': 'LOW',
    }.entries) {
      await tester.ensureVisible(find.byKey(ValueKey('filter-${entry.key}')));
      await tester.tap(find.byKey(ValueKey('filter-${entry.key}')));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      for (final other in [
        'ALERT',
        'CHECK',
        'LOW',
      ].where((s) => s != entry.value)) {
        expect(find.text(other), findsNothing);
      }
    }
  });

  testWidgets('filtered empty history can return to all messages', (
    tester,
  ) async {
    await pumpContent(
      tester,
      MessagesPage(
        messages: [sample('LOW', 0)],
        header: header,
        onMessage: (_) {},
        onManual: () {},
      ),
    );
    await tester.tap(find.byKey(const ValueKey('filter-suspicious')));
    await tester.pumpAndSettle();
    expect(find.text('Сообщений с такой оценкой нет'), findsOneWidget);
    await tester.tap(find.text('Показать все'));
    await tester.pumpAndSettle();
    expect(find.text('LOW'), findsOneWidget);
  });

  testWidgets('message details expose original text without opening links', (
    tester,
  ) async {
    await pumpContent(
      tester,
      SmsDetailPage(
        record: sample('REAL SENDER', 4),
        header: header,
        onSignals: () {},
      ),
    );
    expect(find.byType(SelectableText), findsOneWidget);
    final original = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(original.data, warningText);
    expect(original.onTap, isNull);
  });

  test(
    'changing a checked draft invalidates the result until resubmitted',
    () async {
      final model = SmsViewModel(repository: ProtectionRepository());
      addTearDown(model.dispose);
      model.setText(warningText);
      final first = (await model.submit())!;
      expect(first.verdict.risk, MessageRisk.warn);
      model.setText('Встречаемся завтра');
      expect(model.result, isNull);
      expect(model.verdict, isNull);
      expect(first.text, warningText);
      expect(first.verdict.risk, MessageRisk.warn);
      final next = (await model.submit())!;
      expect(next.text, 'Встречаемся завтра');
      expect(next.verdict.risk, MessageRisk.clear);
      model.clear();
      expect(model.text, isEmpty);
      expect(model.result, isNull);
      expect(model.canSubmit, isFalse);
    },
  );

  testWidgets('analysis failure keeps the draft and offers a real retry', (
    tester,
  ) async {
    final repository = CountingRepository()..fail = true;
    final model = SmsViewModel(repository: repository);
    addTearDown(model.dispose);
    await pumpContent(tester, SmsScreen(viewModel: model));
    await tester.enterText(find.byType(TextField), warningText);
    await tester.pump();
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();
    expect(
      find.text('Не удалось проверить текст. Попробуйте ещё раз.'),
      findsOneWidget,
    );
    expect(find.text(warningText), findsOneWidget);
    expect(find.text('Низкий риск'), findsNothing);
    expect(model.result, isNull);
    repository.fail = false;
    await tester.ensureVisible(find.text('Проверить'));
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();
    expect(find.text('Подозрительное SMS'), findsOneWidget);
    expect(model.error, isNull);
  });

  testWidgets('empty clipboard explains why the draft remains unchanged', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData' ? {'text': '  '} : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final model = SmsViewModel(repository: ProtectionRepository())
      ..setText('Черновик');
    addTearDown(model.dispose);
    await pumpContent(tester, SmsScreen(viewModel: model));
    await tester.tap(find.text('Вставить текст'));
    await tester.pump();
    expect(find.text('В буфере обмена нет текста'), findsOneWidget);
    expect(model.text, 'Черновик');
  });

  testWidgets('history error offers retry instead of claiming no messages', (
    tester,
  ) async {
    var retried = false;
    var openedManual = false;
    await pumpContent(
      tester,
      MessagesPage(
        messages: const [],
        header: header,
        onMessage: (_) {},
        onManual: () => openedManual = true,
        historyError: 'Storage unavailable',
        onRetry: () => retried = true,
      ),
    );
    expect(find.text('Не удалось загрузить сообщения'), findsOneWidget);
    expect(find.text('Входящих SMS пока нет'), findsNothing);
    await tester.tap(find.text('Повторить'));
    expect(retried, isTrue);
    await tester.tap(find.text('Проверить SMS вручную'));
    expect(openedManual, isTrue);
    await pumpContent(
      tester,
      MessagesPage(
        messages: const [],
        header: header,
        onMessage: (_) {},
        onManual: () {},
      ),
    );
    expect(find.text('Входящих SMS пока нет'), findsOneWidget);
    expect(find.text('Не удалось загрузить сообщения'), findsNothing);
  });

  testWidgets('receiving history updates preserves the chosen risk filter', (
    tester,
  ) async {
    Widget history(List<StoredMessage> messages) => MessagesPage(
      messages: messages,
      header: header,
      onMessage: (_) {},
      onManual: () {},
    );
    await pumpContent(tester, history([sample('OLD WATCH', 3)]));
    await tester.ensureVisible(find.byKey(const ValueKey('filter-watch')));
    await tester.tap(find.byKey(const ValueKey('filter-watch')));
    await tester.pumpAndSettle();
    await pumpContent(
      tester,
      history([sample('NEW LOW', 0), sample('NEW WATCH', 3)]),
    );
    expect(find.text('NEW WATCH'), findsOneWidget);
    expect(find.text('NEW LOW'), findsNothing);
  });

  testWidgets(
    'manual action stays reachable at 320px with large text and keyboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final model = SmsViewModel(repository: ProtectionRepository());
      addTearDown(model.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: qorganTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 200),
            ),
            child: child!,
          ),
          home: Scaffold(body: SmsScreen(viewModel: model)),
        ),
      );
      await tester.scrollUntilVisible(
        find.byType(TextField),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), warningText);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Проверить'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Проверить'));
      await tester.pumpAndSettle();
      expect(find.text('Подозрительное SMS'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Изменить текст'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Изменить текст'));
      await tester.pumpAndSettle();
      expect(model.text, warningText);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'history and long sender details support 320px at 200 percent text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final record = sample('ACME VERIFICATION SERVICE WITH A LONG SENDER', 4);
      Future<void> large(Widget child) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: qorganTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: child,
          ),
        );
        await tester.pumpAndSettle();
      }

      await large(
        MessagesPage(
          messages: [record],
          header: header,
          onMessage: (_) {},
          onManual: () {},
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Проверить SMS вручную'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await large(
        SmsDetailPage(record: record, header: header, onSignals: () {}),
      );
      await tester.scrollUntilVisible(
        find.text('Подробности оценки'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Подробности оценки'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Все признаки'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Баллы по правилу: 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
