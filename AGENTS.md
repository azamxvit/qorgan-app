# Working agreements for agents in this repository

Qorğan warns a person about a phishing SMS on their own phone. Everything is
decided on the device. A wrong answer here is not a cosmetic bug: it either
scares someone away from a real bank message, or it reassures them about a
real attack.

Read this before editing. It is short on purpose.

## Who owns what

Two agents work in this tree at the same time. Staying inside your lane is the
difference between collaborating and overwriting each other's work.

**UI/UX agent owns:**
- `lib/ui/**`
- widget tests: `test/ui_*.dart`, `test/mobile_*.dart`, `test/launch_test.dart`
- `docs/superpowers/specs/*-mobile-ux-design.md`

**Functional agent owns:**
- `lib/domain/**` — the SMS rule and its signal modules
- `lib/data/**` — stores, services, the blocklist, the background SMS path
- `android/**`, `ios/**`, `pubspec.yaml`, `scripts/**`
- `test/domain/**`, `test/data/**`

**If your work needs a change on the other side of that line, do not make it.**
Add a `// NEEDS: <what and why>` comment at the call site and leave the call
unimplemented. An unimplemented call that fails loudly is better than a quiet
one that lies — see the first invariant below.

## Invariants

These are not style preferences. Each one is here because breaking it already
produced a real defect.

1. **Never report success for something that did not happen.** A method that
   returns `true`, shows a confirmation, or renders a "done" state must be
   reached only after the underlying operation actually completed. The
   "Очистить историю" action shipped reporting `История Qorğan очищена` while
   the SQLite table was untouched, because the call chain ended in an empty
   `Future<void> clearHistory() async {}`.

2. **Never substitute one message for another.** When a notification or a link
   selects a message by key and that key is not found, the answer is "no
   record", not "the most recent record". Attributing a verdict to the wrong
   SMS is the worst failure this app has, because the user is reading the text
   to decide whether to trust it.

3. **No sample, demo or placeholder message may exist in `lib/`.** Sample SMS
   text lives only in `test/domain/sms_corpus.dart`. Enforced by
   `test/no_demo_data_test.dart`. Do not invent a bank name, a sender or a
   message title that the data does not contain.

4. **`MessageSignal` and `MessageFeedback` are append-only.** Stored rows are
   read back with `.byName`, so renaming or reordering a value breaks every
   database already on a phone. Adding a `MessageSignal` also requires entries
   in all four UI maps — `test/ui_signal_copy_test.dart` will tell you.

5. **No schema change without `onUpgrade` and a migration test.** The pattern
   is in `test/data/message_store_migration_test.dart`: create a database at
   the old version, write a row, reopen through the production store, assert
   the row survived.

6. **The detector gate stays at `minPrecision = 1.0`.** A false warning on a
   real bank SMS teaches the user to ignore Qorğan. If a change makes
   `test/domain/detector_metrics_test.dart` fail, fix the rule, never the
   threshold. Add every real false alarm or missed message to the corpus first.

7. **No message content leaves the device.** The only network request in the
   app downloads a public host list from a constant URL (`docs/blocklist.md`).
   Message text, sender and device identifiers are never sent. A correction
   report is built locally and shared only by an explicit act of the user.

## Tests

A fake must never implement behaviour the production class does not have. The
`clearHistory` defect survived a passing test suite because the test double
deleted its own in-memory records while `AndroidSmsService` had no
implementation at all. If you write a fake for a method, check that the real
class overrides it.

Prefer a test against the real store (`sqflite_common_ffi`, see
`test/data/message_store_test.dart`) over a fake whenever the thing being
verified is persistence, deletion or migration.

## Verification

All three must pass before you call work done. These are exactly what CI runs
(`.github/workflows/checks.yml`):

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

`flutter test` prints a `detector:` line with precision and recall. Read it:
it is the only readable answer to whether the rule got better or worse.

## Do not commit or push

The owner commits. Leave the working tree dirty; do not run `git commit`,
`git push`, `git checkout` or anything else that rewrites history or discards
changes. There is a large amount of uncommitted work in this tree.

## Known-good context

- `README.md` — what the app does and how to run it
- `docs/blocklist.md` — blocklist delivery, integrity and data licence
- `docs/superpowers/plans/2026-11-07-rule-core-cleanup.md` — what the rule
  core looks like now and why
- `docs/android-phone-check.md` — how to verify on a real phone
