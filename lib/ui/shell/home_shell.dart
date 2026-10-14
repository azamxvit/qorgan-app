import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/protection_repository.dart';
import '../../data/services/incoming_message_service.dart';
import '../../data/services/message_store.dart';
import '../core/copy.dart';
import '../core/light_components.dart';
import '../core/colors.dart';
import '../guard/view_models/guard_view_model.dart';
import '../messages/sms_pages.dart';
import '../launch/launch_splash.dart';
import '../sms/view_models/sms_view_model.dart';
import '../sms/widgets/sms_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.repository,
    required this.incomingMessages,
    super.key,
  });
  final ProtectionRepository repository;
  final IncomingMessageService incomingMessages;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  late final GuardViewModel _guard = GuardViewModel(
    repository: widget.repository,
    incomingMessages: widget.incomingMessages,
    sample: AppCopy.phishingText,
  );
  late final SmsViewModel _sms = SmsViewModel(repository: widget.repository);
  bool _openedLaunch = false;
  bool _showSplash = true;

  void _dismissSplash() {
    if (mounted && _showSplash) setState(() => _showSplash = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.incomingMessages.onOpenMessage = _openNotification;
    _initialize();
  }

  Future<void> _initialize() async {
    await _guard.refresh();
    final record = await widget.incomingMessages.openedMessage();
    if (mounted && record != null && !_openedLaunch) {
      _dismissSplash();
      _openedLaunch = true;
      _detail(record);
    }
  }

  Future<void> _openNotification() async {
    await _guard.refresh();
    final record = await widget.incomingMessages.latest();
    if (mounted && record != null) {
      _dismissSplash();
      Navigator.of(context).popUntil((route) => route.isFirst);
      _detail(record);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _guard.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.incomingMessages.onOpenMessage = null;
    _guard.dispose();
    _sms.dispose();
    super.dispose();
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (Theme.of(context).platform == TargetPlatform.android) {
      SystemNavigator.pop();
    }
  }

  SmsHeader get _header =>
      SmsHeader(onBack: _back, onMenu: _menu, onProfile: _settings);
  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  void _detail(StoredMessage record) => _push(
    SmsDetailPage(
      record: record,
      header: _header,
      onSignals: () => _push(SignalsPage(record: record, header: _header)),
    ),
  );
  void _all() => _push(
    ListenableBuilder(
      listenable: _guard,
      builder: (_, _) => MessagesPage(
        messages: _guard.messages,
        header: _header,
        onMessage: _detail,
        onManual: _manual,
      ),
    ),
  );
  void _manual() => _push(
    Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header,
            Expanded(child: SmsScreen(viewModel: _sms)),
          ],
        ),
      ),
    ),
  );
  void _menu() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: QorganColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sms_outlined),
              title: const Text('Сообщения'),
              onTap: () {
                Navigator.pop(sheet);
                _all();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Проверить текст SMS'),
              onTap: () {
                Navigator.pop(sheet);
                _manual();
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Настройки защиты'),
              onTap: () {
                Navigator.pop(sheet);
                _settings();
              },
            ),
          ],
        ),
      ),
    ),
  );
  void _settings() => _push(
    ListenableBuilder(
      listenable: _guard,
      builder: (_, _) => PhonePage(
        header: _header,
        children: [
          Text('Настройки', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _guard.active ? 'Защита включена' : 'Защита выключена',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Новые SMS проверяются на телефоне. Сохраняются последние 100 сообщений.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _guard.busy ||
                            (!_guard.access.supported && !_guard.armed)
                        ? null
                        : _guard.toggle,
                    child: Text(
                      _guard.busy
                          ? 'Проверяем…'
                          : _guard.armed
                          ? 'Выключить защиту'
                          : 'Включить защиту',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardHeading(title: 'Разрешения'),
                const SizedBox(height: 12),
                Text(
                  _guard.access.supported
                      ? 'SMS · ${_guard.access.sms ? "разрешено" : "нужен доступ"}\nУведомления · ${_guard.access.notifications ? "разрешено" : "нужен доступ"}'
                      : 'Автоматический приём доступен на Android',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_guard.access.supported)
                  TextButton(
                    onPressed: _guard.openSettings,
                    child: const Text('Открыть настройки Android'),
                  ),
                TextButton(
                  onPressed: _guard.busy ? null : _guard.refresh,
                  child: const Text('Проверить состояние'),
                ),
              ],
            ),
          ),
          if (_guard.error != null) ...[
            const SizedBox(height: 12),
            Text(_guard.error!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: _licenses,
            child: const Text('Лицензии open source'),
          ),
        ],
      ),
    ),
  );
  Future<void> _licenses() async {
    showLicensePage(context: context, applicationName: 'Qorğan');
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(
        excluding: _showSplash,
        child: AbsorbPointer(
          absorbing: _showSplash,
          child: ListenableBuilder(
            listenable: _guard,
            builder: (_, _) => ProtectionDashboard(
              messages: _guard.messages,
              header: _header,
              onMessage: _detail,
              onAll: _all,
              onSettings: _settings,
              active: _guard.active,
              supported: _guard.access.supported,
            ),
          ),
        ),
      ),
      if (_showSplash)
        Positioned.fill(
          child: LaunchSplash(
            key: const ValueKey('launch-splash'),
            onComplete: _dismissSplash,
          ),
        ),
    ],
  );
}
