import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/data/services/warning_notifier.dart';
import 'package:qorgan_app/domain/inspect_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var sdk = 24;
  var enabled = true;
  setUp(() {
    sdk = 24;
    enabled = true;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getNotificationChannels') {
            return <Map>[]; // Android 7
          }
          if (call.method == 'areNotificationsEnabled') return enabled;
          return true;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(
            'plugins.shounakmulay.com/foreground_sms_channel',
          ),
          (_) async => sdk,
        );
    calls.clear();
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'warning payload is private and never includes SMS text or OTP',
    () async {
      const sms = IncomingSms(
        sender: 'Bank',
        body: 'Срочно сообщите код 123456',
        timestamp: 1,
      );
      final notifier = AndroidWarningNotifier();
      await notifier.show(
        StoredMessage(message: sms, verdict: inspectMessage(sms.body)),
      );
      final payload =
          calls.singleWhere((c) => c.method == 'show').arguments as Map;
      expect(payload['body'], isNot(contains('123456')));
      expect(payload['body'], isNot(contains(sms.body)));
      final details = payload['platformSpecifics'] as Map;
      expect(details['visibility'], 0); // Android VISIBILITY_PRIVATE
      expect(details['onlyAlertOnce'], isTrue);
    },
  );
  test(
    'Android 8+ cannot claim readiness when warning channel is missing',
    () async {
      sdk = 36;
      final notifier = AndroidWarningNotifier();
      await notifier.initialize();
      expect(await notifier.enabled(), isFalse);
    },
  );
  test('disabled app notifications suppress readiness and posting', () async {
    enabled = false;
    final notifier = AndroidWarningNotifier();
    await notifier.initialize();
    expect(await notifier.enabled(), isFalse);
    const sms = IncomingSms(sender: 'x', body: 'код срочно', timestamp: 1);
    await expectLater(
      notifier.show(
        StoredMessage(message: sms, verdict: inspectMessage(sms.body)),
      ),
      throwsStateError,
    );
    expect(calls.where((call) => call.method == 'show'), isEmpty);
  });
}
