import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/android_sms_service.dart';
import 'package:qorgan_app/data/services/blocklist_store.dart';
import 'package:qorgan_app/data/services/incoming_message_processor.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/data/services/protection_settings.dart';
import 'package:qorgan_app/data/services/warning_notifier.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const protection = MethodChannel('kz.qorgan/protection');
  const telephony = MethodChannel(
    'plugins.shounakmulay.com/foreground_sms_channel',
  );
  final nativeCalls = <String>[];
  final notificationCalls = <MethodCall>[];
  var smsGranted = false;
  var notificationsGranted = false;
  var canRequest = true;
  String? launchKey;
  var notificationLaunch = false;
  var initializationSucceeds = true;
  final activeWarnings = <Map<String, Object?>>[];
  Completer<void>? showStarted;
  Completer<void>? continueShow;
  late Directory directory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('qorgan-service-');
    await databaseFactory.setDatabasesPath(directory.path);
    nativeCalls.clear();
    notificationCalls.clear();
    smsGranted = false;
    notificationsGranted = false;
    canRequest = true;
    launchKey = null;
    notificationLaunch = false;
    initializationSucceeds = true;
    activeWarnings.clear();
    showStarted = null;
    continueShow = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(protection, (call) async {
      nativeCalls.add(call.method);
      if (call.method == 'smsGranted') return smsGranted;
      if (call.method.startsWith('canRequest')) return canRequest;
      return null;
    });
    messenger.setMockMethodCallHandler(telephony, (call) async {
      nativeCalls.add(call.method);
      if (call.method == 'sdkInt') return 24;
      if (call.method == 'requestSmsPermissions') {
        throw PlatformException(code: 'permission_denied');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(notifications, (call) async {
      notificationCalls.add(call);
      if (call.method == 'initialize') return initializationSucceeds;
      if (call.method == 'areNotificationsEnabled') return notificationsGranted;
      if (call.method == 'getActiveNotifications') {
        return activeWarnings.map((warning) => Map.of(warning)).toList();
      }
      if (call.method == 'show') {
        showStarted?.complete();
        if (continueShow != null) await continueShow!.future;
        final args = call.arguments as Map;
        final specifics = args['platformSpecifics'] as Map;
        activeWarnings.add({
          'id': args['id'],
          'tag': specifics['tag'],
          'channelId': specifics['channelId'],
          'title': args['title'],
          'body': args['body'],
        });
      }
      if (call.method == 'cancel') {
        final args = call.arguments as Map;
        activeWarnings.removeWhere(
          (warning) =>
              warning['id'] == args['id'] && warning['tag'] == args['tag'],
        );
      }
      if (call.method == 'getNotificationAppLaunchDetails') {
        return {
          'notificationLaunchedApp': notificationLaunch,
          'notificationResponse': {
            'payload': launchKey,
            'notificationResponseType': 0,
          },
        };
      }
      if (call.method == 'requestNotificationsPermission') return false;
      return true;
    });
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [notifications, protection, telephony]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
    final db = await databaseFactory.openDatabase(
      '${directory.path}/qorgan_messages.db',
    );
    await db.close();
    await directory.delete(recursive: true);
  });

  AndroidSmsService service({
    SqliteMessageStore? store,
    ProtectionSettings? settings,
  }) => AndroidSmsService(
    settings: settings ?? MemoryProtectionSettings(),
    blocklist: const EmptyBlocklist(),
    store: store,
  );

  test('denied SMS request never starts the notification request', () async {
    final access = await service().requestSmsAccess();
    expect(access.sms, isFalse);
    expect(
      nativeCalls.where((call) => call == 'requestSmsPermissions'),
      hasLength(1),
    );
    expect(
      notificationCalls.where(
        (call) => call.method == 'requestNotificationsPermission',
      ),
      isEmpty,
    );
  });

  test(
    'failed notification initialization cannot claim protection ready',
    () async {
      smsGranted = true;
      notificationsGranted = true;
      initializationSucceeds = false;
      await expectLater(service().status(), throwsStateError);
    },
  );

  test('legacy combined request also stops after SMS denial', () async {
    final access = await service().requestAccess();
    expect(access.sms, isFalse);
    expect(
      notificationCalls.where(
        (call) => call.method == 'requestNotificationsPermission',
      ),
      isEmpty,
    );
  });

  test('notification request never asks for SMS access', () async {
    final access = await service().requestNotificationAccess();
    expect(access.notifications, isFalse);
    expect(nativeCalls, isNot(contains('requestSmsPermissions')));
    expect(
      notificationCalls.where(
        (call) => call.method == 'requestNotificationsPermission',
      ),
      hasLength(1),
    );
  });

  test('granted capabilities do not trigger more system prompts', () async {
    smsGranted = true;
    notificationsGranted = true;
    final incoming = service();
    await incoming.requestSmsAccess();
    await incoming.requestNotificationAccess();
    expect(nativeCalls, isNot(contains('requestSmsPermissions')));
    expect(
      notificationCalls.where(
        (call) => call.method == 'requestNotificationsPermission',
      ),
      isEmpty,
    );
  });

  test(
    'permanently denied SMS opens settings only on explicit request',
    () async {
      canRequest = false;
      final incoming = service();
      await incoming.status();
      expect(nativeCalls, isNot(contains('openSettings')));
      await incoming.requestSmsAccess();
      expect(nativeCalls, contains('openSettings'));
      expect(nativeCalls, isNot(contains('requestSmsPermissions')));
    },
  );

  test(
    'latest stays newest while notification opens exactly its older record',
    () async {
      final store = SqliteMessageStore();
      await store.save(record(1));
      await store.save(record(2));
      launchKey = record(1).key;
      notificationLaunch = true;
      final incoming = service(store: store);
      await incoming.status();
      expect(incoming.hasNotificationSelection, isTrue);
      expect((await incoming.openedMessage())?.message.timestamp, 1);
      expect((await incoming.latest())?.message.timestamp, 2);
    },
  );

  test(
    'missing notification record is never replaced by the latest SMS',
    () async {
      final store = SqliteMessageStore();
      await store.save(record(2));
      launchKey = record(1).key;
      notificationLaunch = true;
      final incoming = service(store: store);
      await incoming.status();
      expect(incoming.hasNotificationSelection, isTrue);
      expect(await incoming.openedMessage(), isNull);
      expect((await incoming.latest())?.message.timestamp, 2);
    },
  );

  test('malformed notification still takes priority over onboarding', () async {
    notificationLaunch = true;
    final incoming = service();
    await incoming.status();
    expect(incoming.hasNotificationSelection, isTrue);
    expect(await incoming.openedMessage(), isNull);
  });

  test('clear deletes captured keys and cancels only their warnings', () async {
    final store = PausedDeleteStore();
    final settings = MemoryProtectionSettings(armed: true);
    await store.save(record(1));
    final incoming = service(store: store, settings: settings);
    final clearing = incoming.clearHistory();
    await store.started.future;
    await store.save(record(2));
    store.continueDelete.complete();
    await clearing;
    expect((await incoming.recent()).map((row) => row.message.timestamp), [2]);
    expect(await settings.readArmed(), isTrue);
    expect(
      notificationCalls.where((call) => call.method == 'cancelAll'),
      isEmpty,
    );
    final cancelledIds = notificationCalls
        .where((call) => call.method == 'cancel')
        .map((call) => (call.arguments as Map)['id']);
    expect(cancelledIds, contains(record(1).notificationId));
    expect(cancelledIds, isNot(contains(record(2).notificationId)));
  });

  test('clear removes orphan warnings while preserving warnings posted after its snapshot', () async {
    final store = PausedDeleteStore();
    await store.save(record(2));
    // An earlier message has already been evicted from the retained history.
    activeWarnings.addAll([
      activeWarning(record(1)),
      activeWarning(record(0), legacy: true),
      {'id': 99, 'tag': 'other', 'channelId': 'other_channel'},
    ]);
    final incoming = service(store: store);
    final clearing = incoming.clearHistory();
    await store.started.future;
    await store.save(record(3));
    activeWarnings.add(activeWarning(record(3)));
    store.continueDelete.complete();
    await clearing;
    expect(activeWarnings.map((warning) => warning['id']), [
      99,
      record(3).notificationId,
    ]);
    expect((await store.recent()).map((row) => row.message.timestamp), [3]);
    expect(
      notificationCalls.where((call) => call.method == 'cancelAll'),
      isEmpty,
    );
  });

  test(
    'warning posted after its saved record was cleared is withdrawn',
    () async {
      final store = SqliteMessageStore();
      notificationsGranted = true;
      showStarted = Completer<void>();
      continueShow = Completer<void>();
      final processing = IncomingMessageProcessor(
        settings: MemoryProtectionSettings(armed: true),
        store: store,
        notifier: AndroidWarningNotifier(),
      ).process(record(1).message);
      await showStarted!.future;
      expect(await store.byKey(record(1).key), isNotNull);
      await service(store: store).clearHistory();
      continueShow!.complete();
      await processing;
      expect(await store.byKey(record(1).key), isNull);
      expect(activeWarnings, isEmpty);
    },
  );

  test(
    'failed save still posts a warning even though no stored record exists',
    () async {
      final store = FailingSaveStore();
      notificationsGranted = true;
      await IncomingMessageProcessor(
        settings: MemoryProtectionSettings(armed: true),
        store: store,
        notifier: AndroidWarningNotifier(),
      ).process(record(1).message);
      expect(await store.byKey(record(1).key), isNull);
      expect(activeWarnings.map((warning) => warning['id']), [
        record(1).notificationId,
      ]);
    },
  );
}

Map<String, Object?> activeWarning(
  StoredMessage record, {
  bool legacy = false,
}) => {
  'id': record.notificationId,
  'tag': legacy ? null : record.key,
  'channelId': legacy ? null : AndroidWarningNotifier.channelId,
  // Android's active-notification API does not return the plugin payload.
  'title': 'Подозрительное SMS',
  'body':
      'Не сообщайте код и не открывайте ссылку. Проверьте сообщение в Qorgan.',
};

class FailingSaveStore extends SqliteMessageStore {
  @override
  Future<StoredMessage> save(StoredMessage record) async =>
      throw StateError('storage unavailable');
}

StoredMessage record(int time) {
  final sms = IncomingSms(
    sender: 'Bank',
    body: 'Срочно сообщите код $time',
    timestamp: time,
  );
  return StoredMessage(message: sms, verdict: inspectMessage(sms.body));
}

class PausedDeleteStore extends SqliteMessageStore {
  final started = Completer<void>();
  final continueDelete = Completer<void>();
  @override
  Future<void> deleteKeys(Iterable<String> keys) async {
    started.complete();
    await continueDelete.future;
    await super.deleteKeys(keys);
  }
}
