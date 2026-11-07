import 'package:flutter/material.dart';

import '../../core/light_components.dart';
import 'settings_page.dart';

/// Only the explicit agreement returns true. Back and decline never consent.
class SmsDisclosurePage extends StatelessWidget {
  const SmsDisclosurePage({super.key});

  @override
  Widget build(BuildContext context) => PhonePage(
    header: SmsHeader(
      onBack: () => Navigator.pop(context),
      onMenu: () {},
      onProfile: () {},
    ),
    children: [
      Semantics(
        header: true,
        child: Text(
          'Доступ к новым SMS',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Qorğan получает текст и отправителя новых входящих SMS, '
        'чтобы искать признаки фишинга и предупреждать о подозрительных сообщениях.',
      ),
      const SizedBox(height: 16),
      const Text(
        'После того как вы включите защиту, проверка работает в фоне, '
        'в том числе когда приложение не открыто. '
        'Анализ выполняется на вашем устройстве.',
      ),
      const SizedBox(height: 16),
      const Text(
        'Qorğan хранит последние 100 принятых SMS локально на телефоне: '
        'текст, отправителя, время получения и результат проверки. '
        'Историю можно удалить в настройках Qorğan.',
      ),
      const SizedBox(height: 16),
      const Text(
        'Qorğan не отправляет автоматически текст SMS и отправителя '
        'на сервер или другим людям.',
      ),
      const SizedBox(height: 16),
      const Text(
        'Старую переписку в приложении сообщений Qorğan не читает. '
        'Ручная проверка доступна без разрешения на SMS.',
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => LocalInfoPage(
              header: SmsHeader(
                onBack: () => Navigator.pop(context),
                onMenu: () {},
                onProfile: () {},
              ),
              privacy: true,
              supported: true,
            ),
          ),
        ),
        child: const Text(
          'Политика конфиденциальности',
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Если вы согласны с этим использованием SMS, продолжите к запросу '
        'разрешения Android. При первой настройке затем нажмите '
        '«Включить защиту» на экране настройки. Если защита уже была включена, '
        'предоставление доступа восстановит проверку.',
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Согласен, разрешить приём SMS',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Не сейчас'),
      ),
    ],
  );
}
