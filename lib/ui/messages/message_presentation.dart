import '../../data/services/message_store.dart';
import '../../domain/models/message_verdict.dart';

const signalWeights = {
  MessageSignal.bank: 1,
  MessageSignal.urgency: 2,
  MessageSignal.pressure: 2,
  MessageSignal.secret: 3,
  MessageSignal.unofficialLink: 3,
};
const signalNames = {
  MessageSignal.bank: 'Банк',
  MessageSignal.urgency: 'Срочность',
  MessageSignal.pressure: 'Давление',
  MessageSignal.secret: 'Код',
  MessageSignal.unofficialLink: 'Ссылка',
};
const signalReasons = {
  MessageSignal.bank: 'Сообщение ссылается на банк',
  MessageSignal.urgency: 'Торопят с решением',
  MessageSignal.pressure: 'Угрожают ограничить доступ',
  MessageSignal.secret: 'Просят код или подтверждение',
  MessageSignal.unofficialLink: 'Ссылка ведёт на другой сайт',
};

String senderName(StoredMessage record) {
  final sender = record.message.sender.trim();
  if (sender.toLowerCase().contains('kaspi')) return 'Kaspi Bank';
  if (sender.toLowerCase().contains('halyk')) return 'Halyk Bank';
  if (sender.isEmpty) return 'Неизвестный отправитель';
  return sender;
}

String messageTitle(StoredMessage record) {
  final text = record.message.body.toLowerCase();
  if (text.contains('поступ')) return 'Поступление на счёт';
  if (record.verdict.signals.contains(MessageSignal.secret)) {
    return 'Подтвердите доступ';
  }
  if (record.verdict.signals.contains(MessageSignal.pressure)) {
    return 'Ограничение по счёту';
  }
  if (record.verdict.signals.contains(MessageSignal.unofficialLink)) {
    return 'Ссылка в сообщении';
  }
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
