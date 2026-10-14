import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import 'incoming_message_processor.dart';
import 'message_store.dart';

class AndroidWarningNotifier implements WarningNotifier {
  final plugin = FlutterLocalNotificationsPlugin();
  static const channelId = 'qorgan_sms_warnings';
  bool _initialized = false;
  AndroidFlutterLocalNotificationsPlugin? get android => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  Future<void> initialize({void Function(String?)? onTap}) async {
    if (_initialized) return;
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_shield'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );
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

  @override
  Future<void> show(StoredMessage record) async {
    await initialize();
    if (!await enabled()) throw StateError('Warning notifications disabled');
    await plugin.show(
      id: record.notificationId,
      title: 'Подозрительное SMS',
      body: 'Не сообщайте код и не открывайте ссылку. Проверьте сообщение в Qorgan.',
      payload: record.key,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Предупреждения Qorgan',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
          onlyAlertOnce: true,
          icon: 'ic_stat_shield',
        ),
      ),
    );
  }
}
