// Adapted from another_telephony 0.4.1. MIT, Copyright (c) 2020 Shounak Mulay.
// Qorgan keeps only incoming SMS and awaits registration and background completion.
import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef MessageHandler = FutureOr<void> Function(SmsMessage message);
const _foregroundChannel = MethodChannel(
  'plugins.shounakmulay.com/foreground_sms_channel',
);
const _backgroundChannel = MethodChannel(
  'plugins.shounakmulay.com/background_sms_channel',
);

@pragma('vm:entry-point')
void _flutterSmsSetupBackgroundChannel() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  _backgroundChannel.setMethodCallHandler((call) async {
    if (call.method != 'handleBackgroundMessage') return;
    final handle = CallbackHandle.fromRawHandle(
      call.arguments['handle'] as int,
    );
    final callback = PluginUtilities.getCallbackFromHandle(handle);
    if (callback == null) throw StateError('SMS callback unavailable');
    await callback(SmsMessage.fromMap(call.arguments['message'] as Map));
  });
  _backgroundChannel.invokeMethod<void>('backgroundServiceInitialized');
}

class Telephony {
  Telephony._();
  static final instance = Telephony._();
  Future<bool?> get requestSmsPermissions =>
      _foregroundChannel.invokeMethod<bool>('requestSmsPermissions');
  Future<void> listenIncomingSms({
    required MessageHandler onNewMessage,
    required MessageHandler onBackgroundMessage,
    bool listenInBackground = true,
  }) async {
    _foregroundChannel.setMethodCallHandler((call) async {
      if (call.method == 'onMessage') {
        await onNewMessage(
          SmsMessage.fromMap(call.arguments['message'] as Map),
        );
      }
    });
    final setup = PluginUtilities.getCallbackHandle(
      _flutterSmsSetupBackgroundChannel,
    );
    final background = PluginUtilities.getCallbackHandle(onBackgroundMessage);
    if (setup == null || background == null) {
      throw ArgumentError('SMS background callback must be top-level');
    }
    await _foregroundChannel.invokeMethod<void>('startBackgroundService', {
      'setupHandle': setup.toRawHandle(),
      'backgroundHandle': background.toRawHandle(),
    });
  }
}

class SmsMessage {
  SmsMessage.fromMap(Map raw)
    : address = raw['address'] as String?,
      body = raw['body'] as String?,
      date = int.tryParse(raw['date']?.toString() ?? '');
  final String? address;
  final String? body;
  final int? date;
}
