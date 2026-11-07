import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/incoming_message_service.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/data/services/onboarding_settings.dart';
import 'package:qorgan_app/ui/qorgan_app.dart';

import 'ui_feedback_test.dart' show record;
import 'ui_navigation_test.dart' show samples;

// Platform boundary only. AndroidSmsService owns persistence; the parent task
// verifies that implementation against SQLite, including missing keys.
class FeedbackPhone extends UnboundIncomingMessageService {
  List<StoredMessage> records = [record()];
  final writes = <(String, MessageFeedback)>[];
  Completer<void>? pendingWrite;
  bool failWrite = false;
  bool failRead = false;
  String? selectedKey;

  @override
  Future<List<StoredMessage>> recent() async {
    if (failRead) throw StateError('read failed');
    return List.of(records);
  }

  @override
  Future<void> recordFeedback(String key, MessageFeedback feedback) async {
    writes.add((key, feedback));
    await pendingWrite?.future;
    if (failWrite) throw StateError('write failed');
    final index = records.indexWhere((record) => record.key == key);
    if (index == -1) throw StateError('missing message');
    final old = records[index];
    records[index] = StoredMessage(
      message: old.message,
      verdict: old.verdict,
      notified: old.notified,
      feedback: feedback,
    );
  }

  @override
  bool get hasNotificationSelection => selectedKey != null;

  @override
  Future<StoredMessage?> openedMessage() async =>
      records.where((record) => record.key == selectedKey).firstOrNull;
}

Future<void> openApp(WidgetTester tester, FeedbackPhone phone) async {
  await tester.pumpWidget(
    QorganApp(
      repository: ProtectionRepository(),
      incomingMessages: phone,
      onboarding: MemoryOnboardingSettings(completed: true),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    maxScrolls: 100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> openHistoryDetail(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('tab-messages')));
  await tester.pumpAndSettle();
  final message = find.byKey(ValueKey('message-${record().key}'));
  await reveal(tester, message);
  await tester.tap(message);
  await tester.pumpAndSettle();
}

Future<void> openReport(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Настройки'));
  await tester.pumpAndSettle();
  await reveal(tester, find.text('Отчёт об исправлениях'));
  await tester.tap(find.text('Отчёт об исправлениях'));
  await tester.pumpAndSettle();
}

Finder get reportContent =>
    find.byKey(const ValueKey('feedback-report-content'));

void main() {
  for (final route in [
    'history',
    'launch notification',
    'running notification',
  ]) {
    testWidgets('root detail saves selected key only after await ($route)', (
      tester,
    ) async {
      final notification = route != 'history';
      final phone = FeedbackPhone()
        ..records = [samples.last, record()]
        ..pendingWrite = Completer<void>();
      if (route == 'launch notification') phone.selectedKey = record().key;
      await openApp(tester, phone);
      if (route == 'running notification') {
        phone.selectedKey = record().key;
        phone.onOpenMessage!();
        await tester.pumpAndSettle();
      }
      if (!notification) await openHistoryDetail(tester);
      final choice = notification
          ? 'Это не мошенничество'
          : 'Это мошенничество';
      final saved = notification
          ? 'Вы отметили: это не мошенничество'
          : 'Вы отметили: это мошенничество';
      await reveal(tester, find.text(choice));
      await tester.tap(find.text(choice));
      await tester.pumpAndSettle();
      expect(phone.writes, [
        (
          record().key,
          notification ? MessageFeedback.wrong : MessageFeedback.fraud,
        ),
      ]);
      expect(find.textContaining('Вы отметили:'), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, choice))
            .onPressed,
        isNull,
      );
      phone.pendingWrite!.complete();
      await tester.pumpAndSettle();
      expect(find.text(saved), findsOneWidget);
      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();
      await openHistoryDetail(tester);
      await reveal(tester, find.text(saved));
      expect(find.text(saved), findsOneWidget); // Root history was refreshed.
    });
  }

  for (final missing in [false, true]) {
    testWidgets(
      'failed save is retryable without acknowledgement (missing: $missing)',
      (tester) async {
        final phone = FeedbackPhone();
        await openApp(tester, phone);
        await openHistoryDetail(tester);
        if (missing) {
          phone.records = [samples.last];
        } else {
          phone.failWrite = true;
        }
        await reveal(tester, find.text('Это мошенничество'));
        await tester.tap(find.text('Это мошенничество'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Вы отметили:'), findsNothing);
        await reveal(
          tester,
          find.text('Не удалось сохранить отметку. Попробуйте ещё раз.'),
        );
        expect(
          find.text('Не удалось сохранить отметку. Попробуйте ещё раз.'),
          findsOneWidget,
        );
        phone.failWrite = false;
        phone.records = [record()];
        await reveal(tester, find.text('Это мошенничество'));
        await tester.tap(find.text('Это мошенничество'));
        await tester.pumpAndSettle();
        expect(find.text('Вы отметили: это мошенничество'), findsOneWidget);
        expect(phone.writes, [
          (record().key, MessageFeedback.fraud),
          (record().key, MessageFeedback.fraud),
        ]);
      },
    );
  }

  testWidgets(
    'report reads fresh records and awaits explicit copy at 320px and 200% text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final phone = FeedbackPhone();
      final copying = Completer<void>();
      final copies = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copies.add((call.arguments as Map)['text'] as String);
            await copying.future;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await openApp(tester, phone);
      // Change the store after root history was read; a cached list is unmarked.
      phone.records = [record(feedback: MessageFeedback.wrong)];
      await openReport(tester);
      await reveal(tester, find.textContaining('полный текст SMS'));
      expect(find.textContaining('отправителей'), findsOneWidget);
      expect(find.textContaining('удалите'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await reveal(tester, reportContent);
      final text = tester.widget<SelectableText>(reportContent).data!;
      expect(text, contains(record().message.body));
      expect(text, contains('Отправитель: ${record().message.sender}'));
      expect(text, contains('ложная тревога'));
      expect(copies, isEmpty);
      expect(tester.takeException(), isNull);
      await reveal(tester, find.text('Скопировать отчёт'));
      await tester.tap(find.text('Скопировать отчёт'));
      await tester.pumpAndSettle();
      expect(copies, [text]);
      expect(find.text('Отчёт скопирован'), findsNothing);
      copying.complete();
      await tester.pumpAndSettle();
      expect(find.text('Отчёт скопирован'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unmarked history has an empty report and no copy action', (
    tester,
  ) async {
    await openApp(tester, FeedbackPhone());
    await openReport(tester);
    await reveal(tester, find.text('Нет отметок для отчёта'));
    expect(find.text('Нет отметок для отчёта'), findsOneWidget);
    expect(reportContent, findsNothing);
    expect(find.text('Скопировать отчёт'), findsNothing);
  });

  testWidgets(
    'failed report read is an error, then retry reads the store again',
    (tester) async {
      final phone = FeedbackPhone();
      await openApp(tester, phone);
      phone.failRead = true;
      await openReport(tester);
      await reveal(
        tester,
        find.text('Не удалось загрузить отчёт. Попробуйте ещё раз.'),
      );
      expect(find.text('Нет отметок для отчёта'), findsNothing);
      expect(find.text('Скопировать отчёт'), findsNothing);
      phone.failRead = false;
      phone.records = [record(feedback: MessageFeedback.fraud)];
      await reveal(tester, find.text('Повторить'));
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      await reveal(tester, reportContent);
      expect(
        tester.widget<SelectableText>(reportContent).data,
        contains(record().message.body),
      );
    },
  );

  testWidgets(
    'clipboard failure shows an error without success and allows retry',
    (tester) async {
      var failCopy = true;
      var copies = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copies++;
            if (failCopy) {
              throw PlatformException(code: 'clipboard_unavailable');
            }
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final phone = FeedbackPhone()
        ..records = [record(feedback: MessageFeedback.fraud)];
      await openApp(tester, phone);
      await openReport(tester);
      await reveal(tester, find.text('Скопировать отчёт'));
      await tester.tap(find.text('Скопировать отчёт'));
      await tester.pumpAndSettle();
      expect(find.text('Отчёт скопирован'), findsNothing);
      await reveal(
        tester,
        find.text('Не удалось скопировать отчёт. Попробуйте ещё раз.'),
      );
      expect(
        find.text('Не удалось скопировать отчёт. Попробуйте ещё раз.'),
        findsOneWidget,
      );
      failCopy = false;
      await reveal(tester, find.text('Скопировать отчёт'));
      await tester.tap(find.text('Скопировать отчёт'));
      await tester.pumpAndSettle();
      expect(copies, 2);
      expect(find.text('Отчёт скопирован'), findsOneWidget);
    },
  );
}
