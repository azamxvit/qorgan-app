import 'package:flutter/material.dart';

import '../../data/services/message_store.dart';
import '../../domain/models/message_verdict.dart';
import '../core/colors.dart';
import '../core/light_components.dart';
import 'message_presentation.dart';

enum SmsFilter { all, suspicious, watch, normal }

class MessagesPage extends StatefulWidget {
  const MessagesPage({
    required this.messages,
    required this.header,
    required this.onMessage,
    required this.onManual,
    this.historyError,
    this.onRetry,
    super.key,
  });
  final List<StoredMessage> messages;
  final SmsHeader header;
  final ValueChanged<StoredMessage> onMessage;
  final VoidCallback onManual;
  final String? historyError;
  final VoidCallback? onRetry;
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  var filter = SmsFilter.all;

  @override
  Widget build(BuildContext context) {
    final visible = widget.messages
        .where(
          (record) => switch (filter) {
            SmsFilter.all => true,
            SmsFilter.suspicious => record.verdict.risk == MessageRisk.warn,
            SmsFilter.watch => record.verdict.risk == MessageRisk.watch,
            SmsFilter.normal => record.verdict.risk == MessageRisk.clear,
          },
        )
        .toList();
    return PhonePage(
      header: widget.header,
      children: [
        Text('Сообщения', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Последние 100 входящих SMS. Ручные проверки сюда не добавляются.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in SmsFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Semantics(
                    selected: filter == item,
                    child: OutlinedButton(
                      key: ValueKey('filter-${item.name}'),
                      onPressed: () => setState(() => filter = item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: filter == item
                            ? QorganColors.mintInk
                            : QorganColors.ink,
                        backgroundColor: filter == item
                            ? QorganColors.backdrop
                            : QorganColors.surface,
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(switch (item) {
                        SmsFilter.all => 'Все',
                        SmsFilter.suspicious => 'Подозрительные',
                        SmsFilter.watch => 'Стоит проверить',
                        SmsFilter.normal => 'Низкий риск',
                      }),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (widget.historyError != null)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Не удалось загрузить сообщения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Попробуйте ещё раз. Ручная проверка остаётся доступной.',
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: widget.onRetry,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          )
        else if (widget.messages.isEmpty)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Входящих SMS пока нет',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                  'После настройки защиты здесь появятся новые полученные SMS. Старую переписку Qorğan не загружает.',
                ),
              ],
            ),
          )
        else if (visible.isEmpty)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Сообщений с такой оценкой нет'),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() => filter = SmsFilter.all),
                  child: const Text('Показать все'),
                ),
              ],
            ),
          ),
        if (widget.historyError == null)
          for (final record in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                button: true,
                child: InkWell(
                  key: ValueKey('message-${record.key}'),
                  onTap: () => widget.onMessage(record),
                  borderRadius: BorderRadius.circular(20),
                  child: SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          senderName(record),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shortDate(record.message.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Text(messageTitle(record)),
                        const SizedBox(height: 14),
                        StatusPill(risk: record.verdict.risk),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: widget.onManual,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Проверить SMS вручную'),
        ),
      ],
    );
  }
}
