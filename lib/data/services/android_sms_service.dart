import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'incoming_message_processor.dart';
import 'incoming_message_service.dart';
import 'message_store.dart';
import 'protection_settings.dart';
import 'warning_notifier.dart';

IncomingSms _incoming(SmsMessage sms) => IncomingSms(
  sender: sms.address ?? '',
  body: sms.body ?? '',
  timestamp: sms.date ?? 0,
);

@pragma('vm:entry-point')
Future<void> onBackgroundSms(SmsMessage sms) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Each isolate owns its dependencies. No foreground/UI instances are used.
  final processor = IncomingMessageProcessor(
    settings: DeviceProtectionSettings(),
    store: SqliteMessageStore(),
    notifier: AndroidWarningNotifier(),
  );
  await processor.process(_incoming(sms));
}

class AndroidSmsService extends IncomingMessageService {
  AndroidSmsService({required this.settings});
  final ProtectionSettings settings;
  static const _platform = MethodChannel('kz.qorgan/protection');
  final _store = SqliteMessageStore();
  final _notifier = AndroidWarningNotifier();
  void Function(String)? _listener;
  bool _registered = false;
  bool _launchRead = false;
  String? _selectedKey;
  late final _processor = IncomingMessageProcessor(
    settings: settings,
    store: _store,
    notifier: _notifier,
  );

  Future<void> _register() async {
    if (_registered) return;
    await Telephony.instance.listenIncomingSms(
      onNewMessage: (sms) async {
        final record = await _processor.process(_incoming(sms));
        _selectedKey = null;
        if (record != null) _listener?.call(record.message.body);
      },
      onBackgroundMessage: onBackgroundSms,
    );
    _registered = true;
  }

  @override
  Future<ProtectionAccess> status() async {
    await _notifier.initialize(onTap: _onNotificationTap);
    if (!_launchRead) {
      final launch = await _notifier.plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _selectedKey = launch?.notificationResponse?.payload;
      }
      _launchRead = true;
    }
    final sms = await _platform.invokeMethod<bool>('smsGranted') == true;
    if (sms) await _register();
    return ProtectionAccess(
      supported: true,
      sms: sms,
      notifications: await _notifier.enabled(),
    );
  }

  @override
  Future<ProtectionAccess> requestAccess() async {
    await Telephony.instance.requestSmsPermissions;
    await _notifier.initialize(onTap: _onNotificationTap);
    await _notifier.android?.requestNotificationsPermission();
    return status();
  }

  Future<void> _notifyLatest() async {
    final record = await latest();
    if (record != null) _listener?.call(record.message.body);
  }

  void _onNotificationTap(String? key) {
    _selectedKey = key;
    if (onOpenMessage != null) {
      onOpenMessage!();
    } else {
      unawaited(_notifyLatest());
    }
  }

  @override
  Future<StoredMessage?> latest() async => _selectedKey == null
      ? _store.latest()
      : await _store.byKey(_selectedKey!) ?? await _store.latest();
  @override
  Future<List<StoredMessage>> recent() => _store.recent();
  @override
  Future<StoredMessage?> openedMessage() async =>
      _selectedKey == null ? null : _store.byKey(_selectedKey!);
  @override
  Future<void> openSettings() async =>
      _platform.invokeMethod<void>('openSettings');
  @override
  void listen(void Function(String text) onMessage) => _listener = onMessage;
  @override
  void dispose() => _listener = null; // Receiver registration survives screen disposal.
}
