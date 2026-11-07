# Qorğan — Google Play owner handoff

Status: **8 November 2026**. Developer: **Azamat**. Contact: [omirtayazamatt@gmail.com](mailto:omirtayazamatt@gmail.com). Release: **1.0.0 (1)**, package `kz.qorgan.qorgan_app`.

The signed AAB is uploaded to Closed testing – Alpha. The owner authorised submission of the release, store listing and App content declarations, including Data safety and Anti-SMS phishing. The last observed Console status was **Changes in review**, with automated pre-review checks still running. The listing includes the black-background icon and four 1080×1920 screenshots. See [Console status](console-progress.md) and [saved form answers](console-form-answers.md). Background SMS protection is retained. Submission is not SMS permission approval, a completed test rollout, production access or real-phone/pilot validation.

## Submission files

| File | Use |
| --- | --- |
| [build-and-upload.md](build-and-upload.md) | Build and Play upload instructions |
| [release-verification.json](release-verification.json) | Artifact identities, hashes, permissions, signing and static 16 KB checks |
| [assets/](assets/) | Store assets |
| [sms-permission-declaration.md](sms-permission-declaration.md) | English declaration, reviewer instructions, video script and evidence inventory |
| [store-listing.md](store-listing.md) | RU/EN app name and descriptions |
| [data-safety.md](data-safety.md) | Data flows, provider evidence and proposed Console answers for owner review |
| [console-form-answers.md](console-form-answers.md) | Exact saved declarations, audience, ratings, contacts and store-listing status |
| [closed-testing.md](closed-testing.md) | Enrollment, 12-tester/14-day requirement and device-test checklist |
| [privacy-policy-ru.md](privacy-policy-ru.md) | Full Russian mobile privacy policy |
| [privacy-policy-en.md](privacy-policy-en.md) | Full English mobile privacy policy |
| [website/privacy-page.tsx](website/privacy-page.tsx) | Bilingual Next page source for `src/app/privacy/page.tsx` |

Release context and recorded checks: [Google Play readiness](../google-play-readiness.md). Static artifact evidence: [release-verification.json](release-verification.json).

## Public privacy policy

[https://qorgan-web.vercel.app/privacy](https://qorgan-web.vercel.app/privacy) — **verified 7 November 2026**. The production deployment is **READY** at `qorgan-web.vercel.app`. An unauthenticated request to `/privacy` returned **HTTP 200**, without redirect or login. Rendered text contains the full RU/EN policy, Azamat, contact information and GitLab's seven-day logging disclosure.

The source is persisted in qorgan-web. Website build and lint passed on **Next 16.4.5**. The page contains static metadata, the canonical URL, language anchors and direct contact links. Its 44 policy paragraphs match the Markdown policies. Keep these copies and the in-app explanation aligned when data handling changes.

Google requires a public privacy policy and policy text or a link inside the app; unexpected background access also requires an in-app explanation and affirmative consent before the permission request. [Google: User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311).

## Signed release artifacts

The following values are recorded in [release-verification.json](release-verification.json):

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| [AAB](../../artifacts/play-release/qorgan-1.0.0-1.aab) | 53,027,634 | `18585e324504466d737f0df217c9708bd77dd9589a40c771d58c78f29728784a` |
| [APK](../../artifacts/play-release/qorgan-1.0.0-1.apk) | 53,921,960 | `85b46015e567542e60f6ea5a5ad354ae6334dbe9a478cc2186e3e1244849e2ff` |

Bundletool validation, signing, artifact identities, permissions and static 16 KB checks **passed**. The only SMS/Call Log permission is `RECEIVE_SMS`. Static package checks do not establish real-device operation, 16 KB runtime behavior or Google Play approval.

## Recorded final checks

See [readiness](../google-play-readiness.md) for release context. Focused test counts are not added to the full-suite count.

| Check | Result |
| --- | --- |
| Dart formatting | 83 files, 0 changed |
| Flutter analyze | No issues |
| Full Flutter suite | **195 tests passed** |
| Focused feedback UI | **37 tests passed** |
| Real-SQLite feedback checks | **2 tests passed** |
| Python release checks | **2 tests passed**, separate from Flutter counts |
| Detector | Precision **1.00**, recall **1.00**; **0 false warnings / 25 legitimate**, **0 misses / 14 phishing**; **92% legitimate clear** |
| Corpus scope | 39 synthetic development examples; not an independent benchmark or real-world protection history |
| Connected device | `adb` found no devices; real-phone verification remains outstanding |

Feedback persistence and refresh are wired on both routes. The Report page reads fresh `recent()` data, awaits explicit clipboard copying, handles errors and does not send automatically. The full-text report disclosure and advice to redact before external sharing remain part of the policy.

Short descriptions are within 80 characters: RU **59**, EN **44**. Full descriptions contain RU **1717**, EN **1664** characters.

## Remaining owner actions

- Keep the submitted [Data safety answers](console-form-answers.md) aligned with actual data handling. The IP declaration is collected/shared, required, non-ephemeral and HTTPS; it does not rely on a contracted service-provider exemption.
- Record the reviewer video and provide an accessible URL. Its build/version field remains **OUTSTANDING** until a recording identifies the demonstrated build, even though release 1.0.0 (1) is available.
- Run the real-phone checklist, including the in-app policy entry, and retain evidence tied to the signed artifact/hash. Obtain genuine protection/pilot evidence for SMS exception eligibility.
- Review the saved app setup and listing, finish any account-level tasks, and obtain permission approval. Follow [the live Console progress record](console-progress.md) for remaining assets and blockers. No approval is implied by these documents.
- Recruit the closed-test cohort and record actual opt-in dates, engagement and feedback under [closed-testing.md](closed-testing.md).
