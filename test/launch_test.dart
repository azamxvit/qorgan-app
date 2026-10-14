import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/incoming_message_service.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/ui/preview/design_preview.dart';
import 'package:qorgan_app/ui/qorgan_app.dart';
import 'package:qorgan_app/ui/launch/launch_splash.dart';
import 'package:qorgan_app/ui/core/theme.dart';

class NotificationLaunch extends UnboundIncomingMessageService {
  @override
  Future<StoredMessage?> openedMessage() async => previewMessages().first;
}

void main() {
  testWidgets('brand lasts one second and does not replay on resume', (
    tester,
  ) async {
    await tester.pumpWidget(
      QorganApp(
        repository: ProtectionRepository(),
        incomingMessages: UnboundIncomingMessageService(),
      ),
    );
    expect(find.byKey(const ValueKey('launch-splash')), findsOneWidget);
    expect(find.text('Qorğan'), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const ValueKey('launch-splash')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 116));
    expect(find.byKey(const ValueKey('launch-splash')), findsNothing);
    expect(find.text('Последние SMS'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('launch-splash')), findsNothing);
  });
  testWidgets('notification opens its SMS before the splash second expires', (
    tester,
  ) async {
    await tester.pumpWidget(
      QorganApp(
        repository: ProtectionRepository(),
        incomingMessages: NotificationLaunch(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('launch-splash')), findsNothing);
    expect(find.text('Подозрительно · 7'), findsOneWidget);
    await tester.pumpAndSettle();
  });
  testWidgets('reduced motion preserves duration without fading or scaling', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: qorganTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: LaunchSplash(onComplete: () => completed = true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(completed, isFalse);
    final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
    expect(opacities.every((widget) => widget.opacity == 1), isTrue);
    await tester.pump(const Duration(milliseconds: 516));
    expect(completed, isTrue);
  });
  testWidgets('preview offers repeatable launch and renders original brand', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const QorganPreviewApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preview-launch')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Qorğan'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Qorğan'), findsNothing);
    await tester.tap(find.text('Повторить'));
    await tester.pump();
    expect(find.text('Qorğan'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.text('Повторить'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('captures the Flutter launch screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: qorganTheme(),
        home: RepaintBoundary(
          key: key,
          child: LaunchSplash(onComplete: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      await File('artifacts/qorgan-launch-preview.png')
          .writeAsBytes(bytes.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
