/// What the sender field says about who is on the other end.
///
/// Mirrored in Swift for the iOS message filter extension, which cannot run
/// Dart. Keep the behaviour identical and covered by the shared fixture.
library;

/// A sender that is only digits and as long as a mobile number belongs to a
/// person, not to a bank: banks and services reach subscribers from short
/// codes or from alphanumeric sender names, which a private line cannot use.
bool isPersonalNumber(String sender) {
  final value = sender.replaceAll(RegExp(r'[\s()\-+]'), '');
  if (value.isEmpty || !RegExp(r'^\d+$').hasMatch(value)) return false;
  return value.length >= 10;
}
