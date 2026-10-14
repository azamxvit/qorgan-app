import 'package:flutter/material.dart';

import '../../data/services/message_store.dart';
import '../core/colors.dart';
import '../core/light_components.dart';
import 'message_presentation.dart';

enum SmsFilter { all, suspicious, normal }

class MessagesPage extends StatefulWidget {
  const MessagesPage({
    required this.messages,
    required this.header,
    required this.onMessage,
    required this.onManual,
    super.key,
  });
  final List<StoredMessage> messages;
  final SmsHeader header;
  final ValueChanged<StoredMessage> onMessage;
  final VoidCallback onManual;
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  var filter = SmsFilter.all;
  @override
  Widget build(BuildContext context) {
    final visible = widget.messages
        .where(
          (record) =>
              filter == SmsFilter.all ||
              (filter == SmsFilter.suspicious
                  ? record.verdict.block
                  : !record.verdict.block),
        )
        .toList();
    return PhonePage(
      header: widget.header,
      children: [
        Text('Сообщения', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 22),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in SmsFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: InkWell(
                    key: ValueKey('filter-${item.name}'),
                    onTap: () => setState(() => filter = item),
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: filter == item
                            ? QorganColors.mint
                            : QorganColors.surface,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: filter == item
                              ? QorganColors.mint
                              : QorganColors.line,
                        ),
                      ),
                      child: Text(
                        switch (item) {
                          SmsFilter.all => 'Все',
                          SmsFilter.suspicious => 'Подозрительные',
                          SmsFilter.normal => 'Обычные',
                        },
                        style: TextStyle(
                          fontSize: 11,
                          color: filter == item
                              ? QorganColors.mintInk
                              : QorganColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (visible.isEmpty)
          SurfaceCard(
            child: Text(
              'Сообщений пока нет',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final record in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => widget.onMessage(record),
              borderRadius: BorderRadius.circular(20),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${senderName(record)}\n${messageTitle(record)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        SenderAvatar(name: senderName(record), size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            senderName(record),
                            style: const TextStyle(
                              fontSize: 11,
                              color: QorganColors.muted,
                            ),
                          ),
                        ),
                        StatusPill(
                          suspicious: record.verdict.block,
                          label: record.verdict.block
                              ? 'Подозрительно'
                              : record.verdict.score > 1
                              ? 'Проверить'
                              : 'Пропущено',
                          check:
                              !record.verdict.block &&
                              record.verdict.score <= 1,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      shortDate(record.message.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: QorganColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.onManual,
          icon: const Icon(Icons.edit_outlined, size: 15),
          label: const Text('Проверить текст SMS'),
        ),
      ],
    );
  }
}
