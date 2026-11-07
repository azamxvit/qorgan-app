import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/ui/qorgan_app.dart';

import 'domain/sms_corpus.dart';
import 'mobile_ux_test.dart' show FreshPhone;

void main() {
  testWidgets('captures the implemented first-run journey', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: QorganApp(
          repository: ProtectionRepository(),
          incomingMessages: FreshPhone(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await File('artifacts/qorgan-ux-$name.png')
            .writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await capture('welcome');
    await tester.ensureVisible(find.text('Настроить защиту'));
    await tester.tap(find.text('Настроить защиту'));
    await tester.pumpAndSettle();
    await capture('setup');
    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();
    await capture('home');
    await tester.tap(find.byKey(const ValueKey('tab-check')));
    await tester.pumpAndSettle();
    await capture('manual');
    await tester.enterText(find.byType(TextField), corpusPhishingSample);
    await tester.pump();
    await tester.tap(find.text('Проверить', skipOffstage: true));
    await tester.pumpAndSettle();
    await capture('result');
  });
}
