# SMS permission declaration — Qorğan

Prepared 7 November 2026 for the first Google Play upload and a planned closed test with background SMS protection retained. Developer: **Azamat**, **omirtayazamatt@gmail.com**. Package `kz.qorgan.qorgan_app`, signed release **1.0.0 (1)**, final artifacts/hashes and static package checks are recorded in [release-verification.json](release-verification.json). No video recording is asserted.

**Console update, 7 November 2026:** the AAB is uploaded to Closed testing – Alpha, and the Anti-SMS phishing declaration has been saved without sending the app for review. The live form labels its video link **optional** and accepted a blank link. The owner chose to retain the draft; demonstration/protection evidence is still missing. See [actual Console status and saved instructions](console-progress.md).

The English blocks below are paste-ready factual explanations. The submission is **not complete**: the video URL and protection evidence remain outstanding. Do not turn an expected demonstration result into a claimed test result.

## Console choices

| Field | Value |
| --- | --- |
| Core use case | **Anti-SMS phishing (smishing)** |
| Restricted SMS/Call Log permissions requested | **`android.permission.RECEIVE_SMS` only** |
| Access to app content | **All functionality is available without special access** |
| Reviewer credentials | None; no account, login, subscription or invitation inside the app |
| Old APK exception | Not applicable: first Play upload |
| Demo video URL | **OUTSTANDING — record and upload; no URL exists in this package** |

`POST_NOTIFICATIONS` provides alerts; `INTERNET` downloads the public blocklist. The final artifact report also lists `VIBRATE` and the package's internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`; these are not additional SMS/Call Log permissions. The confirmed release requests only `RECEIVE_SMS` within the SMS/Call Log groups. No `READ_SMS`, `SEND_SMS`, contacts, Call Log or default-handler claim is intended.

Google reviews restricted permissions on testing tracks too. Google's general declaration guidance calls for demonstration material. The live SMS form inspected on 7 November labels its video URL optional; saving it blank is possible, but that does not establish approval eligibility. An accessible YouTube or cloud video link can be added before review. These documents are not permission approval. [Google: permission declaration](https://support.google.com/googleplay/android-developer/answer/9214102?hl=en).

## Core functionality — paste

Qorğan's core purpose is to warn the phone's owner about potentially phishing incoming SMS. After the user reads the in-app disclosure, grants SMS and notification access, and explicitly enables protection, Qorğan checks new SMS on the device, including while the app is in the background. Local rules examine the message text, available sender information and links against an on-device phishing-host list. Suspicious results can produce a local warning; the user can open the corresponding saved message and the reasons for the assessment.

Qorğan requests RECEIVE_SMS to receive new incoming messages. It does not read the existing SMS inbox, send SMS, delete messages from the messaging app, block links, or request to become the default SMS, phone or assistant app. It keeps up to 100 received-message records locally. SMS text, senders and verdicts are not automatically uploaded. The app warns about possible risk; it cannot guarantee detection or establish that a message is authentic.

## Why the permission is necessary — paste

Without RECEIVE_SMS, Qorğan cannot assess a newly arriving SMS while its own screen is closed and warn the user without requiring them to first notice and copy that message. Manual checking remains available without SMS permission, but depends on the user opening Qorğan and entering each message; it does not deliver the core background anti-smishing feature.

SMS Retriever and SMS User Consent support verification-message workflows, not continuous analysis of arbitrary incoming SMS from unrelated senders. Qorğan has no account-verification flow and cannot require unrelated SMS senders to use a verification format for this app. A per-message consent step would also require the user to initiate each check. We therefore request the narrow RECEIVE_SMS permission for new messages and do not request historical inbox access. We are not proposing notification access or Accessibility as substitutes for SMS permission review.

This is Qorğan's explanation of its functionality, not a finding of eligibility. Google lists anti-smishing as an exception subject to review and requires a credible track record of substantial user protection. Its alternatives section describes verification-focused APIs. [Google: SMS/Call Log policy](https://support.google.com/googleplay/android-developer/answer/10208820?hl=en).

## Access instructions — paste

All app functionality is available without an account or special access. No test username, password, OTP login or subscription is required. Background SMS review requires an Android phone capable of receiving SMS, SMS and notification permissions, and the user's explicit protection opt-in. A second phone can send controlled test SMS to the test device. Manual checking is available if SMS access is declined. Permission prompts are device capabilities, not account access restrictions.

## Reviewer steps — paste after rehearsing against the submitted build

Use these controlled synthetic bodies from our development corpus, sent from a second phone you control. The sender displayed should be that phone's actual number; do not spoof a bank or substitute the corpus's invented sender number. No live phishing link or real verification code is needed.

Suspicious fixture (the corpus's second phishing body):

```text
Kaspi: Ваш счет заблокирован. Сообщите код из SMS для разблокировки.
```

Benign control (the corpus's courier body):

```text
Курьер заберет заказ через 15 минут
```

These are synthetic fixtures, not messages from or endorsements by the named organizations. Expected outcomes below require confirmation on the submitted build.

1. Install the submitted build and open Qorğan. Continue through the introduction; no registration is required. The current app UI is in Russian.
2. Open protection setup ("Настроить защиту"). Select "Разрешить приём SMS". Read "Доступ к новым SMS", including background use, local storage and the choice to decline. Choose "Согласен, разрешить приём SMS", then allow the Android SMS permission.
3. Allow notifications using "Разрешить уведомления". Select "Включить защиту" separately. Confirm the app reports the actual enabled state. Leave the phone's default messaging app unchanged.
4. From a second phone send the suspicious fixture above. With Qorğan in the background, inspect the local warning. It should not reveal the SMS body or verification codes.
5. Tap that warning. Confirm it opens the exact test SMS, its sender and its assessment, rather than another recent record. Read the explanation of the detected signals.
6. Send the benign control above. Check that it is available in Qorğan's history and that no warning occurs. Report the actual behavior if it differs from this expectation.
7. In settings turn protection off and repeat delivery: new messages should not be processed by Qorğan. Revoke SMS permission in Android settings and confirm manual checking still works.
8. Use "Очистить историю" in Qorğan settings and confirm deletion. Reopen the app: cleared records should stay absent, while original messages remain in the phone's messaging app. New SMS received while protection remains on can create new records.

These are instructions and expected behavior, **not a completed phone test**. Before submission, verify exact labels, rehearse the identified synthetic fixtures and record the release version. Both bodies come from `test/domain/sms_corpus.dart`; fixture messages are synthetic, not evidence of attacks prevented. Do not include real OTPs or personal conversations in review material.

## Demonstration video: recording script

Suggested duration: 3–5 minutes. Show the real submitted Android build and actual interactions, with English captions for the Russian UI. Keep test-phone numbers private. Do not splice a manual check into the background-delivery sequence.

| Time | Screen/action | English narration or caption |
| --- | --- | --- |
| 0:00–0:20 | App/version on the test phone; fresh launch | “Qorğan is an on-device SMS phishing warning app. This is a controlled demonstration, not a field effectiveness study. No account is needed.” |
| 0:20–1:00 | Disclosure, explicit agreement, Android SMS and notification prompts, enable switch | “The user chooses background protection. RECEIVE_SMS is the only SMS permission. Existing inbox messages are not read.” |
| 1:00–1:45 | Press Home; send identified synthetic suspicious fixture from another phone; show arrival and warning continuously | “Qorğan assesses a newly received SMS while in the background. The warning omits the message body.” |
| 1:45–2:15 | Tap notification; show matching record and signals | “This result belongs to this SMS. Qorğan gives a warning; it does not delete the original message or prevent you from acting on it.” |
| 2:15–2:45 | Send identified benign control; inspect history and notification panel | State what actually happened. Do not generalize a single control to all legitimate SMS. |
| 2:45–3:20 | Turn protection off; deliver another fixture; show manual check | “Background processing is opt-in. Manual checking is available without SMS permission.” |
| 3:20–4:00 | Clear local history, reopen, show original SMS still in messaging app; show policy link | “Clearing removes Qorğan's copies. The public policy describes storage, blocklist downloads and voluntary support.” |

Record before submitting: **video URL OUTSTANDING; build/version OUTSTANDING; recording date OUTSTANDING; device/Android OUTSTANDING; real-phone fixture rehearsal OUTSTANDING**. Use the two bodies above in the video. Test the uploaded link without the owner's login. Correct failures before recording a successful take; retain failure notes in the test log.

The release version **1.0.0 (1)** does not fill the video's build/version field: no video has been recorded, so its actual demonstrated build remains outstanding.

## Honest evidence inventory

| Evidence | What currently exists | What it does not establish |
| --- | --- | --- |
| Automated verification | Recorded final run, 7 November 2026 ([readiness](../google-play-readiness.md)): **194 Flutter tests passed**; formatting checked 82 files with 0 changed; analyze found no issues. Separate Python release checks: **2 passed**. | Automated checks do not establish real-phone delivery or field effectiveness. |
| Detector regression corpus | Current **39 synthetic SMS: 25 legitimate + 14 phishing**. Final reported precision **1.00**, recall **1.00**, 0 false warnings among 25 legitimate, 0 misses among 14 phishing, **92% legitimate clear**. `test/domain/sms_corpus.dart` identifies the fixtures as hand-written, not collected user data. | Tiny development corpus, not an independent benchmark, representative field estimate, endorsement or user-protection history. Do not put these rates in store copy. |
| Feedback/report integration | **37 focused UI tests** and **2 real-SQLite tests** passed; verified persistence/refresh on both routes, fresh `recent()` for Report, explicit awaited clipboard copying, error handling and no automatic sending. Focused counts are not added to the 194-test full suite. | Does not establish real-phone background SMS receipt or field protection effectiveness. |
| Source-level behavior | Local rule, real SQLite store, background entry point, constant-URL blocklist download, local report builder; relevant files listed in `README.md`. | Source inspection does not prove the submitted AAB works on real devices. |
| Real-phone test | **Missing current report** tied to a release artifact; the final `adb` check found no devices. `docs/android-phone-check.md` is a procedure. | An emulator/older APK report is not current phone proof. |
| Pilot / real-world protection | **No supplied pilot, outcome records, independent benchmark, analyst report, industry publication or endorsement.** | No established track record meeting the exception's evidence expectation. |
| Review video | Script above; **recording and URL missing**. | A future video cannot be listed as available evidence. |

Evidence explanation — paste if asked:

> This is Qorğan's first Google Play submission. Our latest confirmed automated run on 7 November 2026 passed 194 Flutter tests. The detector's small hand-written corpus contains 39 synthetic examples: 25 legitimate and 14 phishing SMS. On those fixtures, precision and recall were both 1.00, with no false warnings and no missed phishing examples; 92% of legitimate examples received the clear classification. These internal development results are not an independent benchmark or evidence of real-world effectiveness. We do not currently have a documented real-phone pilot, independently measured protection results, analyst reports or an established user-protection history. We cannot claim that the available evidence establishes eligibility for the anti-SMS phishing exception.

Do not silently switch to a manual-only product if Google requests more evidence or declines. The authorized submission retains background protection; escalate the decision and collect genuine evidence. Approval remains Google's decision.
