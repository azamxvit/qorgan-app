# Closed-testing plan — Qorğan

Prepared 7 November 2026. First Play upload; personal developer account created after 13 November 2023. The closed-test release **retains background SMS protection**. This file is a plan and blank evidence checklist, not a record of testers recruited or testing completed.

## Eligibility rule

For this account, Google requires at least **12 testers continuously opted into the closed test for the preceding 14 days**, including when production access is requested. Meeting that minimum permits an application for production access; it is not automatic approval. Internal testing is optional and does not replace the closed test. The application asks about actual engagement, feedback and readiness. [Google: new personal-account testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

SMS permission eligibility and the missing protection-evidence history remain separate gates; see `sms-permission-declaration.md`. Closed testing does not establish that the SMS exception is approved.

## Before inviting testers

- [ ] Complete account/device verification and Play Console app setup; confirm the submitted application identity.
- [x] Signed release **1.0.0 (1)** AAB/APK, hashes, identities, permissions, signing, bundletool and static 16 KB checks are recorded in [release-verification.json](release-verification.json). This does not supply real-phone installation evidence.
- [x] Final checks, 7 November 2026 ([readiness](../google-play-readiness.md)): format 82 files / 0 changed, analyze no issues, full Flutter suite **194 passed**; Python release checks **2 passed**. Detector precision/recall **1.00/1.00**, 0 false warnings among 25 legitimate and 0 misses among 14 phishing synthetic fixtures, 92% legitimate clear. A green suite is not phone proof.
- [ ] Record the real-phone scenarios below against that artifact before inviting a wider group.
- [x] Public policy publication verified at [https://qorgan-web.vercel.app/privacy](https://qorgan-web.vercel.app/privacy) on **7 November 2026**: production READY, unauthenticated HTTP 200 without redirect/login, full RU/EN policy/contact/logging disclosure in rendered text.
- [ ] Check the in-app policy entry against the published policy on the intended device/build.
- [ ] Resolve `data-safety.md` and complete the form. No unchecked “no data” declaration.
- [ ] Prepare permission declaration, honest evidence inventory and accessible video; address Console review requirements. **Video URL and sufficient protection history outstanding.**
- [ ] Select the final [store assets](assets/) and actual release screenshots; use the RU/EN copy from `store-listing.md` and verify labels against the release.
- [ ] Confirm actual target audience, countries, content rating, ads answer and unrestricted app access in Console.

## Recruit and enroll

- [ ] Recruit at least 12 willing testers with Google accounts and suitable Android phones. As a practical buffer, invite more than 12; extra invitations are not qualifying opt-ins.
- [ ] Use the actual closed-track tester list/group and opt-in link from Console. Do not invent a link here.
- [ ] Explain that testers must accept the opt-in, install from the intended track and stay opted in continuously. Simply joining an email list or installing a sideloaded APK is not our enrollment evidence.
- [ ] Keep a private roster: tester alias, consent, device/Android, opt-in time and participation status. Avoid publishing emails, phone numbers or SMS contents in this repository.
- [ ] Confirm the eligible continuously opted-in count in Console. Start the planned window when a qualifying cohort is present; track changes and re-check eligibility at application time.
- [ ] Tell testers that this is an experimental warning tool that can miss threats or produce false alarms. They must not rely on it as proof that an SMS is safe.
- [ ] Provide feedback routes: Play's private testing feedback or a voluntary email to `omirtayazamatt@gmail.com`. Ask for build/device/steps; raw personal SMS are not required. Redact any message the tester deliberately chooses to send.

## Practical exercise schedule

These days are a suggested work plan, not a Google-prescribed daily usage quota. Do not fill future dates or results as if the work occurred.

| Period | Activity | Evidence to retain privately |
| --- | --- | --- |
| Before cohort start | Initial phone smoke check; policy/permission review | Artifact hash, device, build, factual scenario results |
| Days 1–2 | Install, decline permissions, manual check, then explicit background opt-in | Confusing screens, permission-state mismatches, failure steps |
| Days 3–5 | Foreground/background receipt, locked screen, multipart SMS and exact notification routing | Controlled fixture IDs; actual outcome, not just “works” |
| Days 6–9 | Reboot, OEM battery restrictions, permission/channel revocation, offline use | Phone/Android differences, missed delivery, error details |
| Days 10–12 | History clear/relaunch, 100-record eviction, feedback/report privacy if available | Persistence checks; no real OTP in shared screenshots |
| Days 13–14+ | Recheck fixes on the intended build, summarize feedback and remaining risks | Honest engagement and fix log; current eligible opt-in cohort |

## Real-phone checklist

Record **PASS / FAIL / NOT RUN**, date, device, Android version, exact artifact hash, permissions, battery mode and steps for each. Suggested cases build on `docs/android-phone-check.md`; no result is asserted here.

The final `adb` check found **no devices**. The confirmed 37 focused UI tests and 2 real-SQLite checks do not complete these real-phone scenarios. Bind phone evidence to signed release **1.0.0 (1)** and its artifact/hash in [release-verification.json](release-verification.json).

- [ ] Fresh install shows no account requirement. Declining/backing out of SMS disclosure does not enable protection; manual check still works.
- [ ] Explicit agreement precedes the Android SMS prompt; notifications and the enable action work as shown in the review script.
- [ ] A controlled benign SMS and a controlled suspicious SMS are assessed in foreground and background. Never open a test phishing URL.
- [ ] Locked-screen warning does not expose body/OTP. Tapping opens the exact SMS. With two warnings, tapping the older one does not substitute the newer SMS.
- [ ] After that record is cleared/evicted, an old notification shows the missing-record state rather than another message.
- [ ] Multipart SMS is assessed as a whole. Test cold process start, removal from recents, reboot/unlock and intended OEM battery modes.
- [ ] Distinguish ordinary process kill from Android force-stop; record any need to reopen. Do not promise guaranteed delivery under force-stop or every device restriction.
- [ ] Disabled protection persists across relaunch. SMS/channel/notification revocation is reflected accurately; manual checks remain available.
- [ ] Clear history, relaunch and verify the removed records stay absent. Original SMS remain in the system messaging app. Concurrent new receipt may create a new Qorğan record.
- [ ] Confirm no more than 100 received-message records remain, and feedback survives relaunch for retained records if exposed in the release.
- [ ] Manual draft persists only in memory across navigation, clears on explicit reset/process exit, and is absent from received-message history.
- [ ] If report export is available, confirm it warns that it contains full SMS text; copy only on an explicit action. Check redaction instructions and no automatic sending.
- [ ] Offline checks use the local list; app launch's list download contains no SMS/sender/app-added device-ID payload. Reconcile the IP declaration with the published provider evidence and final owner review in `data-safety.md`.
- [ ] Inspect backup configuration and test restore/transfer where feasible. Record limitations; never promise that all OEM transfers obey the flag.

## Production-access evidence template

| Input | Current status |
| --- | --- |
| Closed-track name and opt-in URL | OUTSTANDING |
| Cohort start and earliest eligible application date | OUTSTANDING — derive from actual continuous opt-ins |
| At least 12 eligible testers at application time | NOT VERIFIED |
| Who tested / relevant devices / actual engagement | OUTSTANDING |
| Feedback received, issues fixed, retested build | OUTSTANDING |
| Known failures or untested device conditions | OUTSTANDING |
| Real-phone/pilot observations | NOT YET SUPPLIED; `adb` found no devices |
| Final automated count and detector output | **194 Flutter tests passed**, precision/recall **1.00/1.00**, 0 FP/25 legitimate, 0 misses/14 phishing, 92% legitimate clear; synthetic corpus only |
| SMS permission decision / evidence attachments | OUTSTANDING |
| Decision to apply for production access | NOT MADE |

Write production-access answers from these records after the test. Do not state that 12 people used the app for 14 days merely because time passed; do not convert synthetic fixture results into real-world protection claims.
