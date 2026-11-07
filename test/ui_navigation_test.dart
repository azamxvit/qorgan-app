import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/ui/messages/message_presentation.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/incoming_message_service.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/ui/qorgan_app.dart';

final samples =
    [
          const IncomingSms(
            sender: 'KASPI',
            body: 'Kaspi: Подтвердите код: https://verify-card.example/login',
            timestamp: 1791972300000,
          ),
          const IncomingSms(
            sender: 'HALYK',
            body: 'Halyk Bank: Поступление 20000',
            timestamp: 1791962300000,
          ),
        ]
        .map(
          (sms) =>
              StoredMessage(message: sms, verdict: inspectMessage(sms.body)),
        )
        .toList();

class HistoryService extends UnboundIncomingMessageService {
  @override
  Future<List<StoredMessage>> recent() async => samples;
  @override
  Future<StoredMessage?> latest() async => samples.first;
}

void main() {
  Future<void> app(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      QorganApp(
        repository: ProtectionRepository(),
        incomingMessages: HistoryService(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard opens stored SMS then its real signal breakdown', (
    tester,
  ) async {
    await app(tester);
    expect(find.text('Последние SMS'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('KASPI'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('KASPI').first);
    await tester.pumpAndSettle();
    expect(find.text('Подозрительное SMS'), findsOneWidget);
    for (
      var i = 0;
      i < 10 &&
          find.text('Подробности оценки').hitTestable().evaluate().isEmpty;
      i++
    ) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Подробности оценки'));
    await tester.pumpAndSettle();
    for (
      var i = 0;
      i < 10 &&
          find
              .byKey(const ValueKey('open-signals'))
              .hitTestable()
              .evaluate()
              .isEmpty;
      i++
    ) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -250));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('open-signals')));
    await tester.pumpAndSettle();
    expect(find.text('Из чего сложилось'), findsOneWidget);
    for (final signal in samples.first.verdict.signals) {
      expect(
        find.text(signalNames[signal]!),
        findsWidgets,
        reason: 'the breakdown hides ${signalNames[signal]}',
      );
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'normal filter excludes suspicious SMS while keeping normal sender',
    (tester) async {
      await app(tester);
      await tester.tap(find.byKey(const ValueKey('tab-messages')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('filter-normal')));
      await tester.tap(find.byKey(const ValueKey('filter-normal')));
      await tester.pumpAndSettle();
      expect(find.text('KASPI'), findsNothing);
      expect(find.text('HALYK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
