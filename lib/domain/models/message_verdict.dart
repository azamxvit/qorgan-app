enum MessageSignal { bank, urgency, pressure, secret, unofficialLink }

class MessageVerdict {
  const MessageVerdict({required this.score, required this.signals});

  final int score;
  final List<MessageSignal> signals;

  bool get block => score >= 4;

  static const clear = MessageVerdict(score: 0, signals: []);
}
