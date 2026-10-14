# Qorgan incoming-only fork

Source: pub.dev `another_telephony` 0.4.1, repository https://github.com/thanhdang198/Telephony. Distributed archive version 0.4.1 is the pinned provenance; its original MIT LICENSE is retained verbatim.

Local version: 0.4.1+qorgan.1. Retains upstream SMS broadcast → Flutter callback mechanism and incoming message mapping. Removes inbox queries, sending SMS, calls, location permission and associated controllers. Qorgan changes: awaited synchronous callback registration, goAsync lifetime with 9s timeout and completion callback, single cold engine initialization, Dart plugin registration, multipart body without trimming, foreground readiness gate, RECEIVE_SMS-only request, SDK version query, AGP 9 built-in Kotlin/Java 17 configuration.

Android package/channel names remain compatible with the incoming mechanism. The classifier lives in Qorgan, outside this plugin. SilverGuard and SpamBlocker were architecture references; their code and assets were not copied.

Upstream pub.dev archive SHA-256: `7dd16759099ea3e4ce762c4f5bbfa097940335555d5caa916aaa52eec6a70cb6`.
