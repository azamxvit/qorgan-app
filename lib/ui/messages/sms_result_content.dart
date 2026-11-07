import 'package:flutter/material.dart';

import '../../domain/models/message_verdict.dart';
import '../core/colors.dart';
import '../core/light_components.dart';
import 'message_presentation.dart';

/// Shared assessment of a stored SMS or a manual text snapshot.
/// SelectableText deliberately keeps links as text without launch actions.
class SmsResultContent extends StatelessWidget {
  const SmsResultContent({
    required this.text,
    required this.verdict,
    this.manual = false,
    this.onSignals,
    super.key,
  });
  final String text;
  final MessageVerdict verdict;
  final bool manual;
  final VoidCallback? onSignals;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (verdict.risk) {
      MessageRisk.warn => (
        QorganColors.dark,
        QorganColors.surface,
        Icons.warning_amber_rounded,
      ),
      MessageRisk.watch => (
        QorganColors.backdrop,
        QorganColors.mintInk,
        Icons.info_outline_rounded,
      ),
      MessageRisk.clear => (
        QorganColors.pale,
        QorganColors.ink,
        Icons.check_circle_outline_rounded,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: foreground),
              const SizedBox(height: 14),
              Text(
                riskLabel(verdict.risk),
                style: TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                switch (verdict.risk) {
                  MessageRisk.clear => 'По найденным признакам риск низкий. Это не подтверждает подлинность отправителя.',
                  MessageRisk.watch =>
                    'Есть признаки, на которые стоит обратить внимание.',
                  MessageRisk.warn =>
                    'Обнаружены признаки возможного мошенничества.',
                },
                style: TextStyle(fontSize: 14, height: 1.5, color: foreground),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Что делать', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final advice in _advice(verdict))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(advice),
          ),
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Почему такая оценка',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (verdict.signals.isEmpty)
                const Text('Подозрительных признаков не найдено.'),
              for (final signal in verdict.signals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: QorganColors.ink,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(signalReasons[signal]!)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Текст SMS', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SelectableText(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (manual) ...[
                const SizedBox(height: 14),
                Text(
                  'Проверен только текст; отправитель не проверялся',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          key: const ValueKey('assessment-details'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          title: const Text('Подробности оценки'),
          childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Баллы по правилу: ${verdict.score}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Это сумма найденных признаков, а не вероятность мошенничества.',
            ),
            const SizedBox(height: 12),
            for (final signal in verdict.signals)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${signalNames[signal]} · +${signalWeights[signal]}',
                ),
              ),
            if (onSignals != null)
              TextButton(
                key: const ValueKey('open-signals'),
                onPressed: onSignals,
                child: const Text('Все признаки'),
              ),
          ],
        ),
      ],
    );
  }
}

List<String> _advice(MessageVerdict verdict) => [
  if (verdict.signals.contains(MessageSignal.secret))
    'Не передавайте коды и пароли из SMS другим людям.',
  if (verdict.signals.contains(MessageSignal.unofficialLink) ||
      verdict.signals.contains(MessageSignal.blockedHost))
    'Не переходите по ссылке из сообщения. Откройте нужный сервис самостоятельно.',
  if (verdict.signals.contains(MessageSignal.payment) ||
      verdict.signals.contains(MessageSignal.prize))
    'Не переводите деньги и не оплачивайте получение приза без независимой проверки.',
  if (verdict.risk != MessageRisk.clear)
    'Не торопитесь. Проверьте обращение через официальный сайт, приложение или известный вам номер организации.'
  else
    'Если сообщение вызывает сомнения, проверьте его через известный вам канал связи.',
];
