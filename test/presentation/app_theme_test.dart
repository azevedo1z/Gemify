import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/presentation/theme/app_theme.dart';

const wcagAANormalText = 4.5;

double contrast(Color first, Color second) {
  final luminances = [first.computeLuminance(), second.computeLuminance()]
    ..sort();
  return (luminances.last + 0.05) / (luminances.first + 0.05);
}

void main() {
  test('the light primary is the brand red', () {
    expect(AppTheme.light.colorScheme.primary, const Color(0xFFD52822));
  });

  for (final (mode, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    final scheme = theme.colorScheme;
    final surfaces = {
      'card': theme.cardTheme.color!,
      'background': theme.scaffoldBackgroundColor,
    };

    group('$mode theme', () {
      test('keeps errors in a red different from the primary', () {
        expect(scheme.error, isNot(scheme.primary));
      });

      for (final MapEntry(key: name, value: surface) in surfaces.entries) {
        test('primary and error text meet WCAG AA on the $name', () {
          expect(
            contrast(scheme.primary, surface),
            greaterThan(wcagAANormalText),
          );
          expect(
            contrast(scheme.error, surface),
            greaterThan(wcagAANormalText),
          );
        });
      }

      test('text on a primary button meets WCAG AA', () {
        expect(
          contrast(scheme.onPrimary, scheme.primary),
          greaterThan(wcagAANormalText),
        );
      });

      test('a destructive button is outlined in the error color', () {
        final style = AppTheme.destructive(scheme);

        expect(style.backgroundColor?.resolve({}), Colors.transparent);
        expect(style.foregroundColor?.resolve({}), scheme.error);
        expect(style.side?.resolve({})?.color, scheme.error);
      });

      test(
        'uses the display font only for the large title and the balance',
        () {
          final text = theme.textTheme;

          expect(text.headlineLarge?.fontFamily, AppTheme.displayFontFamily);
          expect(text.headlineSmall?.fontFamily, AppTheme.displayFontFamily);
          for (final readable in [
            text.titleMedium,
            text.bodyLarge,
            text.bodyMedium,
            text.labelLarge,
            theme.dialogTheme.titleTextStyle,
            theme.datePickerTheme.headerHeadlineStyle,
          ]) {
            expect(readable?.fontFamily, isNot(AppTheme.displayFontFamily));
          }
        },
      );

      test('every text style keeps tabular figures', () {
        final text = theme.textTheme;

        for (final style in [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
        ]) {
          expect(
            style?.fontFeatures,
            contains(const FontFeature.tabularFigures()),
          );
        }
      });
    });
  }
}
