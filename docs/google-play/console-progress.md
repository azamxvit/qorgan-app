# Google Play release status — 8 November 2026

This public record omits developer-account IDs, private Console links and tester email addresses. Open [Play Console](https://play.google.com/console/) and select Qorğan to manage the release.

- Package: `kz.qorgan.qorgan_app`
- App: **Qorğan**, Russian default language, free app
- Closed-testing track: **Alpha**
- Release: **1.0.0 (1) — closed test**

## Last observed submission state

The owner authorised submission. Publishing overview then showed **Changes in review** for 14 changes, with automated pre-review checks still running. The Console stated that the changes would be sent for review once those checks completed successfully. This records acceptance of the submission request, not Google approval or public availability.

All **178 available countries/regions**, including the rest-of-world option, were selected. Two owner-approved email lists were attached to Alpha: the existing list and a separate six-address list. Membership details remain in Play Console. List membership does not establish that anyone opted in, installed the app or completed 14 days of testing.

## Release and declarations

- App bundle **1 (1.0.0)**: minimum API **24+**, target SDK **36**, 3 ABIs, with mapping and native debug symbols.
- The final release preview showed **Ready to release**, with the previous country-selection error and missing-tester warning resolved.
- Sign-in details: **No restricted access**; functionality does not require an account or payment.
- SMS core functionality: **Anti-SMS phishing only**; the declaration covers `android.permission.RECEIVE_SMS`.
- Review instructions describe consent/setup, controlled background SMS tests, exact-message notification routing, manual mode and local processing/storage. They do not claim proven field effectiveness.
- The optional SMS demonstration-video field was left empty. Saving or submitting the form does not establish permission approval.
- All App content declarations were completed. Exact answers are recorded in [console-form-answers.md](console-form-answers.md).
- Target audience: **13–15, 16–17, 18 and over**. Content ratings were calculated, including PEGI 3 / ESRB Everyone.
- Data safety uses the IP-address disclosure explained in [data-safety.md](data-safety.md).
- Store category **Tools**, tag **Privacy & security**; public support contact and HTTPS website saved.
- Russian listing text, black-background icon, feature graphic and four **1080×1920** phone images submitted.
- Phone images render the production Flutter widgets with an empty first-run state through `test/mobile_google_play_capture_test.dart`. They are not evidence of background SMS operation on a physical Android device.

## Next steps

- Check the final automated-check and Google review outcomes in Play Console.
- Once the closed release becomes available, give eligible testers the opt-in link shown in Console. Each tester must join under an authorised Google account and install the intended Play release.
- Record real-device behavior, feedback and fixes. No real-phone demonstration or field-effectiveness evidence is asserted here.
- Confirm at least **12 testers continuously opted in for the preceding 14 days** before applying for production access. This is a separate application, not automatic public publication.

## Uploaded artifact

`artifacts/play-release/qorgan-1.0.0-1.aab`, **53,027,634 bytes**. The local artifact directory and signing material are excluded from Git.

SHA-256:

```text
18585e324504466d737f0df217c9708bd77dd9589a40c771d58c78f29728784a
```

Static package verification is recorded in [release-verification.json](release-verification.json). The uploaded AAB was not rebuilt during store-listing preparation or submission.

## Verification recorded when the store assets were prepared

- Format: **83 files, 0 changes**.
- `flutter analyze`: no issues.
- `flutter test`: **195 tests passed**.
- Detector: precision **1.00**, recall **1.00** on the synthetic corpus, with 0 false warnings among 25 legitimate messages and 0 missed phishing messages among 14. Two legitimate messages had the intermediate `watch` state (92% `clear`). These are corpus metrics, not field-effectiveness evidence.
- `git diff --check`: passed.
