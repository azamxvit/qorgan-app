import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/verdict_card.dart';
import '../view_models/guard_view_model.dart';

class GuardScreen extends StatelessWidget {
  const GuardScreen({required this.viewModel, super.key});

  final GuardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final verdict = viewModel.verdict;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Text(
              AppCopy.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppCopy.tagline,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Text(
              AppCopy.guardTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppCopy.guardBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  viewModel.busy ||
                      (!viewModel.access.supported && !viewModel.armed)
                  ? null
                  : viewModel.toggle,
              child: Text(
                viewModel.busy
                    ? 'Проверяем разрешения…'
                    : viewModel.armed
                    ? 'Выключить защиту'
                    : 'Включить защиту',
              ),
            ),
            const SizedBox(height: 12),
            Text(viewModel.active ? AppCopy.armed : AppCopy.disarmed),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Разрешения и работа в фоне'),
                    const SizedBox(height: 8),
                    Text(
                      viewModel.access.supported
                          ? 'Приём SMS: ${viewModel.access.sms ? "разрешён" : "не разрешён"}\nПредупреждения: ${viewModel.access.notifications ? "разрешены" : "не разрешены"}'
                          : 'Автоматический приём SMS доступен на Android. Ручная проверка работает без разрешений.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Анализ выполняется на телефоне. Сохраняются последние 100 принятых сообщений. Тексты не отправляются на сервер.',
                    ),
                    if (viewModel.access.supported)
                      TextButton(
                        onPressed: viewModel.openSettings,
                        child: const Text('Открыть настройки разрешений'),
                      ),
                    TextButton(
                      onPressed: viewModel.busy ? null : viewModel.refresh,
                      child: const Text('Проверить состояние'),
                    ),
                    TextButton(
                      onPressed: () => showLicensePage(
                        context: context,
                        applicationName: 'Qorgan',
                      ),
                      child: const Text('Лицензии open source'),
                    ),
                  ],
                ),
              ),
            ),
            if (viewModel.error != null) Text(viewModel.error!),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: viewModel.simulate,
              child: const Text(AppCopy.simulate),
            ),
            const SizedBox(height: 16),
            if (!viewModel.received)
              Text(
                AppCopy.waiting,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (viewModel.sender != null)
                    Text('Отправитель: ${viewModel.sender}'),
                  if (viewModel.message != null)
                    SelectableText(viewModel.message!),
                  const SizedBox(height: 12),
                  VerdictCard(
                    title: viewModel.blocked ? AppCopy.blocked : AppCopy.allow,
                    verdict: verdict!,
                    blocked: viewModel.blocked,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
