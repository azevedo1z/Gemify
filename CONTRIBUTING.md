# Contributing

Gemify is a personal project, maintained by [@azevedo1z](https://github.com/azevedo1z). These are the conventions every change follows.

## Setup

Follow [Getting started](README.md#getting-started): install Flutter 3.41.6, then run `flutter pub get`, `dart run build_runner build` and `flutter gen-l10n`.

## Rules

- **Layers.** Business rules live only in `lib/domain`, in pure Dart, with no Flutter, Drift or `intl` imports and no clock reads. Dependencies point inward.
- **Money.** Always an integer number of cents (`Money`). Never `double`.
- **Text.** Identifiers in English. Every UI string goes in `lib/presentation/l10n/app_pt.arb`, in Brazilian Portuguese.
- **Code.** `flutter analyze` with no issues (`very_good_analysis`), and no comments in hand-written code.
- **Database.** A table change raises `schemaVersion`, comes with a migration and with `dart run drift_dev make-migrations`.
- **Tests.** Every behavior change comes with a test in the right layer, and `lib/domain` stays at 100% line coverage.

## Commits

Commits follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) in English (`feat: ...`, `fix: ...`, `refactor: ...`). The release notes are built from them, so the subject line is written for the person reading the release.

## Before pushing

```bash
flutter analyze
flutter test --coverage
dart run tool/check_domain_coverage.dart
```

To publish a version, see [Releases](README.md#releases).
