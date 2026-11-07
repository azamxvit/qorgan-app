/// Everything about where a link in a message points.
///
/// This module owns the whole notion of "what does this link point at": the
/// phishing blocklist plugs in here, and nothing else in the rule needs to
/// learn about it. Mirrored in Swift for the iOS message filter extension.
library;

/// Hosts a bank may legitimately link to. A missing entry turns a real bank
/// message into a false warning, so the list has to stay complete — verify it
/// against each bank and serve it remotely before release.
const officialHosts = {
  'kaspi.kz',
  'halykbank.kz',
  'halyk.kz',
  'homebank.kz',
  'bankffin.kz',
  'jusan.kz',
  'forte.kz',
  'bcc.kz',
  'eubank.kz',
  'nurbank.kz',
  'otbasybank.kz',
};

/// Top-level domains seen in Kazakhstani SMS, legitimate and otherwise. Used
/// only for hosts written without a scheme, so an unusual ending never hides a
/// link that spells out `http`.
const _bareHostTlds =
    'kz|ru|com|net|org|info|xyz|top|online|site|click|link|app|me|ly|su|cc|io'
    '|biz|pro|shop|store|live|icu|win';

final _schemedHost = RegExp(r'https?://([^\s/?#]+)');

/// Phishing SMS usually omit the scheme, so a host must also be recognised on
/// its own. Labels are ASCII, which keeps Cyrillic sentences from matching,
/// and the lookbehind keeps an email domain from reading as a link.
final _bareHost = RegExp(
  '(?<![a-z0-9@.\\-])((?:[a-z0-9][a-z0-9-]*\\.)+(?:$_bareHostTlds))'
  r'(?![a-z0-9-])',
);

/// Hosts named by the text, with userinfo and port removed.
Iterable<String> linkedHosts(String text) => [
  ..._schemedHost.allMatches(text).map((match) => match.group(1)!),
  ..._bareHost.allMatches(text).map((match) => match.group(1)!),
].map((host) => host.split('@').last.split(':').first);

/// A bank's own host, including its subdomains. Suffix matching is what makes
/// `kaspi.kz.verify.ru` fail the check while `app.kaspi.kz` passes it.
bool isOfficialHost(String host) =>
    officialHosts.any((name) => host == name || host.endsWith('.$name'));
