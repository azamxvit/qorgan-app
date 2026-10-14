import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'data/repositories/protection_repository.dart';
import 'data/services/incoming_message_service.dart';
import 'ui/qorgan_app.dart';
import 'data/services/android_sms_service.dart';
import 'data/services/protection_settings.dart';
import 'ui/preview/design_preview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Manrope',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  if (const bool.fromEnvironment('QORGAN_PREVIEW')) {
    runApp(const QorganPreviewApp());
    return;
  }
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final settings = android
      ? DeviceProtectionSettings()
      : MemoryProtectionSettings();
  runApp(
    QorganApp(
      repository: ProtectionRepository(settings: settings),
      incomingMessages: android
          ? AndroidSmsService(settings: settings)
          : UnboundIncomingMessageService(),
    ),
  );
}
