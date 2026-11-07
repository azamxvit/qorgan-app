import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/blocklist_store.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';
import 'package:qorgan_app/ui/core/theme.dart';
import 'package:qorgan_app/ui/messages/manual_sms_result_page.dart';
import 'package:qorgan_app/ui/sms/view_models/sms_view_model.dart';
import 'package:qorgan_app/ui/sms/widgets/sms_screen.dart';

class DeferredBlocklist implements Blocklist {
  final requests = <Completer<Set<String>>>[];

  @override
  Future<Set<String>> blockedAmong(Iterable<String> hosts) {
    final request = Completer<Set<String>>();
    requests.add(request);
    return request.future;
  }
}

const warning = 'Срочно передайте код';

void main() {
  test('editing away and back discards the older in-flight verdict', () async {
    final blocklist = DeferredBlocklist();
    final model = SmsViewModel(
      repository: ProtectionRepository(blocklist: blocklist),
    );
    addTearDown(model.dispose);
    model.setText(warning);
    final pending = model.submit();
    expect(model.busy, isTrue);
    model.setText('Изменённый текст');
    model.setText(warning);
    blocklist.requests.single.complete({});
    expect(await pending, isNull);
    expect(model.result, isNull);
    expect(model.busy, isFalse);
  });

  test(
    'clearing and submitting another draft keeps only the newer verdict',
    () async {
      final blocklist = DeferredBlocklist();
      final model = SmsViewModel(
        repository: ProtectionRepository(blocklist: blocklist),
      );
      addTearDown(model.dispose);
      model.setText(warning);
      final first = model.submit();
      model.clear();
      model.setText('Увидимся завтра');
      expect(model.canSubmit, isTrue);
      final second = model.submit();
      blocklist.requests.last.complete({});
      expect((await second)?.verdict.risk, MessageRisk.clear);
      blocklist.requests.first.complete({});
      expect(await first, isNull);
      expect(model.result?.text, 'Увидимся завтра');
      expect(model.busy, isFalse);
    },
  );

  test(
    'disposal cancels a pending check without notifying disposed listeners',
    () async {
      final blocklist = DeferredBlocklist();
      final model = SmsViewModel(
        repository: ProtectionRepository(blocklist: blocklist),
      );
      model.setText(warning);
      final pending = model.submit();
      model.dispose();
      blocklist.requests.single.complete({});
      expect(await pending, isNull);
    },
  );

  testWidgets('a completed manual check does not cover a notification route', (
    tester,
  ) async {
    final blocklist = DeferredBlocklist();
    final model = SmsViewModel(
      repository: ProtectionRepository(blocklist: blocklist),
    )..setText(warning);
    addTearDown(model.dispose);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: qorganTheme(),
        home: Scaffold(body: SmsScreen(viewModel: model)),
      ),
    );
    await tester.tap(find.text('Проверить'));
    await tester.pump();
    expect(find.text('Проверяем…'), findsOneWidget);
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const Scaffold(body: Text('Входящее SMS из уведомления')),
      ),
    );
    await tester.pumpAndSettle();
    blocklist.requests.single.complete({});
    await tester.pumpAndSettle();
    expect(find.text('Входящее SMS из уведомления'), findsOneWidget);
    expect(find.byType(ManualSmsResultPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving and returning to the tab cancels pending automatic navigation',
    (tester) async {
      final blocklist = DeferredBlocklist();
      final model = SmsViewModel(
        repository: ProtectionRepository(blocklist: blocklist),
      )..setText(warning);
      addTearDown(model.dispose);
      final active = ValueNotifier(true);
      addTearDown(active.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: qorganTheme(),
          home: ValueListenableBuilder<bool>(
            valueListenable: active,
            builder: (_, selected, _) => Scaffold(
              body: IndexedStack(
                index: selected ? 0 : 1,
                children: [
                  SmsScreen(viewModel: model, active: selected),
                  const Text('Сообщения'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Проверить'));
      await tester.pump();
      active.value = false;
      await tester.pump();
      active.value = true;
      await tester.pump();
      blocklist.requests.single.complete({});
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ManualSmsResultPage), findsNothing);
      expect(model.text, warning);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('back during analysis does not use a disposed screen context', (
    tester,
  ) async {
    final blocklist = DeferredBlocklist();
    final model = SmsViewModel(
      repository: ProtectionRepository(blocklist: blocklist),
    )..setText(warning);
    addTearDown(model.dispose);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: qorganTheme(),
        home: const Scaffold(body: Text('Корень')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(body: SmsScreen(viewModel: model)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Проверить'));
    await tester.pump();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    blocklist.requests.single.complete({});
    await tester.pumpAndSettle();
    expect(find.text('Корень'), findsOneWidget);
    expect(find.byType(ManualSmsResultPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
