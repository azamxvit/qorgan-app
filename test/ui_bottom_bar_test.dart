import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/ui/core/light_components.dart';

void main() {
  for (final reducedMotion in [false, true]) {
    testWidgets(
      'tab width transitions respect reduced motion: $reducedMotion',
      (tester) async {
        var selected = 0;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: reducedMotion),
              child: child!,
            ),
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                bottomNavigationBar: QorganBottomBar(
                  selectedIndex: selected,
                  onSelected: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        );
        const keys = ['tab-protection', 'tab-check', 'tab-messages'];
        double width(int index) =>
            tester.getSize(find.byKey(ValueKey(keys[index]))).width;
        final expanded = width(0);
        final collapsed = width(1);
        for (final index in [1, 2, 0]) {
          final pill = find.byKey(const ValueKey('tab-active-pill'));
          final start = tester.getTopLeft(pill).dx;
          await tester.tap(find.byKey(ValueKey(keys[index])));
          await tester.pump();
          if (!reducedMotion) {
            expect(tester.getTopLeft(pill).dx, closeTo(start, .1));
          }
          await tester.pump(const Duration(milliseconds: 80));
          final midway = tester.getTopLeft(pill).dx;
          if (reducedMotion) {
            expect(width(index), closeTo(expanded, .1));
          } else {
            expect(width(index), greaterThan(collapsed));
            expect(width(index), lessThan(expanded));
          }
          await tester.pumpAndSettle();
          if (!reducedMotion) {
            final end = tester.getTopLeft(pill).dx;
            expect(midway, greaterThan(start < end ? start : end));
            expect(midway, lessThan(start > end ? start : end));
          }
          expect(width(index), closeTo(expanded, .1));
          expect(tester.takeException(), isNull);
        }
        // Reversing mid-transition must settle on the most recent tap.
        await tester.tap(find.byKey(const ValueKey('tab-check')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(find.byKey(const ValueKey('tab-messages')));
        await tester.pumpAndSettle();
        expect(width(2), closeTo(expanded, .1));
        expect(find.text('Сообщения'), findsOneWidget);
        expect(find.text('Защита'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'only selected label is visible and every tab remains accessible',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              bottomNavigationBar: QorganBottomBar(
                selectedIndex: selected,
                onSelected: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Защита'), findsOneWidget);
      expect(find.text('Сообщения'), findsNothing);
      expect(find.bySemanticsLabel('Сообщения'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tab-messages')));
      await tester.pumpAndSettle();
      expect(selected, 2);
      expect(find.text('Сообщения'), findsOneWidget);
      expect(find.text('Защита'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('narrow screen and large text keep targets above system inset', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final scale in [1.0, 2.0, 3.0]) {
      for (var index = 0; index < 3; index++) {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(bottom: 34),
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              bottomNavigationBar: QorganBottomBar(
                selectedIndex: index,
                onSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        for (final key in ['tab-protection', 'tab-check', 'tab-messages']) {
          final rect = tester.getRect(find.byKey(ValueKey(key)));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.bottom, lessThanOrEqualTo(666));
        }
        expect(tester.takeException(), isNull);
      }
    }
  });
}
