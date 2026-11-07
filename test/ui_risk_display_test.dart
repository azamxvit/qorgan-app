import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';
import 'package:qorgan_app/ui/core/light_components.dart';

void main() {
  Future<void> pump(WidgetTester tester, MessageRisk risk) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: StatusPill(risk: risk)),
    ),
  );

  Color fill(WidgetTester tester) {
    final container = tester.widget<Container>(find.byType(Container));
    return (container.decoration! as BoxDecoration).color!;
  }

  testWidgets('each risk state has its own label', (tester) async {
    await pump(tester, MessageRisk.clear);
    expect(find.text('Низкий риск'), findsOneWidget);

    await pump(tester, MessageRisk.watch);
    expect(find.text('Стоит проверить'), findsOneWidget);

    await pump(tester, MessageRisk.warn);
    expect(find.text('Подозрительное SMS'), findsOneWidget);
  });

  testWidgets('the three states are told apart without reading the label', (
    tester,
  ) async {
    final fills = <MessageRisk, Color>{};
    for (final risk in MessageRisk.values) {
      await pump(tester, risk);
      fills[risk] = fill(tester);
    }

    expect(fills.values.toSet(), hasLength(MessageRisk.values.length));
  });
}
