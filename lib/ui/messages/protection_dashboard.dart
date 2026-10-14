import 'package:flutter/material.dart';

import '../../data/services/message_store.dart';
import '../core/colors.dart';
import '../core/light_components.dart';
import 'message_presentation.dart';

class ProtectionDashboard extends StatelessWidget {
  const ProtectionDashboard({
    required this.messages,
    required this.header,
    required this.onMessage,
    required this.onAll,
    required this.onSettings,
    required this.active,
    required this.supported,
    super.key,
  });
  final List<StoredMessage> messages;
  final SmsHeader header;
  final ValueChanged<StoredMessage> onMessage;
  final VoidCallback onAll;
  final VoidCallback onSettings;
  final bool active;
  final bool supported;
  @override
  Widget build(BuildContext context) {
    final suspicious = messages.where((m) => m.verdict.block).length;
    final normal = messages.length - suspicious;
    return PhonePage(
      header: header,
      bottom: QorganBottomBar(onSms: onAll),
      children: [
        _DashboardTitle(active: active, onSettings: onSettings),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'Проверено', value: messages.length),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(label: 'Подозрительные', value: suspicious),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CountPill(
                label: 'Можно пропустить',
                count: normal,
                mint: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CountPill(label: 'Подозрительно', count: suspicious),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              'Последние SMS',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(
              key: const ValueKey('open-messages'),
              onPressed: onAll,
              child: const Row(
                children: [
                  Text('Все', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 5),
                  Icon(Icons.tune_rounded, size: 15),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (messages.isEmpty)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Пока нет сообщений',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  supported
                      ? 'Новые SMS появятся здесь'
                      : 'Проверьте текст на вкладке SMS',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < messages.take(4).length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, thickness: 1),
                    ),
                  _RecentRow(
                    record: messages[i],
                    onTap: () => onMessage(messages[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w500,
            letterSpacing: -1.8,
            height: 1.05,
          ),
        ),
      ],
    ),
  );
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.count,
    this.mint = false,
  });
  final String label;
  final int count;
  final bool mint;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    decoration: BoxDecoration(
      color: QorganColors.surface,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: mint ? QorganColors.mintInk : QorganColors.ink,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: mint ? QorganColors.mint : QorganColors.ink,
          ),
        ),
      ],
    ),
  );
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.record, required this.onTap});
  final StoredMessage record;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (record.verdict.block) ...[
            const MintDot(size: 5),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName(record),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: QorganColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        shortDate(record.message.timestamp),
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 10,
                          color: QorganColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          StatusPill(suspicious: record.verdict.block, compact: true),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 15,
            color: QorganColors.muted,
          ),
        ],
      ),
    ),
  );
}

class _DashboardTitle extends StatelessWidget {
  const _DashboardTitle({required this.active, required this.onSettings});
  final bool active;
  final VoidCallback onSettings;
  @override
  Widget build(BuildContext context) {
    final title = Text(
      'Защита',
      style: Theme.of(context).textTheme.headlineMedium,
    );
    final status = InkWell(
      onTap: onSettings,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? QorganColors.mint : QorganColors.line,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              active ? 'Включена' : 'Настроить',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
    if (MediaQuery.textScalerOf(context).scale(28) > 40) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 8), status],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        status,
      ],
    );
  }
}
