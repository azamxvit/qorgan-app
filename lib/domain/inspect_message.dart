import 'models/message_verdict.dart';
import 'signals/link_signals.dart';
import 'signals/sender_signals.dart';

export 'signals/link_signals.dart' show officialHosts;

const _bankWords = [
  // Callers who impersonate a bank often avoid naming one, so the generic
  // words carry the claim too.
  'банк',
  'bank',
  'kaspi',
  'каспи',
  'halyk',
  'халык',
  'jusan',
  'freedom',
  'forte',
  'bcc',
];

const _urgencyWords = ['срочно', 'шұғыл', 'минут', 'жедел'];

const _pressureWords = ['заблок', 'бұғат', 'штраф'];

const _secretWords = ['код', 'пароль', 'растау', 'подтверд'];

/// A promised win or payout: the hook of a scam that has nothing to threaten.
const _prizeWords = [
  'поздравля',
  'құттықта',
  'выиграл',
  'выигрыш',
  'компенсац',
];

/// A request to hand over money. Harmless on its own — shops ask it too — so
/// it only matters next to another signal.
const _paymentWords = [
  'оплатите',
  'оплати ',
  'переведи',
  'перевести',
  'төлеңіз',
  'аударыңыз',
];

/// A message that carries a code states its digits. A message that asks for a
/// code cannot: the sender does not know it yet.
final _codeDelivery = RegExp(r'(код|пароль|code)[^\d]{0,24}\d{3,8}');

/// Weight each signal adds to the score. The signal screens read this same
/// table, so a changed weight cannot disagree with the breakdown shown to the
/// user.
const signalWeights = {
  MessageSignal.bank: 1,
  MessageSignal.urgency: 2,
  MessageSignal.pressure: 2,
  MessageSignal.secret: 3,
  MessageSignal.unofficialLink: 3,
  MessageSignal.impersonation: 3,
  MessageSignal.prize: 2,
  MessageSignal.payment: 2,
  // A host already reported for phishing is evidence on its own, so this
  // weight alone reaches the warn threshold.
  MessageSignal.blockedHost: 4,
};

/// Client rule for an SMS. The phone decides; no remote module is called.
///
/// [sender] is empty for a message pasted by hand, which simply leaves the
/// sender signals unused rather than counting them against the text.
///
/// [blockedHosts] are the hosts of *this* message already known for phishing,
/// looked up by the caller. Membership is exact: resolving a subdomain to its
/// blocked parent is the store's job, not the rule's. Keeping the lookup
/// outside leaves this function synchronous and pure — the SMS receiver has a
/// nine-second budget, and the Swift port has to behave identically.
MessageVerdict inspectMessage(
  String raw, {
  String sender = '',
  Set<String> blockedHosts = const {},
}) {
  final text = raw.toLowerCase();
  final signals = <MessageSignal>[];
  var score = 0;

  void add(MessageSignal signal, bool matched) {
    if (!matched) return;
    score += signalWeights[signal]!;
    signals.add(signal);
  }

  bool has(List<String> words) => words.any(text.contains);

  final claimsBank = has(_bankWords);
  add(MessageSignal.bank, claimsBank);
  add(MessageSignal.impersonation, claimsBank && isPersonalNumber(sender));
  add(MessageSignal.urgency, has(_urgencyWords));
  add(MessageSignal.pressure, has(_pressureWords));
  // A bank's own host is never suspicious, whatever the blocklist says. The
  // whitelist ships with the app and the blocklist is fetched, so letting the
  // fetched list win would make the update channel an attack vector.
  final foreignHosts = linkedHosts(text).where((host) => !isOfficialHost(host));
  final foreignLink = foreignHosts.isNotEmpty;
  final knownPhishing = foreignHosts.any(blockedHosts.contains);
  // A bank that sends a code names it and links only to itself. An attacker
  // who asks for a code cannot name it.
  final delivered = !foreignLink && _codeDelivery.hasMatch(text);
  add(MessageSignal.secret, has(_secretWords) && !delivered);
  add(MessageSignal.unofficialLink, foreignLink);
  add(MessageSignal.prize, has(_prizeWords));
  add(MessageSignal.payment, has(_paymentWords));
  add(MessageSignal.blockedHost, knownPhishing);

  return MessageVerdict(score: score, signals: signals);
}
