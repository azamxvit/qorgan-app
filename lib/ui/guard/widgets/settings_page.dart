import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/light_components.dart';
import '../../core/privacy_config.dart';
import '../view_models/guard_view_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.viewModel,
    required this.header,
    required this.onSetup,
    required this.onPrivacy,
    required this.onHelp,
    required this.onLicenses,
    required this.onFeedbackReport,
    super.key,
  });
  final GuardViewModel viewModel;
  final SmsHeader header;
  final VoidCallback onSetup, onPrivacy, onHelp, onLicenses, onFeedbackReport;

  Future<void> _clear(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QorganColors.surface,
        title: const Text('Удалить историю?'),
        content: const Text(
          'Сохранённые SMS будут удалены из Qorğan. Сообщения в приложении SMS останутся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить историю'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    final cleared = await viewModel.clearHistory();
    if (context.mounted && cleared) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('История Qorğan очищена')));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final vm = viewModel;
      return PhonePage(
        header: header,
        children: [
          Text('Настройки', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          if (vm.access.supported || vm.armed) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Проверка новых SMS',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vm.statusError != null
                        ? 'Не удалось проверить состояние'
                        : vm.active
                        ? 'Проверка и предупреждения включены'
                        : vm.armed
                        ? 'Включена, но требуется доступ'
                        : 'Автопроверка выключена',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (vm.armed)
                    OutlinedButton(
                      onPressed: vm.busy ? null : vm.disable,
                      child: const Text('Выключить защиту'),
                    )
                  else
                    FilledButton(
                      onPressed: vm.busy ? null : onSetup,
                      child: const Text('Настроить защиту'),
                    ),
                  if (vm.armed && !vm.active)
                    TextButton(
                      onPressed: vm.busy ? null : onSetup,
                      child: const Text('Восстановить доступ'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Разрешения',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vm.statusError != null
                        ? 'Состояние доступа неизвестно'
                        : 'Новые SMS · ${vm.access.sms ? "разрешено" : "нужен доступ"}\n'
                              'Уведомления · ${vm.access.notifications ? "разрешено" : "нужен доступ"}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: vm.openSettings,
                    child: const Text('Открыть настройки Android'),
                  ),
                  TextButton(
                    onPressed: vm.busy ? null : vm.refresh,
                    child: const Text('Проверить состояние'),
                  ),
                ],
              ),
            ),
          ],
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(vm.error!),
            ),
          const SizedBox(height: 24),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _row(
                  'Отчёт об исправлениях',
                  Icons.rate_review_outlined,
                  onFeedbackReport,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _row('Как работает защита', Icons.shield_outlined, onHelp),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _row(
                  'Политика конфиденциальности',
                  Icons.lock_outline_rounded,
                  onPrivacy,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _row(
                  'Лицензии open source',
                  Icons.description_outlined,
                  onLicenses,
                ),
              ],
            ),
          ),
          if (vm.messages.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: vm.busy ? null : () => _clear(context),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Очистить историю'),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Qorğan · 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: QorganColors.muted, fontSize: 12),
          ),
        ],
      );
    },
  );

  Widget _row(String title, IconData icon, VoidCallback onTap) => Material(
    type: MaterialType.transparency,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class LocalInfoPage extends StatelessWidget {
  const LocalInfoPage({
    required this.header,
    required this.privacy,
    required this.supported,
    super.key,
  });
  final SmsHeader header;
  final bool privacy, supported;
  @override
  Widget build(BuildContext context) => PhonePage(
    header: header,
    children: [
      Semantics(
        header: true,
        child: Text(
          privacy ? 'Политика конфиденциальности' : 'Как работает защита',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      const SizedBox(height: 24),
      if (privacy) ...[
        _section(
          context,
          'Что обрабатывает Qorğan',
          'Qorğan помогает замечать признаки фишинга. При разрешённом доступе '
              'и включённой защите приложение получает текст, отправителя и время получения новых SMS. '
              'Текст и отправитель проверяются на вашем устройстве. '
              'Старую переписку в приложении сообщений Qorğan не читает. '
              'Ручная проверка доступна без разрешения на SMS.',
        ),
        _section(
          context,
          'Работа в фоне и ваш выбор',
          'После того как вы включите защиту, новые SMS проверяются и когда приложение не открыто. '
              'Выключить защиту можно в настройках Qorğan, а отозвать разрешение на SMS — '
              'в настройках Android. Это прекращает проверку новых входящих SMS, '
              'но не удаляет уже сохранённую историю.',
        ),
        _section(
          context,
          'Ваша история',
          'Qorğan хранит последние 100 принятых SMS локально: текст, отправителя, время получения, '
              'результат проверки и ваши отметки, если они есть. При поступлении новых SMS '
              'самые старые записи сверх этого лимита удаляются. У записей нет отдельного срока '
              'хранения по дням: они остаются до замены новыми, очистки истории или удаления данных приложения.',
        ),
        _section(
          context,
          'Управление данными',
          'Кнопка «Очистить историю» в настройках Qorğan удаляет сохранённые записи и их отметки. '
              'Это не удаляет SMS из приложения сообщений и не выключает защиту: '
              'новые SMS могут снова появиться в истории. Чтобы остановить накопление истории, '
              'выключите защиту.',
        ),
        _section(
          context,
          'Ручная проверка',
          'Введённый или вставленный текст и результат ручной проверки остаются в оперативной памяти '
              'и не сохраняются в историю. Черновик сохраняется при переключении разделов, '
              'но не после завершения процесса приложения. Его можно очистить в поле ввода. '
              'Буфер обмена читается только при вашем действии вставки.',
        ),
        _section(
          context,
          'Добровольные отметки и отчёт',
          'Отметки об ошибках проверки, если вы их добавляете, хранятся только на устройстве '
              'вместе с соответствующей записью. Отчёт об исправлениях формируется локально '
              'и может содержать полный текст SMS, отправителя, время получения, результат проверки '
              'и вашу отметку. Копирование или передача отчёта возможны только по вашему действию; '
              'автоматической отправки нет. Перед передачей проверьте его содержимое. '
              'Копии, которые вы передали в другие приложения или людям, не удаляются при очистке Qorğan.',
        ),
        _section(
          context,
          'Загрузка списка опасных адресов',
          'При запуске приложение может загрузить публичный список фишинговых адресов по HTTPS '
              'с malware-filter.gitlab.io. Список хранится на телефоне, и сравнение ссылок из SMS '
              'с ним выполняется локально. Запрос идёт по постоянному адресу: '
              'текст SMS, отправитель, ссылки из ваших сообщений и идентификаторы устройства '
              'в него не добавляются. Фоновый обработчик SMS к сети не обращается.',
        ),
        _section(
          context,
          'Что видит внешний хост',
          'При HTTPS-загрузке списка GitLab Pages записывает в журналы доступа ваш IP-адрес, '
              'время запроса и адрес посещённой страницы — в этом случае адрес файла списка. '
              'Согласно опубликованной политике GitLab (https://about.gitlab.com/privacy/), '
              'эти технические журналы хранятся 7 дней и затем удаляются по мере поступления новых записей. '
              'Это срок, заявленный провайдером; Qorğan не управляет журналами хостинга. '
              'Текст SMS, отправитель и идентификаторы устройства не добавляются в запрос. '
              'Содержимое SMS и отправитель автоматически '
              'не передаются ни этому хосту, ни разработчику Qorğan.',
        ),
        _section(
          context,
          'Без аккаунта и рекламы',
          'Аккаунт не нужен. Рекламы и аналитики нет. Qorğan не использует рекламные '
              'идентификаторы и не отправляет историю использования приложения.',
        ),
        _section(
          context,
          'Удаление приложения',
          'После удаления Qorğan его локальные данные удаляются. Резервное копирование SMS-истории средствами Android отключено.',
        ),
        if (qorganDeveloperName.trim().isNotEmpty)
          _section(
            context,
            'Разработчик',
            qorganDeveloperName.trim(),
            selectable: true,
          ),
        if (qorganSupportEmail.trim().isNotEmpty)
          _section(
            context,
            'Связь по вопросам конфиденциальности',
            qorganSupportEmail.trim(),
            selectable: true,
          ),
        if (hostedPrivacyUrl case final url?)
          _section(context, 'Политика на сайте', url, selectable: true),
      ] else ...[
        _section(
          context,
          'Оценка по признакам',
          'Qorğan ищет признаки возможного мошенничества: просьбы сообщить код, давление, подозрительные ссылки и другие сигналы. Оценка помогает обратить внимание на сообщение, но не подтверждает подлинность отправителя.',
        ),
        _section(
          context,
          'Что делает предупреждение',
          'Подозрительные SMS отмечаются в истории. Приложение не блокирует ссылки, не удаляет сообщения и не изменяет их доставку.',
        ),
        if (supported)
          _section(
            context,
            'Проверка новых SMS',
            'Разрешите приём SMS и уведомления, затем включите защиту. При отключении уведомлений проверка может продолжаться, но предупреждения не появятся.',
          ),
        if (supported)
          _section(
            context,
            'Ограничения Android',
            'Энергосбережение и ограничения производителя могут мешать предупреждениям. После системной «Принудительной остановки» откройте Qorğan вручную. Если предупреждения пропали, проверьте разрешения в настройках.',
          ),
        if (!supported)
          _section(
            context,
            'Ручная проверка',
            'На этом устройстве вставьте текст SMS в раздел «Проверить SMS». Доступ к сообщениям для этого не требуется.',
          ),
      ],
    ],
  );
  Widget _section(
    BuildContext context,
    String title,
    String body, {
    bool selectable = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        if (selectable)
          SelectableText(body, style: Theme.of(context).textTheme.bodyMedium)
        else
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}
