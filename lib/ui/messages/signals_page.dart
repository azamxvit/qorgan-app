import 'package:flutter/material.dart';

import '../../data/services/message_store.dart';
import '../core/colors.dart';
import '../core/light_components.dart';
import 'message_presentation.dart';
import '../../domain/models/message_verdict.dart';

class SignalsPage extends StatelessWidget {
  const SignalsPage({required this.record, required this.header, super.key});
  final StoredMessage record;
  final SmsHeader header;
  @override
  Widget build(BuildContext context) => PhonePage(
    header: header,
    children: [
      Text('Признаки', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 18),
      SurfaceCard(
        child: Row(
          children: [
            SenderAvatar(name: senderName(record), size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName(record),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    messageTitle(record),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeading(title: 'Оценка'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ScoreBar(value: record.verdict.score / 11, height: 8),
                ),
                const SizedBox(width: 15),
                Text(
                  '${record.verdict.score}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Из 11 баллов по нашему правилу',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Text('Из чего сложилось', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 14),
      SurfaceCard(
        child: Column(
          children: [
            for (final signal in [
              MessageSignal.bank,
              MessageSignal.urgency,
              MessageSignal.pressure,
              MessageSignal.unofficialLink,
              if (record.verdict.signals.contains(MessageSignal.secret))
                MessageSignal.secret,
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 78,
                      child: Text(
                        signalNames[signal]!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: QorganColors.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _ScoreBar(
                        value: record.verdict.signals.contains(signal)
                            ? signalWeights[signal]! / 3
                            : 0,
                        height: 3,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: record.verdict.signals.contains(signal)
                            ? QorganColors.mint
                            : QorganColors.canvas,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${record.verdict.signals.contains(signal) ? signalWeights[signal] : 0}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: QorganColors.mintInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SurfaceCard(child: SignalMatrix(record: record)),
    ],
  );
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.value, required this.height});
  final double value;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: height,
      color: QorganColors.mint,
      backgroundColor: QorganColors.line,
    ),
  );
}

class SignalMatrix extends StatelessWidget {
  const SignalMatrix({required this.record, super.key});
  final StoredMessage record;
  @override
  Widget build(BuildContext context) {
    const rows = [
      MessageSignal.bank,
      MessageSignal.urgency,
      MessageSignal.pressure,
      MessageSignal.unofficialLink,
    ];
    final selectedRow = rows.lastIndexWhere(
      (signal) => record.verdict.signals.contains(signal),
    );
    final selectedColumn = selectedRow < 0
        ? 0
        : signalWeights[rows[selectedRow]]!;
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 76),
            for (final label in ['Нет', '1', '2', '3'])
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: QorganColors.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (var row = 0; row < rows.length; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Text(
                    signalNames[rows[row]]!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: QorganColors.muted,
                    ),
                  ),
                ),
                for (var column = 0; column < 4; column++)
                  Expanded(
                    child: Container(
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: row == selectedRow && column == selectedColumn
                            ? QorganColors.mint
                            : QorganColors.canvas,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: row == selectedRow && column == selectedColumn
                          ? Text(
                              '${record.verdict.score}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: QorganColors.mintInk,
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
