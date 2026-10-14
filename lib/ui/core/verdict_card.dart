import 'package:flutter/material.dart';

import '../../domain/models/message_verdict.dart';
import 'colors.dart';
import 'copy.dart';

class VerdictCard extends StatelessWidget {
  const VerdictCard({
    required this.title,
    required this.verdict,
    required this.blocked,
    super.key,
  });

  final String title;
  final MessageVerdict verdict;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final lines = verdict.signals.isEmpty
        ? const [AppCopy.noSignals]
        : [for (final signal in verdict.signals) AppCopy.signalText[signal]!];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: QorganColors.ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: QorganColors.ink.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title · ${verdict.score}',
              style: TextStyle(
                color: blocked ? QorganColors.signal : QorganColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in lines)
              Text(line, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
