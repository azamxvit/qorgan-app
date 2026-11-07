# Data safety — evidence worksheet for the saved declaration

**Console update, 7 November 2026:** the owner requested completing and saving the forms without sending the app for review. Data safety is now saved, and App content shows no declarations needing attention. The exact selected answers and deletion-mechanism rationale are recorded in [console-form-answers.md](console-form-answers.md). The worksheet below retains the evidence and qualifications behind those choices. Saving is not Google approval; final owner review before submission remains outstanding.

Updated 7 November 2026 for Qorğan, developer **Azamat**, contact **omirtayazamatt@gmail.com**. Scope: Android mobile app, not the qorgan-web product. **Recommended automatic-download declaration: IP under Device or other IDs, collected and shared, required, non-ephemeral, HTTPS. Final owner review is required before submission; this is not a submitted form.**

## Google definitions relevant to this worksheet

Closed testing requires a Data safety form; exclusively internal testing is exempt. Collection concerns data leaving the device, including through dependencies; solely local processing is outside collection. Sharing can include transfers to another app, with exceptions for qualifying user-directed transfers or providers acting on the developer's instructions. A sharing exception does not itself exempt collection. Google's IP FAQ requires classification according to actual use; location belongs in the declaration when IP is used to determine location. Retained logs are not ephemeral processing. [Google: Data safety definitions and IP FAQ](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).

The recommendations below are an assessment of **this implementation and the provider's published policy**, not a Google ruling or an independent audit of GitLab systems. The owner must reconcile them with the final build and live form.

## Actual flows

| Data / operation | Inspected behavior | Proposed treatment / remaining question |
| --- | --- | --- |
| Incoming SMS body, sender, receipt timestamp | Processed on-device after protection opt-in. Stored in app-private SQLite with score, signals, notification state and local message key. Up to 100 records. | Local SMS access is not an automatic SMS upload. “SMS or MMS” off-device collection is not evidenced by this path. The app receives SMS, not MMS. |
| Verdict and feedback | Assessment and saved correction labels are local. Feedback does not silently change the rule or send training examples. | Persistence and refresh on both UI routes are verified by the focused UI and real-SQLite checks. No remote feedback endpoint or automatic sending. |
| Manual draft and result | Text entered/pasted by the user is held in memory, not the received-message database; may survive tab navigation until cleared or process exit. Clipboard read is user-triggered. | No off-device collection evidenced by the check. OS keyboard/clipboard behavior is outside the detector's control. |
| Correction report / clipboard | `buildFeedbackReport` includes **full marked SMS text**, sender, received date/time, verdict, score/signals and user label. The Report page reads fresh `recent()` data and awaits an explicit clipboard copy, with error handling and no automatic sending. | A copied report can leave the device when the user separately pastes/shares elsewhere or uses a syncing clipboard. It is not anonymized; the full-text disclosure and redaction advice remain necessary. |
| Voluntary support email | If the user emails the developer, the developer receives their email address, email metadata and whatever content/attachments they choose to send. No automatic app upload. | Document the exact release flow. If the app facilitates a developer-directed report, evaluate optional Email address, Emails, SMS or MMS and other actual included types; don't assume “voluntary” means exempt. A separate external support email is not proof of an in-app upload. |
| Public host-list download | Foreground HTTPS GET to a constant GitLab Pages URL. Source contains no SMS text, sender, message-derived host query, account token or app-added device-ID payload. | IP reaches third-party GitLab. Published logging evidence and the conservative declaration recommendation are below. |
| Preferences and blocklist cache | Protection/onboarding choices, last successful list-update time and downloaded hosts remain local. | No upload found. Last-success timing means failed attempts may recur on later launches; do not promise a strict cap on every request. |
| Ads, analytics, crash SDKs and account | No ads/analytics SDK, automatic crash-reporting service or account flow identified in inspected source/dependencies. | Confirm final dependency inventory and runtime traffic. No independent security review or badge is recorded. |

Source references: `lib/data/services/message_store.dart`, `incoming_message_processor.dart`, `android_sms_service.dart`, `blocklist_updater.dart`, `lib/domain/feedback_report.dart`, `lib/ui/sms/view_models/sms_view_model.dart`, `lib/main.dart`, `pubspec.yaml` and `pubspec.lock`. See the local file links in `README.md`.

**Feedback integration verified, 7 November 2026:** **37 focused UI tests**, **2 real-SQLite tests** and the **full 194-test Flutter suite passed**. Persistence/refresh on both routes, a fresh `recent()` read on the Report page, explicit awaited clipboard copying, error handling and absence of automatic sending are verified. Relevant wiring is in `lib/ui/shell/home_shell.dart` and `lib/ui/guard/widgets/feedback_report_page.dart`; backend `recordFeedback` uses the real store. Focused counts are not added to the full suite. Release context: [readiness](../google-play-readiness.md). Final Data safety form review remains required.

## External endpoint: inspected implementation and published evidence

Endpoint: `https://malware-filter.gitlab.io/malware-filter/phishing-filter-hosts.txt`.

The request is for a public host list, not a lookup of a particular SMS or link. It can occur when launching the Android app even before background SMS protection is enabled. Turning protection off does not itself disable this foreground download. The updater waits 12 hours after a successful update before another update; the receiver only reads the local list.

HTTPS protects traffic in transit, but it does not hide the source IP from GitLab's serving infrastructure. The request transmits network metadata while keeping SMS content and senders on the device.

**Published evidence, read directly on 7 November 2026:** the Pages section and purpose table establish the logging and fraud/abuse-prevention facts now attributed in both public policies, section 5. [GitLab Privacy Statement](https://about.gitlab.com/privacy/).

The published policy is not an independent audit of production deletion or unrelated publisher systems, and does not establish a processing contract between Azamat and GitLab. The seven-day period applies to the described Pages access logs, not support email or all possible recipients' copies.

**Location scope:** the app does not request device location or infer it from IP. GitLab's broader device-information provision allows possible location derivation, but does not establish its use for this specific download. [GitLab Privacy Statement](https://about.gitlab.com/privacy/). Do not infer either actual geolocation or a provider-wide promise of no geolocation from the Pages paragraph. The owner should consider that broader provision during final form review; add location if applicable use is established. Do not select location merely because a connection carries an IP. [Google: IP-address FAQ](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).

## Concrete recommendation for the automatic request

These are **proposed Console answers**, distinct from the published facts above. They deliberately declare the IP flow without relying on a contracted service-provider exemption. They apply to the blocklist download; voluntary reports must be assessed separately.

| Console field | Proposed answer | Reason / scope |
| --- | --- | --- |
| Does the app collect or share any required data types? | **Yes** | The automatic request exposes IP to GitLab and the provider describes retained access logs. Do not submit a global “no data” answer. |
| Data type | **Device or other IDs — network IP address** | Conservative identifier classification for the logged network address. This is our recommendation, not Google's categorical classification of every IP. No IMEI, advertising ID or app-added device ID is sent. |
| Collected? | **Yes** | Off-device receipt and logging by GitLab, even though Azamat does not receive these logs. |
| Shared? | **Yes — third-party GitLab** | No evidence establishes that GitLab processes this request solely under Azamat's instructions. Do not claim the service-provider sharing exemption. |
| Processed ephemerally? | **No** | The documented retained-log flow is not memory-only handling of a live request. |
| Required or optional? | **Required** | Foreground downloads have no app toggle. The SMS protection switch does not control them. Offline use is not an in-app collection opt-out. |
| Collection and sharing purpose | **App functionality** | The app uses the network request to obtain the local checking list. Network delivery/operation is the rationale, not a separate Console purpose. This follows from Qorğan's implementation, not an assertion about all GitLab activities. |
| Additional collection and sharing purpose | **Fraud prevention, security, and compliance** | Recommended mapping of the provider's stated Pages fraud/abuse-prevention purpose above. Do not add advertising, personalization or analytics without evidence for this flow. |
| Encrypted in transit? | **Yes, for this automatic app-controlled flow: HTTPS** | The configured URL and transport use HTTPS. No end-to-end-encryption or local-database-encryption claim is made. Review all release flows before answering globally. |
| Approximate / precise location | **No location type proposed solely for this request on the available evidence** | No app location processing; endpoint-specific provider inference is not established. Apply the owner-review qualification above rather than inventing it or guaranteeing its absence. |
| SMS or MMS / sender content | **No automatic collection or sharing through this request** | No SMS text, sender, verdict, message-derived URL or message key is included. Clipboard/email copies are separate voluntary flows. |

Short explanation for the owner to adapt if Console requests details:

> Qorğan automatically downloads a public phishing-host list over HTTPS from GitLab Pages when due on foreground launch. The request carries no SMS text, sender or app-added device identifier. Its network IP is exposed to GitLab and falls within the provider's published Pages logging practice. We propose declaring IP as Device or other IDs, collected and shared with GitLab, required and non-ephemeral, for App functionality and Fraud prevention, security, and compliance. This classification is subject to final owner review of the release and provider-policy scope.

## Resolve before submitting

1. Use signed release **1.0.0 (1)** and [release-verification.json](release-verification.json) for artifact hashes, identities and permissions. Reconcile the complete runtime dependency list and any additional serving hosts/headers with this worksheet. Do not put real SMS in a traffic trace.
2. Retain the dated official policy references above and recheck them if the endpoint or release changes. Published Pages logging evidence is available. Do not represent that policy review as a production infrastructure audit.
3. Owner reviews the proposed answers, including identifier classification, the broader location provision and the purpose mapping, against the live form. Record any evidence-supported changes and the reviewed release version.
4. Evaluate any additional off-device flows separately. A download classification does not settle clipboard, email, a changed dependency or a redirect to another recipient.
5. Carry the verified report-flow evidence into the final answer sheet: full-text report, explicit awaited clipboard copying, error handling and no automatic sending. External sharing/email remains a separate user action. Reassess if a developer-directed submission or automatic upload is introduced.
6. Reconcile the deployed RU/EN policy and in-app disclosure with the final answers. History clearing does not delete GitLab logs; Azamat does not control them. Confirm handling of support deletion requests. The provider's retention period does not establish a support-email retention period.
7. Save a dated final answer sheet with the owner's review. Do not submit this draft automatically or replace its affirmative IP declaration with an unchecked “No.”

## Evidence worksheet status

The table below records the preparation-stage questions. Final live-form selections have since been saved in [console-form-answers.md](console-form-answers.md), including **Yes** to collection/sharing and encrypted transit, **No** to accounts and the global deletion-request mechanism, and the two purpose selections. Owner review before submission remains pending.

| Question area | Answer status |
| --- | --- |
| Collects or shares required user-data types? | **Recommend Yes**, with the automatic IP answers above; owner review of final form selections remains. Report UI integration is confirmed. |
| SMS automatically uploaded for detection? | **No in inspected implementation.** This is a flow-specific finding, not a global form answer. |
| User account creation? | **No** in inspected implementation. Do not invent an account deletion workflow. |
| Encryption in transit? | The app-controlled list request uses HTTPS. Final global answer depends on the complete audited data flows. Do not claim end-to-end encryption or encrypted local SQLite. |
| Can users request deletion? | Local clear-history and uninstall; email contact for voluntarily sent support data. Owner must select the live form's deletion option using these mechanisms and the provider's published log retention, without promising Azamat can delete provider logs. |
| Independent security review? | **None supplied.** Do not claim a review badge. |
| Policy URL | [https://qorgan-web.vercel.app/privacy](https://qorgan-web.vercel.app/privacy) — **VERIFIED 7 November 2026**. Production READY with canonical alias; unauthenticated HTTP 200, no redirect/login, full RU/EN policy, Azamat/contact and GitLab seven-day logging disclosure present in rendered text. |

Verification recorded **7 November 2026**: public policy **VERIFIED**; website build/lint **PASSED on Next 16.4.5**; focused UI **37 PASSED**; real-SQLite **2 PASSED**; release-preparation Flutter suite **194 PASSED**. Signed **1.0.0 (1)** artifacts and static package checks are recorded in [release-verification.json](release-verification.json); release context is in [readiness](../google-play-readiness.md). Independent infrastructure audit and real-phone validation are not recorded. The owner subsequently authorised submission on **8 November 2026**; the last observed status and remaining checks are in [console-progress.md](console-progress.md).
