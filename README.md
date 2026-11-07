<p align="center">
  <img src=".github/assets/qorgan.svg" alt="Qorğan" width="640">
</p>

<p align="center">
  <strong>Spot suspicious SMS. Keep your messages on your phone.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.5-3AD99A?labelColor=121212" alt="Flutter 3.47.5">
  <img src="https://img.shields.io/badge/Android-7.0%2B-3AD99A?labelColor=121212" alt="Android 7.0 or later">
</p>

<p align="center">
  <a href="#features">Features</a> ·
  <a href="#get-started">Get started</a> ·
  <a href="#privacy">Privacy</a> ·
  <a href="#documentation">Documentation</a> ·
  <a href="https://github.com/azamxvit/qorgan-app/actions/workflows/checks.yml">Build &amp; tests</a>
</p>

## About

Qorğan is a Flutter app that helps you check SMS for signs of phishing. Paste a message to check it, or enable alerts for new messages on Android. Each result explains what the app found.

All checks run on your phone. No account is needed. This repository contains the mobile app, which works independently of the Qorğan website. The app interface is currently in Russian.

## Features

- **Check a message.** Paste SMS text and see its risk level and the reasons behind it.
- **Get alerts on Android.** Enable protection to check incoming SMS and receive a warning when a message looks suspicious.
- **Review recent messages.** Browse and filter the last 100 received messages stored by Qorğan. Manual checks are not added to this history.
- **Stay in control.** Manage permissions, clear local history, and mark a result for correction. Reports are prepared locally and shared only when you choose to share them.

Qorğan can miss scams or flag legitimate messages. It does not delete SMS or block links. Android alerts depend on permissions and battery settings; after a force-stop, open the app again to resume them.

## Get started

Use **Flutter 3.47.5**, the version pinned in CI. Android builds also need **Java 17**, **Android SDK 36**, and **NDK 28.2.13676358**. The minimum supported Android version is **7.0 (API 24)**.

```sh
git clone https://github.com/azamxvit/qorgan-app.git
cd qorgan-app
flutter pub get
flutter run
```

Connect an Android phone or start an emulator before running the app. On first launch, you can check text right away or set up protection. SMS access and notification permission are requested separately; protection starts after you enable it.

Background SMS alerts are implemented for Android. Other platform folders do not imply the same SMS support.

For a signed Google Play build, follow the [build and upload guide](docs/google-play/build-and-upload.md). Release signing requires a private upload key kept outside Git.

## Privacy

Message text, senders, and device identifiers are not sent to a server for analysis. History stays on the device, Android backup is disabled, and lock-screen alerts do not show the SMS text. Clearing history removes Qorğan's records and keeps protection enabled.

The app includes a phishing host list and periodically downloads updates from a fixed public URL. These requests contain no message data, but the hosting provider can see the network IP address and request metadata.

Read the [privacy policy](https://qorgan-web.vercel.app/privacy) and the [host list documentation](docs/blocklist.md) for details.

## Development

| Location | Purpose |
| --- | --- |
| [`lib/ui/`](lib/ui/) | Screens, widgets, and view models |
| [`lib/domain/`](lib/domain/) | SMS rules and risk signals |
| [`lib/data/`](lib/data/) | Local storage, host list updates, and incoming SMS |
| [`test/`](test/) | Rule, storage, and UI tests |

Run the checks before submitting a change:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

The test output includes a `detector:` line with precision and recall on the test corpus. The precision gate is `1.0`: no false warnings are allowed on the legitimate messages in that corpus. This is a test requirement, not a guarantee about every real SMS.

Read [AGENTS.md](AGENTS.md) for repository rules. [CI](.github/workflows/checks.yml) also runs release inspection tests and builds an Android smoke APK.

## Documentation

Most technical guides are currently in Russian.

- [Test on a real Android phone](docs/android-phone-check.md)
- [Phishing host list: updates, privacy, and data licence](docs/blocklist.md)
- [Google Play: signing, builds, and upload](docs/google-play/build-and-upload.md)
- [Mobile UX and local previews](docs/mobile-ux-validation.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md), including Manrope and the phishing host list

## Support

Questions or feedback: [omirtayazamatt@gmail.com](mailto:omirtayazamatt@gmail.com).
