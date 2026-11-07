import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/incoming_message_service.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/ui/core/colors.dart';
import 'package:qorgan_app/ui/qorgan_app.dart';
import 'package:qorgan_app/data/services/onboarding_settings.dart';
import 'package:qorgan_app/ui/launch/brand_mark.dart';
import 'package:qorgan_app/ui/launch/launch_splash.dart';
import 'package:qorgan_app/ui/launch/welcome_page.dart';
import 'package:qorgan_app/ui/core/theme.dart';

import 'domain/sms_corpus.dart';

class NotificationLaunch extends UnboundIncomingMessageService {
  static const _tapped = IncomingSms(
    sender: 'KASPI',
    body: corpusPhishingSample,
    timestamp: 1,
  );

  static final tappedVerdict = inspectMessage(
    _tapped.body,
    sender: _tapped.sender,
  );

  @override
  Future<StoredMessage?> openedMessage() async =>
      StoredMessage(message: _tapped, verdict: tappedVerdict);
}

const _phone = Size(390, 844);

Future<void> _phoneSurface(WidgetTester tester, [Size size = _phone]) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _splash({
  bool holdMark = false,
  bool reduced = false,
  VoidCallback? onComplete,
}) => MaterialApp(
  theme: qorganTheme(),
  home: MediaQuery(
    data: MediaQueryData(size: _phone, disableAnimations: reduced),
    child: LaunchSplash(holdMark: holdMark, onComplete: onComplete ?? () {}),
  ),
);

Widget _welcome({
  required bool revealed,
  bool reduced = false,
  VoidCallback? onSetup,
}) => MaterialApp(
  theme: qorganTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: WelcomePage(
    supported: true,
    revealed: revealed,
    onSetup: onSetup ?? () {},
    onManual: () {},
    onPrivacy: () {},
  ),
);

BrandMark _splashMark(WidgetTester tester) =>
    tester.widget<BrandMark>(find.byKey(const ValueKey('launch-mark')));

double _opacityAbove(WidgetTester tester, Finder target) => tester
    .widgetList<Opacity>(
      find.ancestor(of: target, matching: find.byType(Opacity)),
    )
    .fold(1.0, (value, widget) => value * widget.opacity);

void main() {
  testWidgets('brand lasts 1.4 seconds and does not replay on resume', (
    tester,
  ) async {
    await tester.pumpWidget(
      QorganApp(
        onboarding: MemoryOnboardingSettings(completed: true),
        repository: ProtectionRepository(),
        incomingMessages: UnboundIncomingMessageService(),
      ),
    );
    expect(find.byKey(const ValueKey('launch-splash')), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.byKey(const ValueKey('launch-splash')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 116));
    expect(find.byKey(const ValueKey('launch-splash')), findsNothing);
    expect(find.text('Последние SMS'), findsOneWidget);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('launch-splash')), findsNothing);
  });

  testWidgets('notification opens its SMS before the splash expires', (
    tester,
  ) async {
    await tester.pumpWidget(
      QorganApp(
        onboarding: MemoryOnboardingSettings(completed: true),
        repository: ProtectionRepository(),
        incomingMessages: NotificationLaunch(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('launch-splash')), findsNothing);
    expect(find.text('Подозрительное SMS'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('first launch hands the held mark over to the welcome', (
    tester,
  ) async {
    await _phoneSurface(tester);
    await tester.pumpWidget(
      QorganApp(
        onboarding: MemoryOnboardingSettings(),
        repository: ProtectionRepository(),
        incomingMessages: UnboundIncomingMessageService(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1395));
    expect(_splashMark(tester).size, closeTo(96, .5));
    expect(_opacityAbove(tester, find.text('Проверить SMS')), 0);
    await tester.pump(const Duration(milliseconds: 21));
    expect(find.byKey(const ValueKey('launch-splash')), findsNothing);
    expect(
      tester.getCenter(find.byKey(const ValueKey('welcome-mark'))),
      _phone.center(Offset.zero),
    );
    await tester.pump(const Duration(milliseconds: 1100));
    expect(_opacityAbove(tester, find.text('Проверить SMS')), 1);
  });

  testWidgets('splash opens on a dark mark that settles from 128 to 96', (
    tester,
  ) async {
    await _phoneSurface(tester);
    await tester.pumpWidget(_splash());
    await tester.pump();
    expect(_splashMark(tester).size, 128);
    expect(_splashMark(tester).color, QorganColors.mintInk);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_splashMark(tester).size, closeTo(96, .5));
    expect(_splashMark(tester).color, QorganColors.mintInk);
    await tester.pumpAndSettle();
  });

  testWidgets('held mark ends mint, 96 px, at the screen centre', (
    tester,
  ) async {
    await _phoneSurface(tester);
    var completed = false;
    await tester.pumpWidget(
      _splash(holdMark: true, onComplete: () => completed = true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1395));
    expect(completed, isFalse);
    final mark = _splashMark(tester);
    expect(mark.size, closeTo(96, .5));
    expect(mark.color.g, closeTo(QorganColors.mint.g, .02));
    expect(
      tester.getCenter(find.byKey(const ValueKey('launch-mark'))),
      _phone.center(Offset.zero),
    );
    await tester.pump(const Duration(milliseconds: 10));
    expect(completed, isTrue);
  });

  testWidgets('released mark closes together with the circle', (tester) async {
    await _phoneSurface(tester);
    await tester.pumpWidget(_splash());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1250));
    expect(_splashMark(tester).size, lessThan(90));
    await tester.pump(const Duration(milliseconds: 149));
    expect(_splashMark(tester).size, lessThan(3));
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion holds a still frame for the same time', (
    tester,
  ) async {
    await _phoneSurface(tester);
    var completed = false;
    await tester.pumpWidget(
      _splash(reduced: true, onComplete: () => completed = true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(_splashMark(tester).size, 128);
    expect(_splashMark(tester).color, QorganColors.mintInk);
    expect(completed, isFalse);
    await tester.pump(const Duration(milliseconds: 716));
    expect(completed, isTrue);
  });

  testWidgets('welcome shows only the centred mark, the name and actions', (
    tester,
  ) async {
    await _phoneSurface(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_welcome(revealed: true));
    await tester.pumpAndSettle();
    expect(find.text('Разберитесь в подозрительном SMS'), findsNothing);
    expect(find.byType(BrandMark), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const ValueKey('welcome-mark'))),
      _phone.center(Offset.zero),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('welcome-mark'))).width,
      96,
    );
    expect(find.bySemanticsLabel('Qorğan'), findsOneWidget);
    expect(find.text('Настроить защиту'), findsOneWidget);
    expect(find.text('Текст SMS не отправляется на сервер'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('welcome actions stay hidden and inert until the reveal', (
    tester,
  ) async {
    await _phoneSurface(tester);
    var setups = 0;
    await tester.pumpWidget(_welcome(revealed: false, onSetup: () => setups++));
    await tester.pump(const Duration(seconds: 2));
    expect(_opacityAbove(tester, find.text('Настроить защиту')), 0);
    await tester.tap(find.text('Настроить защиту'), warnIfMissed: false);
    expect(setups, 0);

    await tester.pumpWidget(_welcome(revealed: true, onSetup: () => setups++));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_opacityAbove(tester, find.text('Настроить защиту')), 0);
    await tester.pump(const Duration(milliseconds: 800));
    expect(_opacityAbove(tester, find.text('Настроить защиту')), 1);
    await tester.tap(find.text('Настроить защиту'));
    expect(setups, 1);
  });

  testWidgets('reduced motion shows the welcome at once', (tester) async {
    await _phoneSurface(tester);
    await tester.pumpWidget(_welcome(revealed: true, reduced: true));
    await tester.pump();
    expect(_opacityAbove(tester, find.text('Настроить защиту')), 1);
  });

  testWidgets('name never overlaps actions at 320px and 200 percent text', (
    tester,
  ) async {
    await _phoneSurface(tester, const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_welcome(revealed: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final name = tester.getRect(find.byKey(const ValueKey('welcome-name')));
    final actions = tester.getRect(
      find.byKey(const ValueKey('welcome-actions')),
    );
    expect(name.bottom, lessThanOrEqualTo(actions.top));
    expect(
      tester.getRect(find.byKey(const ValueKey('welcome-mark'))).top,
      greaterThanOrEqualTo(0),
    );
  });

  testWidgets('captures the Flutter launch screen', (tester) async {
    await _phoneSurface(tester);
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
    await tester.pump(const Duration(milliseconds: 800));
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
