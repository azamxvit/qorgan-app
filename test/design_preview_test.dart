import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/ui/core/theme.dart';
import 'package:qorgan_app/ui/preview/design_preview.dart';

void main() {
  testWidgets('renders four real Flutter screens without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1716, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: qorganTheme(),
        home: DesignPreview(boardKey: key),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Подозрительно · 7'), findsOneWidget);
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final file = File('artifacts/qorgan-light-preview.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes.buffer.asUint8List());
      image.dispose();
    });
    debugDisableShadows = true;
  });
}
