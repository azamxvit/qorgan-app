import '../../data/services/message_store.dart';
import '../../domain/models/message_verdict.dart';

export '../../domain/inspect_message.dart' show signalWeights;

String riskLabel(MessageRisk risk) => switch (risk) {
  MessageRisk.clear => 'Низкий риск',
  MessageRisk.watch => 'Стоит проверить',
  MessageRisk.warn => 'Подозрительное SMS',
};

const signalNames = {
  MessageSignal.bank: 'Банк',
  MessageSignal.urgency: 'Срочность',
  MessageSignal.pressure: 'Давление',
  MessageSignal.secret: 'Код',
  MessageSignal.unofficialLink: 'Ссылка',
  MessageSignal.impersonation: 'Отправитель',
  MessageSignal.prize: 'Выигрыш',
  MessageSignal.payment: 'Оплата',
  MessageSignal.blockedHost: 'Известный фишинг',
};
const signalReasons = {
  MessageSignal.bank: 'Сообщение ссылается на банк',
  MessageSignal.urgency: 'Торопят с решением',
  MessageSignal.pressure: 'Угрожают ограничить доступ',
  MessageSignal.secret: 'Просят код или подтверждение',
  MessageSignal.unofficialLink: 'Ссылка ведёт на другой сайт',
  MessageSignal.impersonation: 'Пишут от имени банка с обычного номера',
  MessageSignal.prize: 'Обещают приз или выплату',
  MessageSignal.payment: 'Просят заплатить или перевести',
  MessageSignal.blockedHost: 'Этот адрес уже отмечен как фишинговый',
};

/// Signals the screens list even when they did not fire, so the table keeps a
/// stable shape.
const _baselineRows = [
  MessageSignal.bank,
  MessageSignal.urgency,
  MessageSignal.pressure,
  MessageSignal.unofficialLink,
];

/// Rows for the signal screens: the baseline plus anything else the rule
/// found, so a warning is never shown without the reason behind it.
List<MessageSignal> signalRows(MessageVerdict verdict) => [
  for (final signal in MessageSignal.values)
    if (_baselineRows.contains(signal) || verdict.signals.contains(signal))
      signal,
];

/// The sender exactly as Android reported it. Mapping a sender to a bank name
/// would be a guess, and a guess here reads to the user as verification.
String senderName(StoredMessage record) {
  final sender = record.message.sender.trim();
  return sender.isEmpty ? 'Неизвестный отправитель' : sender;
}

/// Derived only from what the rule found. Reading the body for words like
/// "поступление" let a phishing message title itself as a normal transfer.
String messageTitle(StoredMessage record) {
  final signals = record.verdict.signals;
  if (signals.contains(MessageSignal.impersonation)) {
    return 'Пишут от имени банка';
  }
  if (signals.contains(MessageSignal.secret)) return 'Просят код';
  if (signals.contains(MessageSignal.pressure)) return 'Ограничение по счёту';
  if (signals.contains(MessageSignal.unofficialLink)) {
    return 'Ссылка в сообщении';
  }
  if (signals.contains(MessageSignal.prize)) return 'Обещают выигрыш';
  if (signals.contains(MessageSignal.payment)) return 'Просят оплатить';
  return 'Новое сообщение';
}

String shortDate(int timestamp) {
  if (timestamp == 0) return 'Дата не указана';
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  const months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];
  return '${date.day} ${months[date.month - 1]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
