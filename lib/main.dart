import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'data/repositories/protection_repository.dart';
import 'data/services/blocklist_store.dart';
import 'data/services/blocklist_updater.dart';
import 'data/services/incoming_message_service.dart';
import 'ui/qorgan_app.dart';
import 'data/services/android_sms_service.dart';
import 'data/services/protection_settings.dart';
import 'data/services/onboarding_settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Manrope',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final settings = android
      ? DeviceProtectionSettings()
      : MemoryProtectionSettings();
  final blocklist = android ? SqliteBlocklist() : null;
  runApp(
    QorganApp(
      onboarding: DeviceOnboardingSettings(),
      repository: ProtectionRepository(
        settings: settings,
        blocklist: blocklist,
      ),
      incomingMessages: android
          ? AndroidSmsService(settings: settings, blocklist: blocklist)
          : UnboundIncomingMessageService(),
    ),
  );
  // Refreshed here, in the foreground, and at most twice a day. The SMS
  // receiver never touches the network. A failure is silent: the shipped seed
  // or the last good list stays in place.
  if (blocklist != null) {
    unawaited(
      BlocklistUpdater(
        store: blocklist,
        source: blocklistFeed,
        fetch: fetchOverHttps,
        log: StoredUpdateLog(),
      ).update(),
    );
  }
}
