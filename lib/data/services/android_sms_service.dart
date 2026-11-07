import 'package:another_telephony/telephony.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'blocklist_store.dart';
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
    // Read-only here. The list is refreshed in the foreground; a network round
    // trip would not fit the receiver's nine-second budget.
    blocklist: SqliteBlocklist(),
  );
  await processor.process(_incoming(sms));
}

class AndroidSmsService extends IncomingMessageService {
  AndroidSmsService({
    required this.settings,
    Blocklist? blocklist,
    SqliteMessageStore? store,
  }) : blocklist = blocklist ?? SqliteBlocklist(),
       _store = store ?? SqliteMessageStore();
  final ProtectionSettings settings;
  final Blocklist blocklist;
  static const _platform = MethodChannel('kz.qorgan/protection');
  final SqliteMessageStore _store;
  final _notifier = AndroidWarningNotifier();
  void Function(String)? _listener;
  bool _registered = false;
  bool _launchRead = false;
  bool _notificationSelected = false;
  String? _selectedKey;
  late final _processor = IncomingMessageProcessor(
    settings: settings,
    store: _store,
    notifier: _notifier,
    blocklist: blocklist,
  );

  Future<void> _register() async {
    if (_registered) return;
    await Telephony.instance.listenIncomingSms(
      onNewMessage: (sms) async {
        final record = await _processor.process(_incoming(sms));
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
        _notificationSelected = true;
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
  Future<ProtectionAccess> requestSmsAccess() async {
    final access = await status();
    if (access.sms) return access;
    if (await _platform.invokeMethod<bool>('canRequestSms') != true) {
      await openSettings();
      return status();
    }
    await _platform.invokeMethod<void>('noteSmsRequested');
    try {
      await Telephony.instance.requestSmsPermissions;
    } on PlatformException catch (error) {
      // Denial is a capability state, not a failure to determine the state.
      if (error.code != 'permission_denied') rethrow;
    }
    return status();
  }

  @override
  Future<ProtectionAccess> requestNotificationAccess() async {
    final access = await status();
    if (access.notifications) return access;
    if (await _platform.invokeMethod<bool>('canRequestNotifications') == true) {
      await _platform.invokeMethod<void>('noteNotificationsRequested');
      await _notifier.android?.requestNotificationsPermission();
    } else {
      // Older Android, permanent denial or a blocked warning channel.
      await _platform.invokeMethod<void>('openNotificationSettings');
    }
    return status();
  }

  void _onNotificationTap(String? key) {
    _notificationSelected = true;
    _selectedKey = key;
    onOpenMessage?.call();
  }

  /// The newest stored message, never the one a notification selected. The
  /// selection is answered by [openedMessage] alone, which returns null when
  /// the record is gone instead of substituting another SMS — attributing a
  /// warning to the wrong message is the worst thing this app can do, because
  /// the user reads that text to decide whom to trust.
  @override
  Future<StoredMessage?> latest() => _store.latest();

  @override
  bool get hasNotificationSelection => _notificationSelected;
  @override
  Future<List<StoredMessage>> recent() => _store.recent();
  @override
  Future<void> recordFeedback(String key, MessageFeedback feedback) =>
      _store.recordFeedback(key, feedback);
  @override
  Future<StoredMessage?> openedMessage() async =>
      _selectedKey == null ? null : _store.byKey(_selectedKey!);
  @override
  Future<void> clearHistory() async {
    final warnings = await _notifier.activeWarnings();
    // The keys are captured before the delete so a message arriving in the
    // middle is neither deleted nor stripped of its warning.
    final shown = await _store.recent();
    await _store.deleteKeys(shown.map((record) => record.key));
    await _notifier.cancelSnapshot(warnings);
    await _notifier.cancelFor(shown);
  }

  @override
  Future<void> openSettings() async =>
      _platform.invokeMethod<void>('openSettings');
  @override
  void listen(void Function(String text) onMessage) => _listener = onMessage;
  @override
  void dispose() => _listener = null; // Receiver registration survives screen disposal.
}
