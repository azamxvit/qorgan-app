# Google Play Closed Test Implementation Plan

> **For agentic workers:** Execute the approved release-preparation scope in the existing checkout. UI disclosure/privacy work is delegated to a UI agent; release tooling, signing, Android assets and evidence remain with the functional agent. No commits, pushes, resets or checkout changes.

**Goal:** Prepare a signed, inspected AAB retaining background SMS protection and truthful materials for the Google Play closed test and SMS declaration.

**Architecture:** Keep the current detector, SMS receiver, local history and blocklist. Make production signing explicit and fail closed when absent. Bundle complete privacy copy and show data disclosure before the existing SMS permission request. Prepare submission files locally; actual Play upload, external policy hosting, review approval and phone testing are reported separately.

**Tech Stack:** Flutter 3.47.5, Android API 36, AGP 9.1, Java 17-compatible toolchain, NDK 28.2.

**Spec:** `docs/google-play-readiness.md`, approved by the owner's instruction to fix blockers, prepare AAB and SMS application while keeping background protection.

## Global constraints

- Package ID `kz.qorgan.qorgan_app`; retain `RECEIVE_SMS` and the current background receiver.
- No `READ_SMS`, `SEND_SMS`, contacts, notification listener or Accessibility workaround.
- No invented identity, support contact, hosted URL, test participant, device result or independent benchmark.
- Reuse an existing upload key if the app already has an uploaded release; otherwise generate a private upload key after confirming first release. Never expose passwords in logs or Git.
- Owner confirmed first upload, developer Azamat, support omirtayazamatt@gmail.com and policy hosting on qorgan-web.vercel.app.
- Preserve other uncommitted work and AGENTS.md ownership boundaries.

## Review focus

- Missing signing input must fail release/AAB while ordinary debug development remains usable.
- A CI smoke artifact must never be mistaken for a Play-signed release.
- Data disclosure precedes SMS permission; declining or leaving must not grant permission or enable protection.
- Privacy text and declaration match actual local processing, user-controlled reports and external blocklist fetch.
- Submission material must distinguish automated/emulator verification from real-device or independent efficacy evidence.

## Tasks

- [x] Restore SDK/JDK in stable local storage; record reproducible commands and SDK package versions.
- [x] Configure release signing and a narrowly explicit CI smoke-signing option; add private key exclusions and build documentation.
- [x] UI agent: expand SMS disclosure and privacy screen without changing permission/service contracts; verify ordering and navigation.
- [x] Replace launcher assets with the existing Qorğan mark; prepare store icon and feature graphic using existing artwork.
- [x] Prepare RU/EN store copy, privacy HTML, Data safety worksheet, SMS declaration text, review instructions, video script and tester checklist. Resolve owner-supplied contact details before labeling these ready to submit.
- [x] Generate/reuse upload key securely; build AAB and APK from the same source, inspect manifest/certificate/native alignment, record SHA-256.
- [x] Run format/analyze/full tests and Android smoke/integration checks where available. Independent final review; fix material findings.
- [x] Update readiness report with exact deliverables and only remaining external/manual steps.

## Execution notes

Initial audit: 167 tests pass; SDK path points at a missing temporary directory; release uses debug signature; launcher is Flutter stock. Existing UI chat is completed. Functional and UI work will use disjoint files.

Final verification: 194 Flutter tests, format/analyze, 2 Python tests, signed AAB/APK and static 16 KB checks pass. Independent review finding (APK identity comparison) fixed and verified. Public policy deployed and anonymously checked HTTP 200. No connected Android device; phone run, video, Play submission/approval and tester enrollment remain external steps. No commit/push.
