import 'package:flutter/material.dart';

import '../../data/services/message_store.dart';
import '../core/colors.dart';
import '../core/light_components.dart';
import 'message_presentation.dart';
import '../../domain/models/message_verdict.dart';

class SmsDetailPage extends StatelessWidget {
  const SmsDetailPage({
    required this.record,
    required this.header,
    required this.onSignals,
    super.key,
  });
  final StoredMessage record;
  final SmsHeader header;
  final VoidCallback onSignals;
  @override
  Widget build(BuildContext context) {
    final signals = record.verdict.signals;
    return PhonePage(
      header: header,
      children: [
        Text(
          '${senderName(record)}\n${messageTitle(record)}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            SenderAvatar(name: senderName(record)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                senderName(record),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardHeading(
                title: 'Оценка',
                trailing: IconButton(
                  tooltip: 'Открыть признаки',
                  onPressed: onSignals,
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: QorganColors.muted,
                  ),
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    colors: [QorganColors.mint, QorganColors.signal],
                  ),
                ),
                child: Text(
                  '${record.verdict.block ? 'Подозрительно' : 'Можно пропустить'} · ${record.verdict.score}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: QorganColors.mintInk,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Банк',
                      value: signals.contains(MessageSignal.bank)
                          ? senderName(record)
                          : 'Не указан',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _Metric(
                      label: 'Срочность',
                      value: signals.contains(MessageSignal.urgency)
                          ? 'Есть'
                          : 'Нет',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Давление',
                      value: signals.contains(MessageSignal.pressure)
                          ? 'Есть'
                          : 'Нет',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _Metric(
                      label: 'Ссылка',
                      value: signals.contains(MessageSignal.unofficialLink)
                          ? 'Не официальный сайт'
                          : 'Чужих ссылок нет',
                      accent: signals.contains(MessageSignal.unofficialLink),
                    ),
                  ),
                ],
              ),
              if (signals.contains(MessageSignal.secret)) ...[
                const SizedBox(height: 12),
                Text(
                  'Код или подтверждение · +3',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          key: const ValueKey('open-signals'),
          onTap: onSignals,
          borderRadius: BorderRadius.circular(20),
          child: SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardHeading(
                  title: 'Признаки',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: QorganColors.muted,
                  ),
                ),
                const SizedBox(height: 15),
                if (signals.isEmpty)
                  Text(
                    'Подозрительных признаков не найдено',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                for (final signal in signals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: MintDot(size: 5),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            signalReasons[signal]!,
                            style: const TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          record.verdict.block
              ? 'Не открывайте ссылку. Проверьте в официальном приложении банка'
              : 'Признаков фишинга по нашему правилу нет',
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: QorganColors.muted,
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: const Text(
            'Текст SMS',
            style: TextStyle(fontSize: 12, color: QorganColors.muted),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                record.message.body,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.accent = false,
  });
  final String label;
  final String value;
  final bool accent;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: accent ? QorganColors.mint : QorganColors.ink,
          height: 1.4,
        ),
      ),
    ],
  );
}
