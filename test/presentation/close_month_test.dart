import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
