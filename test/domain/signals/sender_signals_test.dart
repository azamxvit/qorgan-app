import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/signals/sender_signals.dart';

void main() {
  test('a full mobile number is personal', () {
    expect(isPersonalNumber('+7 701 123 45 67'), isTrue);
    expect(isPersonalNumber('77011234567'), isTrue);
  });

  test('a short code or an alphanumeric name is not personal', () {
    expect(isPersonalNumber('1414'), isFalse);
    expect(isPersonalNumber('KASPI'), isFalse);
    expect(isPersonalNumber(''), isFalse);
  });
}
