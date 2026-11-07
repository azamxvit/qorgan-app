# Qorğan Privacy Policy

Date: 7 November 2026.

Developer: Azamat. For privacy, support and deletion of voluntarily submitted data: [omirtayazamatt@gmail.com](mailto:omirtayazamatt@gmail.com).

## 1. Scope

This policy covers the Qorğan Android mobile app, which checks SMS for phishing signals on the user's device. It does not describe other services on the Qorğan website. No account or registration is required. The mobile app has no ads or analytics SDKs and does not send automatic crash reports to the developer.

Qorğan gives warnings about possible risk. It does not block links or delete messages from your SMS app. An assessment can be wrong, and the absence of a warning does not establish that a message is authentic.

## 2. New SMS access and background use

Background checking is your choice. Before requesting permission, the app explains its access to new SMS; you can decline and use manual checking. Alerts require incoming SMS and notification permissions, followed by your separate action to enable protection.

While protection is enabled, Qorğan receives new incoming SMS text, sender information supplied by Android and the time of receipt. It uses these data for local assessment and displaying results, including when the app's screen is not open. It does not load the existing inbox from the system SMS app, send SMS or require becoming the default SMS app. Background alerts depend on permissions and Android restrictions.

## 3. Local processing and history

Text, sender information and links are checked using local rules and an on-device phishing-host list. Qorğan does not send an SMS, its sender or links from the message to a server to make the assessment.

The app's storage on your phone keeps up to 100 recent received SMS records: text, sender, receipt time, assessment, score and signals, notification state and any correction or fraud label you have saved. A local message key associates a record with its notification. Older records beyond this limit are removed when new ones are added. This is a record-count limit, not a period in days: remaining records stay until displaced, history is cleared or app data are removed.

Protection and onboarding preferences, the local host list and its last successful update time are also stored on the device. Marking an assessment as wrong does not itself send the message to the developer or automatically change the detection rule.

## 4. Manual checks and clipboard

Text you enter or paste for a manual check, and its result, are held in app memory. A draft may remain while moving between screens until you clear it or the app process exits. A manual check does not add that text to received-message history or upload it to a server. Pasting from the clipboard is triggered by your action.

The clipboard and your chosen keyboard are controlled by Android and the apps you use. If you copy text or use clipboard synchronization, those facilities may handle additional copies under their own rules.

## 5. Public host-list download

When launched in the foreground, Qorğan may download a public phishing-host list over HTTPS from this constant address: https://malware-filter.gitlab.io/malware-filter/phishing-filter-hosts.txt. After a successful update, the app waits at least 12 hours before another update; a failed attempt may be retried on a later launch. The background SMS handler uses the local list and does not make a network request for each message.

The GET request contains no SMS text, sender, assessment, link from the message being checked or app-added device identifier. However, GitLab infrastructure serving the list sees the network IP address and technical request information. HTTPS does not hide the IP from the receiving infrastructure. Qorğan does not request device location or infer it from IP.

According to [GitLab's policy, “GitLab Pages Data”](https://about.gitlab.com/privacy/), access logs contain IP, access time and visited page, retained for seven days with rolling deletion. Listed purposes include fraud and abuse prevention. This is published information checked on 7 November 2026, not an independent audit. That retention period is not a guarantee for other systems operated by the list publisher or other data recipients.

This download may occur whether or not background SMS checking is enabled. Turning protection off does not itself disable list downloads on app launch. Available local rules and the list can be used without a network connection.

## 6. Corrections, copied reports and support

A report about marked messages is generated locally. If you choose to copy such a report, it contains the full text of marked SMS, senders, receipt times, assessments, scores and signals, your labels and the report date. Copying to the clipboard is not automatic delivery to the developer.

Before pasting a report into email, a messenger or another external service, review and remove personal information, account numbers, phone numbers, passwords, verification codes and other people's details. The report is not automatically anonymized. You decide whether to send it, to whom and through which service; that service's rules apply to the transferred copy.

If you voluntarily email omirtayazamatt@gmail.com, the developer receives your email address, request content, email technical information and any attachments you select. These data are used to respond and investigate the problem you describe. There is no automatic SMS or report upload to support. Emails and attachments may remain in the mailbox until deleted; no fixed retention period has been established for these requests. To request deletion of data you voluntarily sent, email the same address and identify the request to locate, without resending the sensitive SMS.

## 7. Your controls and deletion

You can turn protection off in Qorğan and revoke SMS permission in Android settings. This limits further access but does not itself delete existing history.

The clear-history action in settings removes saved message copies and their associated labels from Qorğan. Original SMS remain in your messaging app. While protection is on, new incoming SMS may create new records, including during a history-clear operation.

Uninstalling Qorğan or clearing its data through Android removes local app data through the operating system's normal process. This does not delete original SMS, clipboard text, emails already sent or copies held by recipients you chose. Use the contact above to request deletion of data voluntarily sent to the developer. The developer can act on copies under their control, but does not control other people's mailboxes, external publications or GitLab infrastructure logs; limitations relevant to a specific request will be explained in the response.

## 8. Storage protection and backups

Local records are in app storage with access restricted by Android. We do not claim separate app-level database encryption. Your device lock and system settings help protect access to your data.

App backup is disabled in the Android configuration. This is a risk-reduction measure, not a guarantee across all devices: restore, device-to-device transfer and manufacturer tools can behave differently. Qorğan does not provide its own cloud SMS synchronization. We cannot guarantee that every device-transfer method excludes app data.

## 9. Contact and changes

For questions about this policy or deletion of voluntarily submitted data, contact Azamat at omirtayazamatt@gmail.com. This policy may change when data handling changes; the current revision is identified by the date at the top. Material changes in SMS access must also be reflected in the in-app explanation.
