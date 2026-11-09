import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/calendar_date.dart';
import 'package:gemify/domain/reference_month.dart';
import 'package:gemify/domain/reference_window.dart';
import 'package:gemify/presentation/l10n/generated/app_localizations.dart';
import 'package:gemify/presentation/shared/reference_picker.dart';

final today = CalendarDate(2026, 11, 7);
final openWindow = ReferenceWindow.after(null, today: today);
final windowAfterOctober = ReferenceWindow.after(
  ReferenceMonth(2026, 10),
  today: today,
);
final windowWithinOneYear = ReferenceWindow.after(
  ReferenceMonth(2027, 5),
  today: today,
);

final class PickerResult {
  ReferenceMonth? picked;
}

Future<PickerResult> openPicker(
  WidgetTester tester, {
  required ReferenceMonth initial,
  required ReferenceWindow window,
}) async {
  final result = PickerResult();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result.picked = await pickReference(
            context,
            title: 'Título',
            confirmLabel: 'Salvar',
            initial: initial,
            window: window,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
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

bool saveEnabled(WidgetTester tester) =>
    tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Salvar'))
        .onPressed !=
    null;

void main() {
  testWidgets('saves only after a month is chosen and confirmed', (
    tester,
  ) async {
    final result = await openPicker(
      tester,
      initial: ReferenceMonth(2026, 11),
      window: windowAfterOctober,
    );

    await tester.tap(find.text('dez/2026'));
    await tester.pumpAndSettle();
    expect(find.text('Título'), findsOneWidget);
    expect(result.picked, isNull);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Título'), findsNothing);
    expect(result.picked, ReferenceMonth(2026, 12));
  });

  testWidgets('cancelling returns no reference', (tester) async {
    final result = await openPicker(
      tester,
      initial: ReferenceMonth(2026, 11),
      window: windowAfterOctober,
    );

    await tester.tap(find.text('dez/2026'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Título'), findsNothing);
    expect(result.picked, isNull);
  });

  testWidgets('offers only the months inside the window', (tester) async {
    await openPicker(
      tester,
      initial: ReferenceMonth(2026, 11),
      window: windowAfterOctober,
    );

    expect(find.text('out/2026'), findsNothing);
    expect(find.text('nov/2026'), findsOneWidget);
    expect(find.text('dez/2026'), findsOneWidget);
    expect(yearButtonEnabled(tester, 'Ano anterior'), isFalse);

    await tester.tap(find.byTooltip('Próximo ano'));
    await tester.pumpAndSettle();
    expect(find.text('fev/2027'), findsOneWidget);
    expect(find.text('mar/2027'), findsNothing);
    expect(yearButtonEnabled(tester, 'Próximo ano'), isFalse);
    expect(yearButtonEnabled(tester, 'Ano anterior'), isTrue);
  });

  testWidgets('hides the year arrows when the window fits in one year', (
    tester,
  ) async {
    await openPicker(
      tester,
      initial: ReferenceMonth(2027, 6),
      window: windowWithinOneYear,
    );

    expect(find.byTooltip('Ano anterior'), findsNothing);
    expect(find.byTooltip('Próximo ano'), findsNothing);
    expect(find.text('jun/2027'), findsOneWidget);
  });

  testWidgets('a reference outside the window starts unselected', (
    tester,
  ) async {
    await openPicker(
      tester,
      initial: ReferenceMonth(2030, 1),
      window: openWindow,
    );

    expect(find.text('2027'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });
}
