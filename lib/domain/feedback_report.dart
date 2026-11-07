import '../data/services/message_store.dart';

/// Turns the corrections a user marked into text they can read and hand over.
///
/// Nothing here sends anything. The report is built so the user can see
/// exactly what it contains — the message text included — and then decide
/// whether to share it at all. That is the whole privacy design: Qorgan never
/// uploads a message, and a correction only leaves the phone by a deliberate
/// act of the person who owns it.
///
/// This is the only route by which the detector can learn about Kazakhstani
/// phishing: global blocklists barely cover it (see docs/blocklist.md), so
/// real corrections are the corpus the rule has to be measured against.
String buildFeedbackReport(List<StoredMessage> messages, {DateTime? at}) {
  final marked = messages
      .where((record) => record.feedback != MessageFeedback.none)
      .toList();
  if (marked.isEmpty) return '';

  final lines = <String>[
    'Qorğan — исправления к проверке SMS',
    'Отмечено сообщений: ${marked.length}.'
        ' Дата отчёта: ${_day(at ?? DateTime.now())}.',
    '',
    'Ниже полный текст отмеченных SMS и то, как их оценило приложение.'
        ' Отправляйте только если согласны поделиться этим текстом.',
    '',
  ];

  for (var i = 0; i < marked.length; i++) {
    final record = marked[i];
    lines.addAll([
      '--- ${i + 1} / ${marked.length} ---',
      'Пользователь: ${_feedbackLabel(record.feedback)}',
      'Qorğan: ${record.verdict.risk.name}, '
          'score ${record.verdict.score}'
          '${record.verdict.signals.isEmpty ? '' : ', признаки: '
                    '${record.verdict.signals.map((s) => s.name).join(', ')}'}',
      'Отправитель: ${record.message.sender.trim().isEmpty ? '—' : record.message.sender}',
      'Получено: ${_day(DateTime.fromMillisecondsSinceEpoch(record.message.timestamp))}',
      'Текст: ${record.message.body}',
      '',
    ]);
  }

  return lines.join('\n');
}

String _feedbackLabel(MessageFeedback feedback) => switch (feedback) {
  MessageFeedback.wrong => 'это не мошенничество (ложная тревога)',
  MessageFeedback.fraud => 'это мошенничество',
  MessageFeedback.none => '—',
};

String _day(DateTime at) =>
    '${at.year}-${_two(at.month)}-${_two(at.day)} ${_two(at.hour)}:${_two(at.minute)}';

String _two(int value) => value.toString().padLeft(2, '0');
