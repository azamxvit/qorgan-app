import 'models/message_verdict.dart';

const officialHosts = {
  'kaspi.kz',
  'halykbank.kz',
  'bankffin.kz',
  'jusan.kz',
  'forte.kz',
};

const _bankWords = [
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

final _linkPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

/// Client rule for an SMS. The phone decides; no remote module is called.
MessageVerdict inspectMessage(String raw) {
  final text = raw.toLowerCase();
  final signals = <MessageSignal>[];
  var score = 0;

  void add(MessageSignal signal, int weight, bool matched) {
    if (!matched) return;
    score += weight;
    signals.add(signal);
  }

  bool has(List<String> words) => words.any(text.contains);

  add(MessageSignal.bank, 1, has(_bankWords));
  add(MessageSignal.urgency, 2, has(_urgencyWords));
  add(MessageSignal.pressure, 2, has(_pressureWords));
  add(MessageSignal.secret, 3, has(_secretWords));
  add(MessageSignal.unofficialLink, 3, _hasUnofficialLink(text));

  return MessageVerdict(score: score, signals: signals);
}

bool _hasUnofficialLink(String text) {
  final links = _linkPattern.allMatches(text);
  if (links.isEmpty) return false;
  for (final link in links) {
    final host = Uri.tryParse(link.group(0)!)?.host.toLowerCase() ?? '';
    final official = officialHosts.any(
      (name) => host == name || host.endsWith('.$name'),
    );
    if (!official) return true;
  }
  return false;
}
