import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/presentation/close_month/close_month_screen.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/providers.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/app_finders.dart';
import '../support/app_harness.dart';
import '../support/app_seeds.dart';

final Finder newIncome = field('Entrada');
final Finder closeButton = button('Fechar mês');

void main() {
  testApp(
    'a digit typed and then erased keeps the previous income',
    (app) async {
      await app.tap(find.text('Fechar mês'));
      await app.enter(newIncome, '5');
      expect(find.text(r'R$ 0,05 (informada)'), findsOneWidget);

      await app.backspace(newIncome);
      expect(find.text(r'R$ 4.800,00 (mantida)'), findsOneWidget);
      await app.tap(closeButton);

      expect(find.text('dez/2026'), findsOneWidget);
      expect(
        textOf(app.tester, const Key('auditLine')),
        startsWith('4.800,00 - ('),
      );
    },
    seed: seedSampleMonth,
  );

  testApp('closes with the income typed for the new month', (app) async {
    await app.tap(find.text('Fechar mês'));
    await app.enter(newIncome, '600000');
    expect(find.text(r'R$ 6.000,00 (informada)'), findsOneWidget);

    await app.tap(closeButton);

    expect(find.text('dez/2026'), findsOneWidget);
    expect(
      textOf(app.tester, const Key('auditLine')),
      startsWith('6.000,00 - ('),
    );
  }, seed: seedSampleMonth);

  testApp(
    'a failed close says so and keeps the month open',
    (app) async {
      await app.tap(find.text('Fechar mês'));
      await app.tap(closeButton);

      expect(app.tester.takeException(), isA<SqliteException>());
      expect(
        find.text('Erro. Nada foi alterado.'),
        findsOneWidget,
      );
      expect(isEnabled(app.tester, closeButton), isTrue);
      await app.tap(find.byType(BackButton));
      expect(find.text('nov/2026'), findsOneWidget);
    },
    seed: failingOn('months', seedSampleMonth),
  );

  testApp('back is ignored while the close is in progress', (app) async {
    await app.tap(find.text('Fechar mês'));
    app.repository.holdWrites();
    await app.tap(closeButton);

    await app.pressBack();
    expect(find.text('Fechar nov/2026'), findsOneWidget);

    app.repository.releaseWrites();
    await app.settle();
    expect(find.text('dez/2026'), findsOneWidget);
  }, seed: seedSampleMonth);

  testWidgets('a failed load of the open month is not a crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openMonthProvider.overrideWith(
            (ref) => Stream.error(Exception('load')),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CloseMonthScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Fechar mês'), findsOneWidget);
  });
}
