# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Codex, Copilot) when working with code in this repository.

OffMoney is an offline Flutter app for Android (Flutter 3.41.6, Dart 3.11) for personal monthly finance, with deterministic rules and no AI. Identifiers, docs and commits are in English; the UI is in Brazilian Portuguese.

## Commands

Generated code (Drift `*.g.dart` and `lib/presentation/l10n/generated/`) is git-ignored. Regenerate after cloning and whenever tables or `.arb` strings change:

```bash
flutter pub get
dart run build_runner build
flutter gen-l10n
```

Checks (the same ones CI runs; all must pass before pushing):

```bash
flutter analyze                           # very_good_analysis, zero issues
flutter test --coverage
dart run tool/check_domain_coverage.dart  # fails unless lib/domain has 100% line coverage
```

- Single test file: `flutter test test/domain/money_test.dart`; single test: add `--plain-name "<test description>"`.
- Integration test (needs a device or emulator): `flutter test integration_test`.
- CI sets `TZ=America/Sao_Paulo`: one test (local "today" vs UTC) only runs in a time zone behind UTC.
- Schema change: raise `schemaVersion` in `lib/data/offmoney_database.dart`, write the migration, then `dart run drift_dev make-migrations` (schemas live in `drift_schemas/`).
- Debug builds install as `com.azevedo1z.gemify.debug` ("OffMoney Dev"). Release builds need `android/key.properties` (git-ignored) and fail without it.

## Architecture

Clean architecture with dependencies pointing inward: `presentation -> application -> domain`, and `data` implements the `application` port.

- `lib/domain/`: pure Dart business rules. No Flutter, Drift or `intl` imports, and no clock reads (`today` is always passed in). `Money` is integer cents; never use `double`. Totals (`MonthSummary`) are derived from the items on every read, never stored. `MonthClosing.plan` computes a `ClosePlan` (fixed expenses kept, installments advancing or finishing, variables cleared, next reference and income) or a `CloseError`; the same plan feeds both the close preview screen and the write.
- `lib/application/`: use cases as callable classes in `month_actions.dart` (`SaveExpense`, `CheckExpense`, `PrepareClose`, `ConfirmClose`, ...), the `MonthRepository` port, `Clock` (`systemClock` returns UTC; `todayFrom` converts to the local date), the rejection exceptions, and backup (`backup_codec.dart` validates a whole JSON file into a `BackupSnapshot` or a `BackupProblem` before anything is replaced).
- `lib/data/`: Drift `OffMoneyDatabase` (tables `months`, `expenses`, `change_log`) and `DriftMonthRepository`. Every write runs in one transaction and appends a `change_log` row with before/after JSON. CHECK constraints, foreign keys and the partial unique index `one_open_month` repeat the domain rules as a second line of defense. `applyClose` closes the month only if it is still open, otherwise it throws `CloseConflictException`, so a repeated confirmation writes nothing.
- `lib/presentation/`: Riverpod (`flutter_riverpod` 2.x) providers in `providers.dart` wire the use cases. `monthRepositoryProvider`, `themeModeStoreProvider` and `clockProvider` are overridden at startup (`startup.dart`, called from `main.dart`), which also ensures an open month exists. Screens watch repository streams (`openMonthProvider`, `monthProvider`, `closedMonthsProvider`). Every UI string goes in `lib/presentation/l10n/app_pt.arb`.

Domain invariants: exactly one open month at a time; categories always in the order income, fixed, installment, variable; the audit line is `(Entrada) - (Fixos + Parcelados + Variáveis) = Saldo`; a close is irreversible and atomic; variable expenses are dated and never in the future.

## Tests

- `test/` mirrors `lib/` by layer. `test/application/acceptance_test.dart` runs full monthly cycles and checks every total to the cent.
- Test doubles in `test/support/`: `MemoryRepository` is the real `DriftMonthRepository` over an in-memory SQLite database with a controllable `TestClock` (starts at 2026-11-07); `HoldableRepository` can hold writes to test in-flight UI states; `builders.dart` builds domain objects.
- Widget tests use `testApp(...)` from `app_harness.dart`, which pumps `OffMoneyApp` with all providers overridden, plus a `seed` callback to prepare data; use `app.wait(...)` to await database futures inside a widget test.
- Test data is invented (`sample_cycle.dart`). The repo is public: never put the owner's real names or amounts in it.

## Conventions

- No comments in hand-written code.
- Every behavior change comes with a test in the right layer.
- Commits follow Conventional Commits in English; GitHub Release notes are built from the subjects (`tool/release_notes.sh`), so write them for the release reader. There is no changelog file.
- Release: set `version: X.Y.Z+N` in `pubspec.yaml` (`N` must increase), commit `chore(release): vX.Y.Z`, push, then push tag `vX.Y.Z`. The release workflow rejects a tag that does not match `pubspec.yaml`.
