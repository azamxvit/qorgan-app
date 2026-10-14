import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../data/services/message_store.dart';
import '../../domain/inspect_message.dart';
import '../core/colors.dart';
import '../core/light_components.dart';
import '../core/theme.dart';
import '../messages/sms_pages.dart';
import '../launch/launch_splash.dart';

List<StoredMessage> previewMessages() {
  final samples = [
    IncomingSms(
      sender: 'KASPI',
      body: 'Kaspi: Подтвердите код: https://verify-card.example/login',
      timestamp: DateTime(2026, 10, 14, 14, 5).millisecondsSinceEpoch,
    ),
    IncomingSms(
      sender: 'HALYK',
      body: 'Halyk Bank: Поступление 20 000 ₸',
      timestamp: DateTime(2026, 10, 14, 12, 42).millisecondsSinceEpoch,
    ),
    IncomingSms(
      sender: 'KASPI',
      body: 'Kaspi: Срочно подтвердите данные. Счёт заблокирован.',
      timestamp: DateTime(2026, 10, 14, 11, 30).millisecondsSinceEpoch,
    ),
    IncomingSms(
      sender: '1414',
      body: 'Срочно заберите документ в ЦОН.',
      timestamp: DateTime(2026, 10, 13, 16, 18).millisecondsSinceEpoch,
    ),
  ];
  return samples
      .map(
        (sms) => StoredMessage(message: sms, verdict: inspectMessage(sms.body)),
      )
      .toList();
}

class QorganPreviewApp extends StatelessWidget {
  const QorganPreviewApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Qorğan · светлый интерфейс',
    debugShowCheckedModeBanner: false,
    theme: qorganTheme(),
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const DesignPreview(),
  );
}

class DesignPreview extends StatelessWidget {
  const DesignPreview({this.boardKey, super.key});
  final GlobalKey? boardKey;
  @override
  Widget build(BuildContext context) {
    final messages = previewMessages();
    final record = messages.first;
    final header = SmsHeader(onBack: () {}, onMenu: () {}, onProfile: () {});
    final screens = [
      ProtectionDashboard(
        messages: messages,
        header: header,
        onMessage: (_) {},
        onAll: () {},
        onSettings: () {},
        active: true,
        supported: true,
      ),
      SmsDetailPage(record: record, header: header, onSignals: () {}),
      SignalsPage(record: record, header: header),
      MessagesPage(
        messages: messages,
        header: header,
        onMessage: (_) {},
        onManual: () {},
      ),
    ];
    return Scaffold(
      floatingActionButton: FilledButton.icon(
        key: const ValueKey('preview-launch'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _LaunchPreviewDialog(),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Посмотреть запуск'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [QorganColors.surface, QorganColors.backdrop],
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: RepaintBoundary(
              key: boardKey,
              child: Container(
                width: 1716,
                height: 932,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [QorganColors.surface, QorganColors.backdrop],
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 44,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < screens.length; i++) ...[
                      if (i > 0) const SizedBox(width: 28),
                      Container(
                        width: 390,
                        height: 844,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: QorganColors.ink.withValues(alpha: .08),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: MediaQuery(
                            data: const MediaQueryData(
                              size: Size(390, 844),
                              devicePixelRatio: 1,
                              textScaler: TextScaler.noScaling,
                            ),
                            child: screens[i],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchPreviewDialog extends StatefulWidget {
  const _LaunchPreviewDialog();
  @override
  State<_LaunchPreviewDialog> createState() => _LaunchPreviewDialogState();
}

class _LaunchPreviewDialogState extends State<_LaunchPreviewDialog> {
  bool _launching = true;
  int _replay = 0;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: SizedBox(
      width: 390,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProtectionDashboard(
                    messages: previewMessages(),
                    header: SmsHeader(
                      onBack: () {},
                      onMenu: () {},
                      onProfile: () {},
                    ),
                    onMessage: (_) {},
                    onAll: () {},
                    onSettings: () {},
                    active: true,
                    supported: true,
                  ),
                  if (_launching)
                    LaunchSplash(
                      key: ValueKey(_replay),
                      onComplete: () => setState(() => _launching = false),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => setState(() {
                  _replay++;
                  _launching = true;
                }),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Повторить'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
