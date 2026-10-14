# Background SMS Implementation Plan

> Execute inline using executing-plans; keep the existing working tree and user changes.

**Goal:** Build an Android APK that warns about incoming suspicious SMS while Flutter UI is closed.
**Architecture:** Android SMS broadcast receiver starts a background Dart handler. A shared processor calls the unchanged domain rule, persists results and posts private local notifications.
**Tech Stack:** Flutter/Dart, another_telephony, flutter_local_notifications, shared_preferences, sqflite.
**Spec:** ../specs/2026-10-14-background-sms-design.md

## Global constraints

- Preserve inspectMessage, its weights and score >= 4 threshold.
- Only RECEIVE_SMS and POST_NOTIFICATIONS permissions; no network SMS processing.
- Android APK first; force-stop excluded; iOS manual checks only.
- No foreground singleton or ViewModel dependency in background callback.
- Preserve user edits; no resetting or automatic committing of their work.

## Review focus

- Disabled protection persists and is observed in another isolate.
- Duplicate and multipart SMS produce one warning.
- Storage failure does not suppress a threat notification.
- Denied/revoked permissions and disabled notification channel do not claim readiness.
- Notification preview does not disclose SMS body or OTP on lock screen.

## Task 1: Common processor and storage

Files: lib/data/services/incoming_message_processor.dart, message_store.dart, protection_settings.dart; test/data/incoming_message_processor_test.dart.
Interfaces: IncomingSms(sender, body, timestamp), MessageStore.save/latest/markNotified, ProtectionSettings.readArmed/writeArmed, WarningNotifier.show.
- [x] Write failing behavioral tests: phishing warns, ordinary does not, disabled and empty ignored, duplicate ignored, notification failure can retry, storage failure still warns.
- [x] Run `flutter test test/data/incoming_message_processor_test.dart`, implement shared async processor and persistent adapters, rerun suite.

```dart
final verdict = inspectMessage(message.body);
if (verdict.block) await notifier.show(record);
```

## Task 2: Android integration

Files: incoming_message_service.dart, android_sms_service.dart, warning_notifier.dart, main.dart, pubspec.yaml, AndroidManifest.xml, Android Gradle configuration, notification drawable.
Interfaces: service initialize/status/requestAccess/process callback; Android background callback initializes its own processor dependencies.
- [x] Obtain packages and inspect actual receiver/background implementation, permissions and licenses.
- [x] Register protected SMS_RECEIVED receiver, top-level entry point, private notification channel, stable notification IDs.
- [x] Validate manifest and compile release APK. Fix compatibility in a documented local MIT fork if upstream cannot compile against current AGP.

```dart
@pragma('vm:entry-point')
Future<void> onBackgroundSms(SmsMessage sms) async {
  WidgetsFlutterBinding.ensureInitialized();
  await createProcessor().process(IncomingSms.fromPlatform(sms));
}
```

## Task 3: Protection UI and persistent switch

Files: protection_repository.dart, guard_view_model.dart, guard_screen.dart, copy.dart, home_shell.dart; test/guard_view_model_test.dart, test/widget_test.dart.
- [x] Write failing tests for default disabled, denied permissions, successful enable, persistence failure, resume refresh and saved incoming result.
- [x] Implement enable flow, permission disclosure/card, persistent switch, latest received verdict and truthful warning copy.
- [x] Run `flutter analyze` and all `flutter test` tests.

## Task 4: Delivery

Files: README.md, THIRD_PARTY_NOTICES.md, docs/android-phone-check.md, artifacts/qorgan.apk.
- [x] Record source versions, upstream notices and actual copied code provenance.
- [x] Inspect release manifest and APK; export APK with SHA-256 checksum.
- [x] List real-phone checks for active/background/swiped/locked/process-death/reboot, multipart and permission revocation. Only claim device checks if actually performed.

## Execution ledger

User approved the written spec and explicitly requested implementation and APK on 2026-10-14. Execute in the current workspace to preserve the uncommitted Qorgan foundation. No deployment or publication requested.

Verification: 22 tests pass; flutter analyze clean; native permissions checked. Physical phone checks remain for the user. Emulator validation recorded separately in docs/android-validation.md.
