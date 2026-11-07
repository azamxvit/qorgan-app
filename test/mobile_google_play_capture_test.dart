import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/ui/qorgan_app.dart';

import 'mobile_ux_test.dart' show FreshPhone;

void main() {
  testWidgets('captures empty first-run screens for the store listing', (
    tester,
  ) async {
    // These are widget renders, not captures from an Android device.
    await tester.binding.setSurfaceSize(const Size(432, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await (FontLoader(
      'Manrope',
    )..addFont(rootBundle.load('assets/fonts/Manrope.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();

    final key = GlobalKey();
    final phone = FreshPhone();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: QorganApp(
          repository: ProtectionRepository(),
          incomingMessages: phone,
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.5);
        try {
          expect(image.width, 1080);
          expect(image.height, 1920);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final output = File('docs/google-play/assets/phone-$name.png');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        } finally {
          image.dispose();
        }
      });
      expect(tester.takeException(), isNull);
    }

    await capture('welcome');
    await tester.ensureVisible(find.text('Настроить защиту'));
    await tester.tap(find.text('Настроить защиту'));
    await tester.pumpAndSettle();
    await capture('setup');
    await tester.ensureVisible(find.text('Позже'));
    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();
    await capture('home');
    await tester.tap(find.byKey(const ValueKey('tab-check')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    await capture('manual');
    expect(phone.requests + phone.smsRequests + phone.notificationRequests, 0);
  });
}
