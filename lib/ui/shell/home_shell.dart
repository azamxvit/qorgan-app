import 'package:flutter/material.dart';

import '../../data/repositories/protection_repository.dart';
import '../../data/services/incoming_message_service.dart';
import '../../data/services/message_store.dart';
import '../../data/services/onboarding_settings.dart';
import '../../domain/feedback_report.dart';
import '../core/light_components.dart';
import '../guard/view_models/guard_view_model.dart';
import '../guard/widgets/feedback_report_page.dart';
import '../guard/widgets/settings_page.dart';
import '../guard/widgets/setup_page.dart';
import '../launch/launch_splash.dart';
import '../launch/welcome_page.dart';
import '../messages/sms_pages.dart';
import '../sms/view_models/sms_view_model.dart';
import '../sms/widgets/sms_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.repository,
    required this.incomingMessages,
    this.onboarding,
    super.key,
  });
  final ProtectionRepository repository;
  final IncomingMessageService incomingMessages;
  final OnboardingSettings? onboarding;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  late final GuardViewModel _guard = GuardViewModel(
    repository: widget.repository,
    incomingMessages: widget.incomingMessages,
  );
  late final SmsViewModel _sms = SmsViewModel(repository: widget.repository);
  late final OnboardingSettings _onboarding =
      widget.onboarding ?? MemoryOnboardingSettings();
  bool _showSplash = true;
  bool _welcome = false;
  bool _starting = false;
  bool _interacted = false;
  bool _openedNotification = false;
  int _notificationGeneration = 0;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.incomingMessages.onOpenMessage = _openNotification;
    _initialize();
  }

  Future<void> _initialize() async {
    await _guard.refresh();
    if (!mounted) return;
    if (!_openedNotification) {
      await _readNotification(initial: true);
    }
    if (!mounted || _openedNotification || _interacted) return;
    try {
      final completed = await _onboarding.readCompleted();
      final savedSetting = await widget.repository.hasSavedProtectionSetting();
      final existing = savedSetting || _guard.messages.isNotEmpty;
      if (!mounted || _openedNotification || _interacted) return;
      if (existing && !completed) await _onboarding.writeCompleted();
      if (mounted && !_openedNotification && !_interacted) {
        setState(() => _welcome = !completed && !existing);
      }
    } catch (_) {
      if (mounted && !_openedNotification && !_interacted) {
        setState(() => _welcome = true);
      }
    }
  }

  void _dismissSplash() {
    if (mounted && _showSplash) setState(() => _showSplash = false);
  }

  Future<void> _start({required bool setup}) async {
    if (_starting) return;
    setState(() => _starting = true);
    _interacted = true;
    try {
      await _onboarding.writeCompleted();
    } catch (_) {
      if (mounted) {
        _notice('Выбор не сохранился. Приветствие может появиться снова.');
      }
    }
    if (!mounted || _openedNotification) return;
    setState(() {
      _starting = false;
      _welcome = false;
      _tab = setup ? 0 : 1;
    });
    if (setup) _setup();
  }

  void _select(int index) {
    _interacted = true;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _tab = index);
  }

  Future<void> _openNotification() async {
    _openedNotification = true;
    await _readNotification();
    await _guard.refresh();
  }

  Future<void> _readNotification({bool initial = false}) async {
    final generation = ++_notificationGeneration;
    try {
      final record = await widget.incomingMessages.openedMessage();
      if (!mounted || generation != _notificationGeneration) return;
      if (initial &&
          record == null &&
          !widget.incomingMessages.hasNotificationSelection) {
        return;
      }
      _openedNotification = true;
      _notificationRoot();
      if (record != null) {
        _detail(record);
      } else {
        _missingMessage();
      }
    } catch (_) {
      if (!mounted || generation != _notificationGeneration) return;
      if (initial && !widget.incomingMessages.hasNotificationSelection) return;
      _openedNotification = true;
      _notificationRoot();
      _missingMessage(failed: true);
    }
  }

  void _notificationRoot() {
    _dismissSplash();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {
      _welcome = false;
      _tab = 0;
    });
  }

  void _missingMessage({bool failed = false}) => _push(
    PhonePage(
      header: _header(),
      children: [
        Text(
          failed
              ? 'Не удалось открыть сообщение'
              : 'Сообщение больше не хранится в Qorğan',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 18),
        Text(
          failed ? 'Попробуйте прочитать сохранённое сообщение ещё раз.' : 'В истории остаются последние 100 SMS. Запись могла быть удалена или заменена более новой.',
        ),
        const SizedBox(height: 24),
        if (failed)
          FilledButton(
            onPressed: _openNotification,
            child: const Text('Повторить'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            _select(2);
          },
          child: const Text('К сообщениям'),
        ),
      ],
    ),
  );

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

  void _back() => Navigator.of(context).maybePop();
  SmsHeader _header({bool root = false}) =>
      SmsHeader(onBack: _back, onMenu: () {}, onProfile: _settings, root: root);
  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _detail(StoredMessage record) => _push(
    SmsDetailPage(
      record: record,
      header: _header(),
      onSignals: () => _push(SignalsPage(record: record, header: _header())),
      onFeedback: (feedback) async {
        await widget.incomingMessages.recordFeedback(record.key, feedback);
        if (mounted) await _guard.refresh();
      },
    ),
  );

  void _setup() => _push(
    SetupPage(
      viewModel: _guard,
      header: _header(),
      onLater: _back,
      onDone: () {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        _select(0);
        _notice('Проверка новых SMS включена');
      },
    ),
  );

  void _info(bool privacy) => _push(
    LocalInfoPage(
      header: _header(),
      privacy: privacy,
      supported: _guard.access.supported,
    ),
  );

  void _settings() => _push(
    SettingsPage(
      viewModel: _guard,
      header: _header(),
      onSetup: _setup,
      onPrivacy: () => _info(true),
      onHelp: () => _info(false),
      onFeedbackReport: () => _push(
        FeedbackReportPage(
          header: _header(),
          loadReport: () async =>
              buildFeedbackReport(await widget.incomingMessages.recent()),
        ),
      ),
      onLicenses: () =>
          showLicensePage(context: context, applicationName: 'Qorğan'),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _welcome || _tab == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_welcome && _tab != 0) _select(0);
    },
    child: Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: _showSplash,
          child: AbsorbPointer(
            absorbing: _showSplash,
            child: ListenableBuilder(
              listenable: _guard,
              builder: (context, _) => _welcome
                  ? WelcomePage(
                      supported: _guard.access.supported,
                      busy: _starting,
                      revealed: !_showSplash,
                      onSetup: () => _start(setup: true),
                      onManual: () => _start(setup: false),
                      onPrivacy: () => _info(true),
                    )
                  : Scaffold(
                      resizeToAvoidBottomInset: false,
                      bottomNavigationBar:
                          MediaQuery.viewInsetsOf(context).bottom > 0
                          ? null
                          : QorganBottomBar(
                              selectedIndex: _tab,
                              onSelected: _select,
                            ),
                      body: IndexedStack(
                        index: _tab,
                        children: [
                          ProtectionDashboard(
                            messages: _guard.messages,
                            header: _header(root: true),
                            onMessage: _detail,
                            onAll: () => _select(2),
                            onManual: () => _select(1),
                            onSettings: _setup,
                            active: _guard.active,
                            supported: _guard.access.supported,
                            viewModel: _guard,
                            showBottom: false,
                          ),
                          Scaffold(
                            body: SafeArea(
                              child: Column(
                                children: [
                                  _header(root: true),
                                  Expanded(
                                    child: SmsScreen(
                                      viewModel: _sms,
                                      active: _tab == 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          MessagesPage(
                            messages: _guard.messages,
                            header: _header(root: true),
                            onMessage: _detail,
                            onManual: () => _select(1),
                            historyError: _guard.historyError,
                            onRetry: _guard.refresh,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        if (_showSplash)
          LaunchSplash(
            key: const ValueKey('launch-splash'),
            holdMark: _welcome,
            onComplete: _dismissSplash,
          ),
      ],
    ),
  );
}
