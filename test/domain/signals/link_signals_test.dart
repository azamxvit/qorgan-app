import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/signals/link_signals.dart';

void main() {
  test('finds hosts with and without a scheme', () {
    expect(linkedHosts('перейдите https://verify.example/a'), [
      'verify.example',
    ]);
    expect(linkedHosts('получите на halyk-bonus.ru'), ['halyk-bonus.ru']);
  });

  test('ignores an email domain', () {
    expect(linkedHosts('пишите на support@qorgan-help.ru'), isEmpty);
  });

  test('a subdomain of a bank is official, a lookalike is not', () {
    expect(isOfficialHost('app.kaspi.kz'), isTrue);
    expect(isOfficialHost('kaspi.kz.verify.ru'), isFalse);
  });
}
