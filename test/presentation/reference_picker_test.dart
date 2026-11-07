import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/reference_month.dart';
import 'package:gemify/presentation/l10n/generated/app_localizations.dart';
import 'package:gemify/presentation/shared/reference_picker.dart';

Future<void> openPicker(WidgetTester tester, ReferenceMonth initial) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => pickReference(context, initial: initial),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

bool yearButtonEnabled(WidgetTester tester, String tooltip) =>
    tester
        .widget<IconButton>(
          find.ancestor(
            of: find.byTooltip(tooltip),
            matching: find.byType(IconButton),
          ),
        )
        .onPressed !=
    null;

void main() {
  testWidgets('the year stops at the last supported one', (tester) async {
    await openPicker(tester, ReferenceMonth(ReferenceMonth.lastYear, 1));

    expect(yearButtonEnabled(tester, 'Próximo ano'), isFalse);
    expect(yearButtonEnabled(tester, 'Ano anterior'), isTrue);
  });

  testWidgets('the year stops at the first supported one', (tester) async {
    await openPicker(tester, ReferenceMonth(ReferenceMonth.firstYear, 1));

    expect(yearButtonEnabled(tester, 'Ano anterior'), isFalse);
    expect(yearButtonEnabled(tester, 'Próximo ano'), isTrue);
  });
}
