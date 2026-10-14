# Qorgan Android validation — 2026-10-14

Artifact: `artifacts/qorgan-1.0.0.apk`, version 1.0.0 (1), package `kz.qorgan.qorgan_app`, min SDK 24, target SDK 36. Universal release APK for arm64-v8a, armeabi-v7a and x86_64, with a test Android Debug signature.

SHA-256: `3b4db574048b808ef2b435d7777df9f79e043e26631672450c957f8c08a4a942`.

## Verified

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 22 tests pass, including unchanged domain behavior, shared processor, privacy, permission status, persistent switch behavior, real SQLite restoration, deduplication and 100-message retention.
- `flutter build apk --release --no-pub`: succeeds.
- `apksigner verify`: valid test signature.
- APK permissions: RECEIVE_SMS, POST_NOTIFICATIONS, VIBRATE and AndroidX's private dynamic receiver permission. No READ_SMS, SEND_SMS, phone, contacts, location or INTERNET permission.
- Notification drawable is retained in the optimized APK via `res/raw/keep.xml`.
- Original MIT/BSD notices are present in APK NOTICES.Z and accessible through the licenses screen.

## Release APK integration test

Device: Android emulator, API 36 / Android 16, Google APIs arm64-v8a, 320 × 640. The exact deliverable APK was installed, not a debug or integration-test build. All SMS were synthetic emulator events.

Passed:

1. Protection starts and can be enabled with SMS/notification permissions.
2. Ordinary SMS produces no warning.
3. Suspicious SMS produces a warning while the UI is open.
4. After Home and `am kill`, the script confirms the Qorgan process is absent. An incoming suspicious SMS starts background processing and produces a warning while the screen is off.
5. Disabled protection survives process death and suppresses new warnings. Restarting Qorgan restores the disabled state.
6. After enabling protection, rebooting Android and unlocking once, Qorgan remains unopened and has no process. The next suspicious SMS produces a warning.

Reproducible command (emulator only; clears Qorgan's test data):

```bash
python3 scripts/validate_android.py --adb /path/to/adb --apk artifacts/qorgan-1.0.0.apk --reboot
```

Machine-readable evidence: [android-emulator-results.json](android-emulator-results.json). Active system grouping summaries are excluded from the warning count; individual Qorgan notifications have PRIVATE visibility.

## Remaining phone checks

A real phone was not available. Carrier delivery, actual multipart SMS, notification tapping across real device lock screens, literal swipe from recents and Samsung/Xiaomi/Oppo battery management require the checks in [android-phone-check.md](android-phone-check.md). Android 7's notification API behavior is covered by a unit test, not an API 24 emulator run.

Force-stop is excluded: Android blocks receiver delivery until manual launch. The receiver waits for Dart completion up to nine seconds; there is no durable native retry queue if cold initialization exceeds this limit. This APK supplies warnings, not SMS deletion or blocking links in other applications.
