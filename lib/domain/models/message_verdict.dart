/// Persisted by name in the message store, so values may only be appended and
/// never renamed: an older row must still resolve after an update.
enum MessageSignal {
  bank,
  urgency,
  pressure,
  secret,
  unofficialLink,
  impersonation,
  prize,
  payment,
  blockedHost,
}

/// What Qorgan does about a message.
///
/// Derived from the score, never stored: the `messages` table keeps `score`
/// and `signals` only, and it has no migration path for a new column.
enum MessageRisk {
  /// Nothing worth the user's attention.
  clear,

  /// Saved and marked in the list, but no notification. A borderline message
  /// costs the user a glance instead of an interruption.
  watch,

  /// Worth waking the phone for.
  warn,
}

class MessageVerdict {
  const MessageVerdict({required this.score, required this.signals});

  final int score;
  final List<MessageSignal> signals;

  MessageRisk get risk => switch (score) {
    >= 4 => MessageRisk.warn,
    >= 3 => MessageRisk.watch,
    _ => MessageRisk.clear,
  };

  /// The notification trigger. Only the warn state interrupts the user.
  bool get block => risk == MessageRisk.warn;

  static const clear = MessageVerdict(score: 0, signals: []);
}
