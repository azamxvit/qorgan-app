import 'package:flutter/material.dart';

import '../../data/services/message_store.dart';
import '../../domain/models/message_verdict.dart';
import '../core/colors.dart';
import '../core/light_components.dart';
import '../guard/view_models/guard_view_model.dart';
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
    this.onManual,
    this.viewModel,
    this.showBottom = true,
    super.key,
  });
  final List<StoredMessage> messages;
  final SmsHeader header;
  final ValueChanged<StoredMessage> onMessage;
  final VoidCallback onAll;
  final VoidCallback onSettings;
  final VoidCallback? onManual;
  final bool active;
  final bool supported;
  final GuardViewModel? viewModel;
  final bool showBottom;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final receiving =
        active || (vm != null && vm.statusKnown && vm.armed && vm.access.sms);
    final loading =
        vm != null &&
        (!vm.loaded || (!vm.statusKnown && vm.statusError == null));
    final unknown = vm?.statusError != null;
    final missingSms = vm != null && vm.armed && !vm.access.sms;
    final missingAlerts =
        vm != null && vm.armed && vm.access.sms && !vm.access.notifications;
    final title = loading
        ? 'Проверяем состояние…'
        : unknown
        ? 'Не удалось проверить состояние'
        : !supported
        ? 'Проверяйте SMS вручную'
        : missingSms
        ? 'Нет доступа к новым SMS'
        : missingAlerts
        ? 'Предупреждения выключены'
        : active
        ? 'Проверка новых SMS включена'
        : 'Автопроверка выключена';
    final subtitle = loading
        ? 'Ручная проверка уже доступна.'
        : unknown
        ? 'Попробуйте обновить состояние защиты.'
        : !supported
        ? 'На этом устройстве доступна проверка текста сообщения.'
        : missingSms
        ? 'Восстановите доступ, чтобы проверять новые сообщения.'
        : missingAlerts
        ? 'Проверка новых SMS включена, уведомления недоступны.'
        : active
        ? 'Предупреждения о подозрительных сообщениях включены.'
        : 'Настройте проверку, чтобы получать предупреждения о подозрительных сообщениях.';
    return PhonePage(
      header: header,
      bottom: showBottom ? QorganBottomBar(onSms: onAll) : null,
      children: [
        Text('Защита', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: active ? QorganColors.backdrop : QorganColors.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: active ? QorganColors.mint : QorganColors.pale,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  active ? Icons.verified_user_outlined : Icons.shield_outlined,
                  color: active ? QorganColors.mintInk : QorganColors.ink,
                  size: 28,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: active ? QorganColors.mintInk : QorganColors.muted,
                ),
              ),
              if (!loading && !active && (supported || unknown)) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: vm?.busy == true
                      ? null
                      : unknown
                      ? vm?.refresh
                      : onSettings,
                  child: Text(
                    unknown
                        ? 'Повторить'
                        : missingSms
                        ? 'Восстановить доступ'
                        : missingAlerts
                        ? 'Включить уведомления'
                        : 'Настроить защиту',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: InkWell(
            onTap: onManual,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 28,
                    color: QorganColors.ink,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Проверить SMS',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Вставьте текст и узнайте, на что обратить внимание',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
        if (messages.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(
            'В сохранённой истории',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _count(context, '${messages.length}', 'проверено'),
              _count(
                context,
                '${messages.where((m) => m.verdict.risk == MessageRisk.warn).length}',
                'подозрительных',
              ),
            ],
          ),
        ],
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: Text(
                'Последние SMS',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              key: const ValueKey('open-messages'),
              onPressed: onAll,
              child: const Text('Все'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (vm?.historyError != null)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Не удалось загрузить сообщения'),
                TextButton(
                  onPressed: vm!.refresh,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          )
        else if (messages.isEmpty)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 24),
                const SizedBox(height: 14),
                Text(
                  'Новых SMS пока нет',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  receiving
                      ? 'Они появятся здесь после получения.'
                      : supported
                      ? 'Включите проверку новых SMS или проверьте текст вручную.'
                      : 'Проверить текст можно в разделе «Проверить SMS».',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          for (final record in messages.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: QorganColors.surface,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => onMessage(record),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                senderName(record),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shortDate(record.message.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        StatusPill(risk: record.verdict.risk),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _count(BuildContext context, String number, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: QorganColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$number  ',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          TextSpan(text: label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}
