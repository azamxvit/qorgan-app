import 'package:flutter/material.dart';

import '../../data/services/message_store.dart';
import '../core/colors.dart';
import '../core/light_components.dart';
import 'message_presentation.dart';

class SignalsPage extends StatelessWidget {
  const SignalsPage({required this.record, required this.header, super.key});
  final StoredMessage record;
  final SmsHeader header;
  @override
  Widget build(BuildContext context) => PhonePage(
    header: header,
    children: [
      Text('Признаки', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text(senderName(record), style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 24),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusPill(risk: record.verdict.risk),
            const SizedBox(height: 18),
            Text(
              'Баллы по правилу: ${record.verdict.score}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Это сумма найденных признаков, а не вероятность мошенничества.',
              style: TextStyle(color: QorganColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 26),
      Text('Из чего сложилось', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 14),
      SurfaceCard(
        child: Column(
          children: [
            for (final signal in signalRows(record.verdict))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            signalNames[signal]!,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            record.verdict.signals.contains(signal)
                                ? signalReasons[signal]!
                                : 'Не обнаружено',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      record.verdict.signals.contains(signal)
                          ? '+${signalWeights[signal]}'
                          : '0',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: QorganColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
