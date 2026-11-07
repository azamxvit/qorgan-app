# Rule Core Cleanup and Three-State Risk — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strip every piece of demo and invented data out of the shipping app, then reshape the SMS rule into composable signal modules with a three-state verdict, so the blocklist (Phase C) and the Swift port (Phase D) have a stable target.

**Architecture:** The rule keeps living entirely on the device in `lib/domain`. Its two context-dependent parts — what a link points at, and who sent the message — move into `lib/domain/signals/` as standalone modules, because Phase C replaces the link module's host check with a blocklist lookup and Phase D reimplements both modules in Swift. The binary `block` flag becomes a three-state `MessageRisk` derived from the already-stored score, so there is no database migration (the store has no `onUpgrade` and cannot get one safely).

**Tech Stack:** Flutter 3.47.5, Dart SDK ^3.13.4, `flutter_test`, sqflite, shared_preferences.

## Global Constraints

- `MessageSignal` values may only be appended, never renamed or reordered: `lib/data/services/message_store.dart:55` reads stored rows with `MessageSignal.values.byName`, so an old row must still resolve after an update.
- No change to the `messages` table schema. `SqliteMessageStore` opens with `version: 1` and defines only `onCreate`; adding a column without an `onUpgrade` path breaks updates for existing users.
- `test/domain/sms_corpus.dart` is kept and is the only home for sample SMS text. No sample message may live in `lib/`.
- The precision gate in `test/domain/detector_metrics_test.dart` stays at `minPrecision = 1.0`. Tasks may not lower it.
- Every task ends with `flutter analyze` clean, `flutter test` green, and `dart format --output=none --set-exit-if-changed lib test` clean — these are exactly what `.github/workflows/checks.yml` runs.
- No `print` in `lib/`. The metrics report in `test/` is the one allowed exception and already carries `// ignore: avoid_print`.

---

## File Structure

**Deleted**
- `lib/ui/preview/design_preview.dart` (228 lines) — demo app with four fake SMS, reachable in the production binary via `--dart-define=QORGAN_PREVIEW=true`.
- `lib/ui/guard/widgets/guard_screen.dart` (127 lines) — dead since the light-UI redesign; referenced by nothing.
- `test/design_preview_test.dart` — exists only to render the deleted demo app.

**Created**
- `lib/domain/signals/sender_signals.dart` — classifies a sender string. Phase D mirrors this file in Swift.
- `lib/domain/signals/link_signals.dart` — extracts hosts from text and decides whether a host is a bank's own. Phase C adds the blocklist lookup here.

**Modified**
- `lib/main.dart` — drop the preview branch.
- `lib/domain/models/message_verdict.dart` — add `MessageRisk`.
- `lib/domain/inspect_message.dart` — compose the signal modules instead of holding the regexes itself.
- `lib/ui/core/copy.dart` — drop sample texts and three dead keys.
- `lib/ui/sms/widgets/sms_screen.dart` — drop the two sample buttons.
- `lib/ui/guard/view_models/guard_view_model.dart` — drop `simulate()` and the `sample` parameter.
- `lib/ui/messages/message_presentation.dart` — stop inventing sender names and titles.
- `lib/ui/core/light_components.dart` — `StatusPill` renders three states.
- `lib/ui/messages/protection_dashboard.dart` — count and show the watch state.
- `test/domain/sms_corpus.dart` — export two named fixtures for other tests.
- `test/guard_view_model_test.dart`, `test/launch_test.dart`, `test/ui_navigation_test.dart`, `test/domain/inspect_message_test.dart`, `test/data/incoming_message_processor_test.dart` — follow the production changes.
- `README.md`, `docs/light-ui-validation.md`, `docs/launch-ui-validation.md` — remove the preview instructions they currently document.

---

### Task 1 (выполнено): Move sample SMS text out of the app and into the corpus

Five test files import sample message text from `AppCopy`, which is why the text cannot simply be deleted from the app. Give the tests a home in the corpus first.

**Files:**
- Modify: `test/domain/sms_corpus.dart`
- Modify: `test/domain/inspect_message_test.dart:8,16`
- Modify: `test/data/incoming_message_processor_test.dart:15,33,40`

**Interfaces:**
- Consumes: `CorpusSms` from `test/domain/sms_corpus.dart`.
- Produces: `corpusPhishingSample` and `corpusOrdinarySample`, both `String`, importable as `import 'sms_corpus.dart';` from `test/domain/` and `import '../domain/sms_corpus.dart';` from `test/data/`.

- [x] **Step 1: Add the two named fixtures to the corpus**

Append to `test/domain/sms_corpus.dart`:

```dart
/// The two messages other tests reference by name. They used to live in
/// `AppCopy` and therefore shipped inside the app; sample text belongs here.
const corpusPhishingSample =
    'KASPI: Счёт заблокируют через 15 минут. Срочно подтвердите код: '
    'http://kaspi-secure.xyz/login';
const corpusOrdinarySample =
    'Halyk Bank: Поступление 20 000 ₸. Доступно 145 300 ₸.';
```

- [x] **Step 2: Point the domain test at the fixtures**

In `test/domain/inspect_message_test.dart`, replace the `AppCopy` import with `import 'sms_corpus.dart';`, then replace `AppCopy.phishingText` with `corpusPhishingSample` and `AppCopy.ordinaryText` with `corpusOrdinarySample`.

- [x] **Step 3: Point the processor test at the fixtures**

In `test/data/incoming_message_processor_test.dart`, replace the `AppCopy` import with `import '../domain/sms_corpus.dart';`, then replace all three `AppCopy.phishingText` / `AppCopy.ordinaryText` references.

- [x] **Step 4: Verify nothing changed behaviourally**

Run: `flutter test`
Expected: PASS, 48 tests. The fixture strings are byte-identical to the old `AppCopy` values, so scores must be unchanged — the processor test still expects `score == 11` and `score == 1`.

- [x] **Step 5: Commit**

```bash
git add test/domain/sms_corpus.dart test/domain/inspect_message_test.dart test/data/incoming_message_processor_test.dart
git commit -m "test: keep sample SMS text in the corpus, not in app copy"
```

---

### Task 2 (выполнено): Delete the demo mode, the dead screen, and the sample buttons

**Files:**
- Delete: `lib/ui/preview/design_preview.dart`, `lib/ui/guard/widgets/guard_screen.dart`, `test/design_preview_test.dart`
- Modify: `lib/main.dart:10,19-22`
- Modify: `lib/ui/core/copy.dart:20-24`
- Modify: `lib/ui/sms/widgets/sms_screen.dart:50-62`
- Modify: `lib/ui/guard/view_models/guard_view_model.dart`
- Modify: `lib/ui/shell/home_shell.dart:32`
- Modify: `test/guard_view_model_test.dart`, `test/launch_test.dart`
- Modify: `README.md`, `docs/light-ui-validation.md`, `docs/launch-ui-validation.md`

**Interfaces:**
- Produces: `GuardViewModel({required ProtectionRepository repository, required IncomingMessageService incomingMessages})` — the `sample` parameter is gone and `simulate()` no longer exists.

- [x] **Step 1: Write the failing test that no sample text ships in the app**

Create `test/no_demo_data_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Demo data in a security app is worse than no data: it teaches the user to
  // trust a screen that was never fed by their phone.
  test('no demo message, preview mode or sample button ships in lib/', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final marker in const [
        'QORGAN_PREVIEW',
        'design_preview',
        'previewMessages',
        'phishingText',
        'ordinaryText',
        'simulate',
      ]) {
        if (source.contains(marker)) offenders.add('${file.path}: $marker');
      }
    }

    expect(offenders, isEmpty);
  });
}
```

- [x] **Step 2: Run it to make sure it fails**

Run: `flutter test test/no_demo_data_test.dart`
Expected: FAIL listing `lib/main.dart: QORGAN_PREVIEW`, `lib/ui/preview/design_preview.dart: previewMessages`, `lib/ui/core/copy.dart: phishingText`, `lib/ui/sms/widgets/sms_screen.dart: phishingText`, `lib/ui/guard/view_models/guard_view_model.dart: simulate` and others.

- [x] **Step 3: Delete the demo files**

```bash
git rm lib/ui/preview/design_preview.dart lib/ui/guard/widgets/guard_screen.dart test/design_preview_test.dart
```

- [x] **Step 4: Remove the preview branch from the entry point**

In `lib/main.dart`, delete the `import 'ui/preview/design_preview.dart';` line and this block:

```dart
  if (const bool.fromEnvironment('QORGAN_PREVIEW')) {
    runApp(const QorganPreviewApp());
    return;
  }
```

- [x] **Step 5: Remove the sample texts and the dead keys from app copy**

In `lib/ui/core/copy.dart`, delete `phishingSample`, `ordinarySample`, `phishingText`, `ordinaryText`, and the three keys nothing reads: `guardLabel`, `smsLabel`, `passedWhileOff`.

- [x] **Step 6: Remove the sample buttons from the manual check screen**

In `lib/ui/sms/widgets/sms_screen.dart`, delete this widget and the `SizedBox` that follows it:

```dart
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _use(AppCopy.phishingText),
                  child: const Text(AppCopy.phishingSample),
                ),
                OutlinedButton(
                  onPressed: () => _use(AppCopy.ordinaryText),
                  child: const Text(AppCopy.ordinarySample),
                ),
              ],
            ),
            const SizedBox(height: 8),
```

If `_use` becomes unused after this, delete it too — `flutter analyze` will say so.

- [x] **Step 7: Remove simulate from the view model**

In `lib/ui/guard/view_models/guard_view_model.dart`, delete the `required this._sample` constructor parameter, the `final String _sample;` field, and `void simulate() => _onIncoming(_sample);`. Keep `_onIncoming`: the platform listener still calls it.

In `lib/ui/shell/home_shell.dart`, delete the `sample: AppCopy.phishingText,` argument at line 32.

- [x] **Step 8: Update the tests that constructed the view model with a sample**

In `test/guard_view_model_test.dart`, delete the `sample: AppCopy.phishingText,` argument from all five `GuardViewModel(...)` calls and drop the now-unused `AppCopy` import. If a test exercises `simulate()`, delete that test — the behaviour is gone, not broken.

In `test/launch_test.dart`, delete the whole `testWidgets('preview offers repeatable launch and renders original brand', ...)` block and the `import 'package:qorgan_app/ui/preview/design_preview.dart';` line.

- [x] **Step 9: Run the guard test and the full suite**

Run: `flutter test test/no_demo_data_test.dart && flutter test && flutter analyze`
Expected: the guard test PASSES, the suite is green, analyze reports no issues. Test count drops by the deleted preview tests.

- [x] **Step 10: Remove the preview instructions from the docs**

In `README.md`, delete the paragraph starting `Превью тех же компонентов с демонстрационными SMS:`, the fenced `flutter run -d web-server --web-port 8788 --dart-define=QORGAN_PREVIEW=true` block, the sentence referencing `artifacts/qorgan-light-preview.png` and `test/design_preview_test.dart`, and the `### Заставка Qorğan` paragraph sentence about the gallery at `http://127.0.0.1:8788/`. Keep the Manrope/OFL licence sentence — move it into the preceding paragraph.

In `docs/light-ui-validation.md`, delete the two sentences describing the 390×844 preview and the browser preview URL. In `docs/launch-ui-validation.md`, delete the bullet about the web preview at port 8788.

```bash
git rm artifacts/qorgan-light-preview.png
```

- [x] **Step 11: Commit**

```bash
git add -A
git commit -m "refactor: remove the demo mode, dead guard screen and sample buttons"
```

---

### Task 3 (выполнено): Stop inventing sender names and message titles

`senderName` returns `'Kaspi Bank'` or `'Halyk Bank'` for any sender containing those substrings and ignores every other bank. `messageTitle` returns `'Поступление на счёт'` for any text containing `поступ` — a phishing message that says "Вам поступление 150 000" gets a reassuring title.

**Files:**
- Modify: `lib/ui/messages/message_presentation.dart`
- Modify: `test/ui_navigation_test.dart:53`
- Test: `test/ui_message_presentation_test.dart` (create)

**Interfaces:**
- Produces: `String senderName(StoredMessage record)` returns the sender verbatim, or `'Неизвестный отправитель'` when it is blank. `String messageTitle(StoredMessage record)` is derived only from `record.verdict.signals` and never from the message text.

- [x] **Step 1: Write the failing tests**

Create `test/ui_message_presentation_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/ui/messages/message_presentation.dart';

StoredMessage record(String sender, String body) => StoredMessage(
  message: IncomingSms(sender: sender, body: body, timestamp: 1),
  verdict: inspectMessage(body, sender: sender),
);

void main() {
  test('the sender is shown as the network reported it', () {
    expect(senderName(record('BCC', 'Поступление 1000')), 'BCC');
    expect(senderName(record('KASPI', 'Поступление 1000')), 'KASPI');
    expect(senderName(record('  ', 'Поступление 1000')), 'Неизвестный отправитель');
  });

  test('a suspicious message never gets a reassuring title', () {
    final phishing = record(
      '+7 701 222 33 44',
      'Вам поступление 150 000 тг, получите на halyk-bonus.ru',
    );

    expect(phishing.verdict.block, isTrue);
    expect(messageTitle(phishing), isNot('Поступление на счёт'));
  });
}
```

- [x] **Step 2: Run them to make sure they fail**

Run: `flutter test test/ui_message_presentation_test.dart`
Expected: FAIL twice — `senderName` returns `'Kaspi Bank'` instead of `'KASPI'`, and `messageTitle` returns `'Поступление на счёт'` for the phishing message because its body contains `поступ`.

- [x] **Step 3: Rewrite both functions**

In `lib/ui/messages/message_presentation.dart`, replace both functions with:

```dart
/// The sender exactly as Android reported it. Mapping a sender to a bank name
/// would be a guess, and a guess here reads to the user as verification.
String senderName(StoredMessage record) {
  final sender = record.message.sender.trim();
  return sender.isEmpty ? 'Неизвестный отправитель' : sender;
}

/// Derived only from what the rule found. Reading the body for words like
/// "поступление" let a phishing message title itself as a normal transfer.
String messageTitle(StoredMessage record) {
  final signals = record.verdict.signals;
  if (signals.contains(MessageSignal.impersonation)) {
    return 'Пишут от имени банка';
  }
  if (signals.contains(MessageSignal.secret)) return 'Просят код';
  if (signals.contains(MessageSignal.pressure)) return 'Ограничение по счёту';
  if (signals.contains(MessageSignal.unofficialLink)) {
    return 'Ссылка в сообщении';
  }
  if (signals.contains(MessageSignal.prize)) return 'Обещают выигрыш';
  if (signals.contains(MessageSignal.payment)) return 'Просят оплатить';
  return 'Новое сообщение';
}
```

- [x] **Step 4: Run them to make sure they pass**

Run: `flutter test test/ui_message_presentation_test.dart`
Expected: PASS.

- [x] **Step 5: Fix the navigation test that tapped the invented name**

`test/ui_navigation_test.dart` taps `find.text('Kaspi Bank')`, which no longer exists. Its fixture sender is `'KASPI'`, so change the tap to `find.text('KASPI').first`.

- [x] **Step 6: Run the full suite**

Run: `flutter test && flutter analyze`
Expected: green and clean.

- [x] **Step 7: Commit**

```bash
git add -A
git commit -m "fix: show the real sender and derive titles from signals only"
```

---

### Task 4 (выполнено): Extract the sender and link signals into their own modules

Nothing about behaviour changes here. This is the seam Phase C plugs the blocklist into and Phase D mirrors in Swift.

**Files:**
- Create: `lib/domain/signals/sender_signals.dart`, `lib/domain/signals/link_signals.dart`
- Modify: `lib/domain/inspect_message.dart`
- Test: `test/domain/signals/link_signals_test.dart`, `test/domain/signals/sender_signals_test.dart` (create)

**Interfaces:**
- Produces: `bool isPersonalNumber(String sender)` from `lib/domain/signals/sender_signals.dart`; `Iterable<String> linkedHosts(String text)`, `bool isOfficialHost(String host)` and `const Set<String> officialHosts` from `lib/domain/signals/link_signals.dart`.
- `inspect_message.dart` keeps exporting `officialHosts` so existing importers do not break: add `export 'signals/link_signals.dart' show officialHosts;`.

- [x] **Step 1: Write the failing module tests**

Create `test/domain/signals/sender_signals_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/signals/sender_signals.dart';

void main() {
  test('a full mobile number is personal', () {
    expect(isPersonalNumber('+7 701 123 45 67'), isTrue);
    expect(isPersonalNumber('77011234567'), isTrue);
  });

  test('a short code or an alphanumeric name is not personal', () {
    expect(isPersonalNumber('1414'), isFalse);
    expect(isPersonalNumber('KASPI'), isFalse);
    expect(isPersonalNumber(''), isFalse);
  });
}
```

Create `test/domain/signals/link_signals_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/signals/link_signals.dart';

void main() {
  test('finds hosts with and without a scheme', () {
    expect(linkedHosts('перейдите https://verify.example/a'), ['verify.example']);
    expect(linkedHosts('получите на halyk-bonus.ru'), ['halyk-bonus.ru']);
  });

  test('ignores an email domain', () {
    expect(linkedHosts('пишите на support@qorgan-help.ru'), isEmpty);
  });

  test('a subdomain of a bank is official, a lookalike is not', () {
    expect(isOfficialHost('app.kaspi.kz'), isTrue);
    expect(isOfficialHost('kaspi.kz.verify.ru'), isFalse);
  });
}
```

- [x] **Step 2: Run them to make sure they fail**

Run: `flutter test test/domain/signals/`
Expected: FAIL to compile — `Error: Not found: 'package:qorgan_app/domain/signals/sender_signals.dart'`.

- [x] **Step 3: Create the sender module**

Create `lib/domain/signals/sender_signals.dart` and move the body of `_isPersonalNumber` from `inspect_message.dart` into it, renamed public:

```dart
/// A sender that is only digits and as long as a mobile number belongs to a
/// person, not to a bank: banks and services reach subscribers from short
/// codes or from alphanumeric sender names, which a private line cannot use.
bool isPersonalNumber(String sender) {
  final value = sender.replaceAll(RegExp(r'[\s()\-+]'), '');
  if (value.isEmpty || !RegExp(r'^\d+$').hasMatch(value)) return false;
  return value.length >= 10;
}
```

- [x] **Step 4: Create the link module**

Create `lib/domain/signals/link_signals.dart` with exactly this content, cut from `inspect_message.dart`. Phase C adds the blocklist check to this file, so it must own the whole notion of "what does this link point at".

```dart
/// Hosts a bank may legitimately link to. A missing entry turns a real bank
/// message into a false warning, so the list has to stay complete — verify it
/// against each bank and serve it remotely before release.
const officialHosts = {
  'kaspi.kz',
  'halykbank.kz',
  'halyk.kz',
  'homebank.kz',
  'bankffin.kz',
  'jusan.kz',
  'forte.kz',
  'bcc.kz',
  'eubank.kz',
  'nurbank.kz',
  'otbasybank.kz',
};

/// Top-level domains seen in Kazakhstani SMS, legitimate and otherwise. Used
/// only for hosts written without a scheme, so an unusual ending never hides a
/// link that spells out `http`.
const _bareHostTlds =
    'kz|ru|com|net|org|info|xyz|top|online|site|click|link|app|me|ly|su|cc|io'
    '|biz|pro|shop|store|live|icu|win';

final _schemedHost = RegExp(r'https?://([^\s/?#]+)');

/// Phishing SMS usually omit the scheme, so a host must also be recognised on
/// its own. Labels are ASCII, which keeps Cyrillic sentences from matching,
/// and the lookbehind keeps an email domain from reading as a link.
final _bareHost = RegExp(
  '(?<![a-z0-9@.\\-])((?:[a-z0-9][a-z0-9-]*\\.)+(?:$_bareHostTlds))'
  r'(?![a-z0-9-])',
);

/// Hosts named by the text, with userinfo and port removed.
Iterable<String> linkedHosts(String text) => [
  ..._schemedHost.allMatches(text).map((match) => match.group(1)!),
  ..._bareHost.allMatches(text).map((match) => match.group(1)!),
].map((host) => host.split('@').last.split(':').first);

bool isOfficialHost(String host) =>
    officialHosts.any((name) => host == name || host.endsWith('.$name'));
```

Note the escaping: `_bareHost` is built with a single-quoted interpolated string for the TLD list, so its backslashes are doubled, while `_schemedHost` and the trailing lookahead are raw strings. Copy it verbatim rather than retyping it.

- [x] **Step 5: Make the rule compose the modules**

In `lib/domain/inspect_message.dart`: delete the moved declarations, add

```dart
import 'signals/link_signals.dart';
import 'signals/sender_signals.dart';

export 'signals/link_signals.dart' show officialHosts;
```

and change the two call sites to `isPersonalNumber(sender)` and
`linkedHosts(text).any((host) => !isOfficialHost(host))`.

- [x] **Step 6: Run everything**

Run: `flutter test && flutter analyze && dart format --output=none --set-exit-if-changed lib test`
Expected: all green. The metrics line must still read `precision 1.00 … recall 1.00 — ложных тревог 0 из 25, пропущено 0 из 14`. A pure move cannot change it; if it did, the move was not pure.

- [x] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor: split sender and link signals out of the rule"
```

---

### Task 5 (выполнено): Replace the binary verdict with three risk states

Borrowed from `sms-fraud-detector`, which uses `PASS` / `PASS-WATCH` / `ESCALATE` / `BLOCK` rather than one boolean. Three states are enough here: notify, mark quietly, ignore. The middle state is what makes a borderline message cheap — no push, just a marker in the list.

**Files:**
- Modify: `lib/domain/models/message_verdict.dart`
- Modify: `test/domain/detector_metrics_test.dart`
- Test: `test/domain/message_risk_test.dart` (create)

**Interfaces:**
- Produces: `enum MessageRisk { clear, watch, warn }` and `MessageRisk get risk` on `MessageVerdict`. `bool get block` stays, redefined as `risk == MessageRisk.warn`, so the notification path in `incoming_message_processor.dart:35` and every current UI call site keep working unchanged.

- [x] **Step 1: Write the failing tests**

Create `test/domain/message_risk_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';

MessageVerdict scored(int score) =>
    MessageVerdict(score: score, signals: const []);

void main() {
  test('risk rises with the score at the documented thresholds', () {
    expect(scored(0).risk, MessageRisk.clear);
    expect(scored(2).risk, MessageRisk.clear);
    expect(scored(3).risk, MessageRisk.watch);
    expect(scored(4).risk, MessageRisk.warn);
    expect(scored(11).risk, MessageRisk.warn);
  });

  test('only the warn state notifies', () {
    expect(scored(3).block, isFalse);
    expect(scored(4).block, isTrue);
  });
}
```

- [x] **Step 2: Run them to make sure they fail**

Run: `flutter test test/domain/message_risk_test.dart`
Expected: FAIL to compile — `Error: Undefined name 'MessageRisk'`.

- [x] **Step 3: Add the risk states**

In `lib/domain/models/message_verdict.dart`, add above `MessageVerdict`:

```dart
/// What Qorgan does about a message.
///
/// Derived from the score, never stored: the `messages` table keeps `score`
/// and `signals` only, and it has no migration path for a new column.
enum MessageRisk {
  /// Nothing worth the user's attention.
  clear,

  /// Saved and marked in the list, but no notification. A borderline message
  /// costs the user a glance instead of an interruption.
  watch,

  /// Worth waking the phone for.
  warn,
}
```

and replace `bool get block => score >= 4;` with:

```dart
  MessageRisk get risk => switch (score) {
    >= 4 => MessageRisk.warn,
    >= 3 => MessageRisk.watch,
    _ => MessageRisk.clear,
  };

  bool get block => risk == MessageRisk.warn;
```

- [x] **Step 4: Run them to make sure they pass**

Run: `flutter test test/domain/message_risk_test.dart`
Expected: PASS.

- [x] **Step 5: Add a gate so the watch state cannot creep over legitimate traffic**

A middle state is only useful while it stays rare. Append to `test/domain/detector_metrics_test.dart`:

```dart
  test('the watch state stays rare on legitimate traffic', () {
    final clear = legitimateSms
        .where(
          (sms) =>
              inspectMessage(sms.body, sender: sms.sender).risk ==
              MessageRisk.clear,
        )
        .length;
    final share = clear / legitimateSms.length;
    // ignore: avoid_print
    print(
      'detector: ${(share * 100).round()}% легитимных сообщений — clear '
      '(${legitimateSms.length - clear} помечено watch)',
    );

    expect(share, greaterThanOrEqualTo(0.8));
  });
```

Add `import 'package:qorgan_app/domain/models/message_verdict.dart';` to that file.

- [x] **Step 6: Run the full suite**

Run: `flutter test && flutter analyze`
Expected: green. The new line reports `92% легитимных сообщений — clear (2 помечено watch)` — `Forte: срочно обновите приложение` and the OLX link both score 3. Precision and recall must be unchanged, because the `warn` threshold is still 4.

- [x] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: three risk states instead of a single block flag"
```

---

### Task 6 (выполнено): Show the watch state in the UI

Without this the middle state exists but is invisible, which is worse than not having it.

**Files:**
- Modify: `lib/ui/core/light_components.dart` (`StatusPill`)
- Modify: `lib/ui/messages/protection_dashboard.dart:28,205,247`
- Test: `test/ui_risk_display_test.dart` (create)

**Interfaces:**
- Consumes: `MessageRisk` from Task 5.
- Produces: `StatusPill({required MessageRisk risk, String? label, bool check, bool compact})` — the `suspicious` boolean parameter is replaced.

- [x] **Step 1: Write the failing test**

Create `test/ui_risk_display_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';
import 'package:qorgan_app/ui/core/light_components.dart';

void main() {
  Future<void> pump(WidgetTester tester, MessageRisk risk) => tester.pumpWidget(
    MaterialApp(home: Scaffold(body: StatusPill(risk: risk))),
  );

  testWidgets('each risk state has its own label', (tester) async {
    await pump(tester, MessageRisk.clear);
    expect(find.text('Можно пропустить'), findsOneWidget);

    await pump(tester, MessageRisk.watch);
    expect(find.text('Стоит посмотреть'), findsOneWidget);

    await pump(tester, MessageRisk.warn);
    expect(find.text('Подозрительно'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run it to make sure it fails**

Run: `flutter test test/ui_risk_display_test.dart`
Expected: FAIL to compile — `Error: No named parameter with the name 'risk'`.

- [x] **Step 3: Make StatusPill take a risk**

In `lib/ui/core/light_components.dart`, replace `final bool suspicious;` with `final MessageRisk risk;` and the constructor parameter `required this.suspicious` with `required this.risk`. Add the import for `message_verdict.dart`. Replace the two ternaries and the default label with:

```dart
  Color get _fill => switch (risk) {
    MessageRisk.warn => QorganColors.mint,
    MessageRisk.watch => QorganColors.pale,
    MessageRisk.clear => QorganColors.pale,
  };

  Color get _ink => switch (risk) {
    MessageRisk.warn => QorganColors.mintInk,
    _ => QorganColors.muted,
  };

  String get _label => switch (risk) {
    MessageRisk.warn => 'Подозрительно',
    MessageRisk.watch => 'Стоит посмотреть',
    MessageRisk.clear => 'Можно пропустить',
  };
```

and use `_fill`, `_ink`, `label ?? _label` in `build`.

- [x] **Step 4: Run it to make sure it passes**

Run: `flutter test test/ui_risk_display_test.dart`
Expected: PASS.

- [x] **Step 5: Update every StatusPill call site**

Run `flutter analyze` to list them; each `StatusPill(suspicious: record.verdict.block, ...)` becomes `StatusPill(risk: record.verdict.risk, ...)`.

In `lib/ui/messages/protection_dashboard.dart` line 28, replace the counters:

```dart
    final suspicious = messages
        .where((m) => m.verdict.risk == MessageRisk.warn)
        .length;
    final watched = messages
        .where((m) => m.verdict.risk == MessageRisk.watch)
        .length;
    final normal = messages.length - suspicious - watched;
```

Replace the `_CountPill` row so the middle state has a place to appear:

```dart
        Row(
          children: [
            Expanded(
              child: _CountPill(
                label: 'Можно пропустить',
                count: normal,
                mint: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CountPill(label: 'Стоит посмотреть', count: watched),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CountPill(label: 'Подозрительно', count: suspicious),
            ),
          ],
        ),
```

Three pills in one row at 390 px is tight — `test/ui_responsiveness_test.dart` checks for overflow and will say so. If it overflows, wrap the row in a `SingleChildScrollView(scrollDirection: Axis.horizontal, ...)` rather than shortening the labels.

In `_RecentRow`, the leading dot shows only for `verdict.block`; show it for the watch state too, so a marked message is visible without opening it:

```dart
          if (record.verdict.risk != MessageRisk.clear) ...[
            const MintDot(size: 5),
            const SizedBox(width: 8),
          ],
```

Add `import '../../domain/models/message_verdict.dart';` to the file if it is not already there.

- [x] **Step 6: Run everything**

Run: `flutter test && flutter analyze && dart format --output=none --set-exit-if-changed lib test`
Expected: all green and clean.

- [x] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: show the watch state in the list and the dashboard"
```

---

## Статус

Задачи 1–6 выполнены 2026-11-07. Проверено: `flutter analyze` без замечаний, `flutter test` — 59 тестов проходят, `dart format` без изменений. Метрики детектора не изменились ни на одном шаге: precision 1.00, recall 1.00, 92% легитимных сообщений в состоянии `clear`.

Отклонения от плана, принятые при исполнении:

- Задача 2 дополнительно убрала устаревшую инструкцию «на вкладке „Фон“» из `README.md` и `docs/android-phone-check.md`: такой вкладки нет с момента редизайна, по этой инструкции защиту на телефоне было не включить.
- Задача 2: в `test/launch_test.dart` утверждение `'Подозрительно · 7'` привязано к фактическому счёту (`NotificationLaunch.tappedVerdict.score`) вместо константы — старая фикстура жила в удалённом демо-файле.
- Задача 6: `messages_page.dart` держал собственное третье состояние со своим порогом (`score > 1`) и своим словом («Проверить»). Оно заменено на `risk`, иначе в приложении было бы два разных определения «посередине».
- Задача 6: для состояния `watch` взят существующий токен `QorganColors.backdrop`, а не `pale` из плана — три состояния обязаны отличаться не только подписью, это проверяет `test/ui_risk_display_test.dart`.

## Phases C and D — separate plans

Both depend on the rule shape this plan settles, so each gets its own plan once this one lands. The decisions already made are recorded here so they are not relitigated.

**Phase C — выполнено 2026-11-07.** Устройство и решения: [docs/blocklist.md](../../blocklist.md). 80 тестов проходят, `flutter analyze` чисто.

Одно отступление от договорённости, принятое осознанно: **криптографической подписи нет**, вместо неё только HTTPS, порог правдоподобия и необязательный SHA-256. Подписать чужой фид невозможно — для подписи нужен наш ключ и наша раздача списка. Взамен добавлена защита, которая работает уже сейчас: белый список банков побеждает блоклист, поэтому подменённый список не может вызвать ложную тревогу на настоящем банке. Путь к настоящей подписи описан в `docs/blocklist.md`.

Исходный план фазы C (для истории):

**Phase C — phishing blocklist, hybrid delivery.** A snapshot ships as a Flutter asset so a fresh install works with no network, and a signed update is fetched when a network is available. Requires adding `android.permission.INTERNET`, which the app deliberately does not have today — so it also requires a Play Data Safety declaration and a privacy-policy line saying the app fetches a domain list and sends no message content. The feed must be verified by signature, because a swapped list is itself an attack: it can whitelist the attacker. `lib/domain/signals/link_signals.dart` from Task 4 is the only place that learns about it. Candidate feeds: URLhaus plain-text dumps, `curbengh/phishing-filter` aggregate (OpenPhish + PhishTank, twice daily, gzip/brotli). A blocklist does not replace `officialHosts` — the whitelist prevents false alarms on real banks, the blocklist catches new attacker domains, and both are needed.

**Phase D — Swift port with parity tests.** `ILMessageFilterExtension` cannot run Dart, so the rule exists twice and the only defence against drift is a shared fixture. Export `test/domain/sms_corpus.dart` to a language-neutral `test/fixtures/sms_corpus.json`, have the Dart test read it instead of Dart literals, and have an XCTest read the same file; both must produce identical scores and risk states for every entry. Mirror `sender_signals.dart` and `link_signals.dart` as Swift files with the same function names. Only once parity is green does the `ILMessageFilterExtension` target get added — and note Apple's constraints: the extension only sees messages from senders not in the user's contacts, and it has no general network access (a deferred lookup to one declared URL is the only exception). Reference implementation: `afterxleep/Bouncer` (MIT, shipping, SwiftUI, on-device rules).
