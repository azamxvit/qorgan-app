import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import 'incoming_message_processor.dart';
import 'message_store.dart';

class AndroidWarningNotifier implements RemovableWarningNotifier {
  final plugin = FlutterLocalNotificationsPlugin();
  static const channelId = 'qorgan_sms_warnings';
  static const _title = 'Подозрительное SMS';
  static const _body =
      'Не сообщайте код и не открывайте ссылку. Проверьте сообщение в Qorgan.';
  static final _messageKey = RegExp(r'^[a-f0-9]{64}$');
  bool _initialized = false;
  AndroidFlutterLocalNotificationsPlugin? get android => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  Future<void> initialize({void Function(String?)? onTap}) async {
    if (_initialized) return;
    final initialized = await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_shield'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );
    if (initialized != true) {
      throw StateError('Warning notification initialization failed');
    }
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        'Предупреждения Qorgan',
        description: 'Подозрительные входящие SMS',
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  Future<bool> enabled() async {
    if (await android?.areNotificationsEnabled() != true) return false;
    final sdk = await const MethodChannel(
      'plugins.shounakmulay.com/foreground_sms_channel',
    ).invokeMethod<int>('sdkInt');
    if (sdk != null && sdk < 26) return true;
    final channels = await android?.getNotificationChannels();
    if (channels == null) return false;
    final channel = channels.where((c) => c.id == channelId).firstOrNull;
    return channel != null && channel.importance != Importance.none;
  }

  /// Snapshot before clearing, including warnings whose rows were evicted.
  Future<List<ActiveNotification>>
  activeWarnings() async => (await plugin.getActiveNotifications())
      .where((warning) {
        if (warning.id == null) return false;
        if (warning.channelId == channelId) return true;
        // Android before API 26 has no channels, and its active-notification
        // API omits the payload. Earlier builds also had no key tag.
        return warning.channelId == null &&
            (_messageKey.hasMatch(warning.tag ?? '') ||
                (warning.tag == null &&
                    warning.title == _title &&
                    warning.body == _body));
      })
      .toList(growable: false);

  Future<void> cancelSnapshot(Iterable<ActiveNotification> warnings) async {
    for (final warning in warnings) {
      final id = warning.id;
      if (id != null) await plugin.cancel(id: id, tag: warning.tag);
    }
  }

  /// Withdraws the warnings for exactly these records.
  ///
  /// Per-notification rather than `cancelAll` on purpose: an SMS that arrives
  /// while the user is clearing keeps its warning, because that record was
  /// never in the list they chose to delete.
  @override
  Future<void> cancelFor(Iterable<StoredMessage> records) async {
    for (final record in records) {
      await plugin.cancel(id: record.notificationId, tag: record.key);
      // Earlier app versions posted warnings without a tag.
      await plugin.cancel(id: record.notificationId);
    }
  }

  @override
  Future<void> show(StoredMessage record) async {
    await initialize();
    if (!await enabled()) throw StateError('Warning notifications disabled');
    await plugin.show(
      id: record.notificationId,
      title: _title,
      body: _body,
      payload: record.key,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Предупреждения Qorgan',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
          onlyAlertOnce: true,
          icon: 'ic_stat_shield',
          tag: record.key,
        ),
      ),
    );
  }
}
