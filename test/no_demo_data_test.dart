import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Demo data in a security app is worse than no data: it teaches the user to
  // trust a screen that was never fed by their phone. Sample SMS text belongs
  // in test/domain/sms_corpus.dart and nowhere else.
  test('no demo message, preview mode or sample button ships in lib/', () {
    const markers = [
      'QORGAN_PREVIEW',
      'design_preview',
      'previewMessages',
      'phishingText',
      'ordinaryText',
      'simulate',
    ];
    final offenders = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final marker in markers) {
        if (source.contains(marker)) offenders.add('${file.path}: $marker');
      }
    }

    expect(offenders, isEmpty);
  });
}
