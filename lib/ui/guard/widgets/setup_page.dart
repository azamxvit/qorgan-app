import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/light_components.dart';
import '../view_models/guard_view_model.dart';
import 'sms_disclosure_page.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({
    required this.viewModel,
    required this.header,
    required this.onDone,
    required this.onLater,
    super.key,
  });
  final GuardViewModel viewModel;
  final SmsHeader header;
  final VoidCallback onDone;
  final VoidCallback onLater;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  bool _disclosing = false;

  Future<void> _requestSmsAccess() async {
    if (_disclosing || widget.viewModel.busy) return;
    final setupRoute = ModalRoute.of(context);
    setState(() => _disclosing = true);
    try {
      final agreed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const SmsDisclosurePage()),
      );
      // A notification can replace setup while the disclosure is open.
      // Dismissal, a stale route, and returning from privacy are not consent.
      if (agreed == true && mounted && setupRoute?.isCurrent == true) {
        await widget.viewModel.requestSmsAccess();
      }
    } finally {
      if (mounted) setState(() => _disclosing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final vm = widget.viewModel;
      return PhonePage(
        header: widget.header,
        children: [
          Text(
            'Настройте защиту',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Два разрешения, чтобы замечать подозрительные сообщения вовремя.',
            style: TextStyle(color: QorganColors.muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          if (!vm.loaded)
            const Text('Проверяем разрешения…')
          else if (vm.statusError != null) ...[
            Text(vm.statusError!),
            TextButton(
              onPressed: vm.busy ? null : vm.refresh,
              child: const Text('Повторить'),
            ),
          ] else if (!vm.access.supported)
            const Text('На этом устройстве доступна ручная проверка SMS.')
          else ...[
            _PermissionStep(
              number: '01',
              title: 'Новые SMS',
              ready: vm.access.sms,
              description: 'Доступ нужен, чтобы проверять сообщения при получении. Старую переписку Qorğan не загружает.',
              button: 'Разрешить приём SMS',
              onPressed: vm.busy || _disclosing ? null : _requestSmsAccess,
            ),
            const SizedBox(height: 14),
            _PermissionStep(
              number: '02',
              title: 'Предупреждения',
              ready: vm.access.notifications,
              description: 'Уведомим, если найдём подозрительное сообщение. Текст SMS и коды не показываются в предупреждении.',
              button: 'Разрешить уведомления',
              onPressed: vm.busy || !vm.access.sms
                  ? null
                  : vm.requestNotificationAccess,
            ),
            const SizedBox(height: 22),
            if (vm.error != null) ...[
              Text(vm.error!, style: const TextStyle(color: QorganColors.ink)),
              const SizedBox(height: 10),
              TextButton(
                onPressed: vm.busy ? null : vm.openSettings,
                child: const Text('Открыть настройки Android'),
              ),
            ],
            if (vm.access.ready)
              FilledButton(
                onPressed: vm.busy
                    ? null
                    : () async {
                        final enabled = vm.armed || await vm.enable();
                        if (enabled &&
                            context.mounted &&
                            ModalRoute.of(context)?.isCurrent == true) {
                          widget.onDone();
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(vm.armed ? 'Готово' : 'Включить защиту'),
                ),
              ),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: vm.busy ? null : widget.onLater,
            child: const Text('Позже'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ручная проверка доступна без этих разрешений.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: QorganColors.muted),
          ),
        ],
      );
    },
  );
}

class _PermissionStep extends StatelessWidget {
  const _PermissionStep({
    required this.number,
    required this.title,
    required this.description,
    required this.button,
    required this.ready,
    required this.onPressed,
  });
  final String number, title, description, button;
  final bool ready;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              number,
              style: const TextStyle(fontSize: 13, color: QorganColors.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (ready)
              const Icon(
                Icons.check_circle_rounded,
                color: QorganColors.mintInk,
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        if (ready)
          const Text(
            'Разрешено',
            style: TextStyle(
              color: QorganColors.mintInk,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(button, textAlign: TextAlign.center),
              ),
            ),
          ),
      ],
    ),
  );
}
