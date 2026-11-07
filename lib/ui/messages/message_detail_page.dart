import 'package:flutter/material.dart';

import '../../data/services/message_store.dart';
import '../core/light_components.dart';
import 'message_presentation.dart';
import 'sms_result_content.dart';

class SmsDetailPage extends StatefulWidget {
  const SmsDetailPage({
    required this.record,
    required this.header,
    required this.onSignals,
    this.onFeedback,
    super.key,
  });
  final StoredMessage record;
  final SmsHeader header;
  final VoidCallback onSignals;
  final Future<void> Function(MessageFeedback)? onFeedback;

  @override
  State<SmsDetailPage> createState() => _SmsDetailPageState();
}

class _SmsDetailPageState extends State<SmsDetailPage> {
  late MessageFeedback _feedback = widget.record.feedback;
  bool _savingFeedback = false;
  String? _feedbackError;

  @override
  void didUpdateWidget(covariant SmsDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.key != widget.record.key ||
        oldWidget.record.feedback != widget.record.feedback) {
      _feedback = widget.record.feedback;
      _feedbackError = null;
    }
  }

  Future<void> _saveFeedback(MessageFeedback value) async {
    if (_savingFeedback || widget.onFeedback == null) return;
    final messageKey = widget.record.key;
    setState(() {
      _savingFeedback = true;
      _feedbackError = null;
    });
    try {
      await widget.onFeedback!(value);
      if (mounted && widget.record.key == messageKey) {
        setState(() => _feedback = value);
      }
    } catch (_) {
      if (mounted && widget.record.key == messageKey) {
        setState(
          () => _feedbackError =
              'Не удалось сохранить отметку. Попробуйте ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _savingFeedback = false);
    }
  }

  @override
  Widget build(BuildContext context) => PhonePage(
    header: widget.header,
    children: [
      Text(
        senderName(widget.record),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        shortDate(widget.record.message.timestamp),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 20),
      SmsResultContent(
        text: widget.record.message.body,
        verdict: widget.record.verdict,
        onSignals: widget.onSignals,
      ),
      if (_feedback != MessageFeedback.none || widget.onFeedback != null) ...[
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ваша оценка сообщения',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (_feedback != MessageFeedback.none)
                Semantics(
                  liveRegion: true,
                  child: Text(switch (_feedback) {
                    MessageFeedback.wrong =>
                      'Вы отметили: это не мошенничество',
                    MessageFeedback.fraud => 'Вы отметили: это мошенничество',
                    MessageFeedback.none => '',
                  }),
                )
              else ...[
                Text(
                  'Отметка сохраняется на устройстве.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _savingFeedback
                      ? null
                      : () => _saveFeedback(MessageFeedback.wrong),
                  child: const Text(
                    'Это не мошенничество',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _savingFeedback
                      ? null
                      : () => _saveFeedback(MessageFeedback.fraud),
                  child: const Text(
                    'Это мошенничество',
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_feedbackError != null) ...[
                  const SizedBox(height: 12),
                  Semantics(liveRegion: true, child: Text(_feedbackError!)),
                ],
              ],
            ],
          ),
        ),
      ],
    ],
  );
}
