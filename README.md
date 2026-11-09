<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/brand/offmoney-logo-dark.png">
    <img src="assets/brand/offmoney-logo.png" width="320" alt="OffMoney">
  </picture>
</h1>

<p align="center">
  Personal monthly finance for Android: income, fixed, installment and variable expenses, a month close and a balance you can audit line by line. Offline, with no AI.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41.6-02569B?logo=flutter" alt="Flutter 3.41.6"/>
  <img src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart" alt="Dart 3.11"/>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" alt="Platform: Android"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License: MIT"/>
  <img src="https://img.shields.io/badge/status-early%20development-orange" alt="Status: early development"/>
  <img src="https://img.shields.io/badge/domain%20coverage-100%25-brightgreen" alt="Domain coverage: 100% of lines"/>
  <img src="https://img.shields.io/badge/network-none-lightgrey" alt="No network access"/>
</p>

<p align="center">
  <a href="README.pt-BR.md">Leia em português</a>
</p>

---

> [!NOTE]
> OffMoney is a personal tracking tool, not financial advice. Check your amounts and decisions yourself; the software comes with no warranty (see the [license](LICENSE)).

## Table of contents

- [Why OffMoney](#why-offmoney)
- [Features](#features)
- [How it works](#how-it-works)
- [Getting started](#getting-started)
- [Building a release](#building-a-release)
- [Releases](#releases)
- [Data and backup](#data-and-backup)
- [Architecture](#architecture)
- [Testing and code quality](#testing-and-code-quality)
- [Project status](#project-status)
- [Privacy](#privacy)
- [License](#license)

## Why OffMoney

OffMoney is a monthly budget that stays off the network. There is no account, no bank connection, no cloud and no AI: you type what comes in and what goes out, and the app does the arithmetic the same way every time.

- **Exact.** Amounts are integer cents, every rule has one implementation with tests, and every total is recomputed from the items.
- **Auditable.** The balance always shows the full calculation, and every change is logged with its old and new values.
- **Private.** Release builds have no internet permission; your data leaves the phone only when you export a backup.

The app interface is in Brazilian Portuguese.

## Features

- **Four fixed categories.** Entrada Mensal (monthly income), Gastos Fixos (fixed), Gastos Parcelados (installments) and Gastos Variáveis (variable), always in that order, each with its subtotal.
- **Audit line.** The balance is always shown as `(Entrada) - (Fixos + Parcelados + Variáveis) = Saldo`, with the values, pinned at the bottom of the screen.
- **Month close with a preview.** Before closing, the app lists every effect: variable expenses cleared, installments advancing or finishing, fixed expenses carried over, the closing balance and the next month's income.
- **Careful input.** A currency field filled from the right, with an empty state distinct from R$ 0,00; confirmation when an expense exceeds the remaining balance, when it looks like a duplicate, and before deleting.
- **History.** Closed months are read-only, with their own audit line.
- **Share.** A plain-text summary of any month, through the Android share sheet.
- **Backup.** A versioned JSON export of every month, expense and change, and an import that validates the whole file before replacing anything.
- **Change log.** Every write records the old and new values in the same transaction.
- **Theme.** Light, dark or following the system, chosen from the menu.

## How it works

Each month has a reference (for example `nov/2026`) and exactly one month is open at a time.

| Category | During the month | At the close |
|---|---|---|
| Entrada Mensal | One amount, editable | Kept for the next month unless a new one is typed |
| Gastos Fixos | Added, edited, deleted freely | Copied to the next month |
| Gastos Parcelados | Shown as `current/total`; the last one is marked "Final" | Advance one installment; finished purchases leave |
| Gastos Variáveis | Dated, never in the future | Cleared |

Closing applies everything in one database transaction, and a close cannot be undone. A second confirmation of the same close writes nothing.

The audit line for a month with R$ 4.800,00 of income reads:

```text
4.800,00 - (2.504,00 + 790,50 + 0,00) = 1.505,50
```

## Getting started

Requirements: Flutter 3.41.6 (Dart 3.11), the Android SDK and Java 17.

Generated code (Drift and translations) is not committed. After cloning, and whenever tables or UI strings change:

```bash
flutter pub get
dart run build_runner build
flutter gen-l10n
```

Then run the app on a device or emulator:

```bash
flutter run
```

Debug builds install as a separate app, `com.azevedo1z.gemify.debug` ("OffMoney Dev"), so development never touches the data of the installed release.

## Building a release

Release builds are signed with a keystore kept outside the repository. Create `android/key.properties` (ignored by Git):

```properties
storeFile=C:/path/to/offmoney-release.jks
storePassword=...
keyAlias=offmoney
keyPassword=...
```

Without this file the release build stops with an error, so an APK is never signed with a different key.

```bash
flutter build apk --release        # direct install
flutter build appbundle --release  # Google Play
flutter install --release
```

On Google Play, the app uses Play App Signing: Google signs what users download, and this keystore is the upload key. A lost upload key can be reset through Play Console support.

> [!WARNING]
> Keep a copy of the keystore and of `key.properties`. APKs installed outside Play are signed with this key directly: without it they cannot be updated, and reinstalling erases the app's data. Export a backup from the app before any reinstall.

## Releases

Releases follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and live only on [GitHub Releases](https://github.com/azevedo1z/Gemify/releases); there is no changelog file. Commits follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/), and the release notes are built from them. Pushing a `vX.Y.Z` tag runs the [release workflow](.github/workflows/release.yml), which checks that the tag matches the `version` in `pubspec.yaml` and creates the GitHub Release with notes grouped from the commits since the previous tag (features, fixes, other changes). Each release carries only the source code; signed builds are made locally (see [Building a release](#building-a-release)).

To cut a release:

1. Set `version: X.Y.Z+N` in `pubspec.yaml`. `X.Y.Z` is the version name and must match the tag; `N` is the build number (Android `versionCode`), which must be higher than the previous one for every Google Play upload.
2. Commit `chore(release): vX.Y.Z` and push to `master`.
3. Run `git tag vX.Y.Z` and `git push origin vX.Y.Z`.

The notes can be edited on the release page afterwards.

## Data and backup

- Data lives in a local SQLite database (Drift). CHECK constraints, foreign keys and a unique open month repeat the domain rules as a second line of defense.
- Android automatic backup and device transfer are off, so the JSON export is the only backup. The exported file is not encrypted: keep it somewhere safe.
- An import validates the whole file (format, version, integer amounts, months in order, every expense) and replaces all data in one transaction. An invalid file changes nothing.
- The schema is versioned in `drift_schemas/`. When tables change, raise `schemaVersion`, write the migration and run `dart run drift_dev make-migrations`.

## Architecture

```text
lib/
├── domain/        Pure Dart rules: money, months, expenses, validation, warnings, the close plan
├── application/   Use cases, the repository port, the clock and the backup codec
├── data/          Drift database and the repository implementation
└── presentation/  Riverpod providers, screens, shared widgets, theme and pt-BR strings
```

Dependencies point inward: the domain imports nothing from Flutter, Drift or `intl`, and it never reads the clock. Money is an integer number of cents everywhere, and every total is derived from the items on each read.

## Testing and code quality

```bash
flutter analyze
flutter test --coverage
dart run tool/check_domain_coverage.dart
flutter test integration_test
```

- Unit tests for the domain, with 100% line coverage enforced in CI.
- Data tests on an in-memory database: constraints, transactions, rollbacks and the close guard.
- Acceptance tests that run a full monthly cycle, from one close to the next, and check every total to the cent.
- Widget tests for every screen and flow, including failure paths.
- The integration test needs a connected device or emulator.
- `very_good_analysis` with no issues, and no comments in hand-written code.

[CI](.github/workflows/ci.yml) runs the analyzer, the tests and the coverage check on every push to `master` and on pull requests. One test checks that "today" is the local date and only runs in a time zone behind UTC, so CI sets `TZ=America/Sao_Paulo`.

## Project status

Early development (`0.x`), heading to Google Play. The database schema and the backup format may still change between minor versions, always with a migration or a documented import path.

## Privacy

OffMoney has no account, no analytics and no network access in release builds. See the [privacy policy](PRIVACY_POLICY.md). To report a security issue, see the [security policy](SECURITY.md).

## License

[MIT](LICENSE)
