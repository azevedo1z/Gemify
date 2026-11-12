import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/presentation/providers.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/app_finders.dart';
import '../support/app_harness.dart';
import '../support/app_seeds.dart';
import '../support/builders.dart';

final Finder saveButton = textButton('Salvar');
const duplicateWarning = 'Possível duplicata';
const addedToast = 'Gasto adicionado';

Future<void> newFixed(AppHarness app, String name, String digits) async {
  await app.tap(find.byTooltip('Adicionar em Gastos Fixos'));
  await app.enter(field('Nome'), name);
  await app.enter(field('Valor'), digits);
  await app.tap(saveButton);
}

void main() {
  testApp('adding an expense confirms it with a toast', (app) async {
    await app.tap(addVariableButton);
    await app.enter(field('Nome'), 'Pão');
    await app.enter(field('Valor'), '700');

    await app.tap(saveButton);

    expect(find.text('Pão'), findsOneWidget);
    expect(find.widgetWithText(SnackBar, addedToast), findsOneWidget);
  });

  testApp('editing an expense shows no toast', (app) async {
    await app.tap(find.text('Condomínio'));
    await app.enter(field('Valor'), '80000');

    await app.tap(saveButton);

    expect(find.text('Gasto fixo'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  }, seed: seedRent);

  testApp('a possible duplicate is saved only if confirmed', (app) async {
    await newFixed(app, 'condomínio', '1000');
    expect(find.text(duplicateWarning), findsOneWidget);
    await app.tap(find.text('Cancelar'));
    expect(find.text('Novo gasto fixo'), findsOneWidget);

    await app.tap(saveButton);
    await app.tap(find.text('Salvar').last);

    expect(find.text('condomínio'), findsOneWidget);
    expect(find.text('Condomínio'), findsOneWidget);
  }, seed: seedRent);

  testApp('every warning shows in a single dialog', (app) async {
    await newFixed(app, 'Condomínio', '50000');

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text(
        r'R$ 500,00 excede o saldo de R$ 250,00',
      ),
      findsOneWidget,
    );
    expect(find.text(duplicateWarning), findsOneWidget);
  }, seed: seedRent);

  testApp('an edit asks only when it adds more than the balance', (app) async {
    await app.tap(find.text('Condomínio'));
    await app.enter(field('Valor'), '120000');
    await app.tap(saveButton);
    expect(
      find.text(
        r'R$ 450,00 excede o saldo de R$ 250,00',
      ),
      findsOneWidget,
    );
    await app.tap(find.text('Cancelar'));

    await app.enter(field('Valor'), '100000');
    await app.tap(saveButton);

    expect(find.byType(AlertDialog), findsNothing);
    expect(textOf(app.tester, const Key('balance')), r'R$ 0,00');
  }, seed: seedRent);

  testApp(
    'renaming, lowering or deleting never asks about the balance',
    (app) async {
      await app.tap(find.text('Mercado'));
      await app.enter(field('Nome'), 'Supermercado');
      await app.enter(field('Valor'), '12000');
      await app.tap(saveButton);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Supermercado'), findsOneWidget);

      await app.tap(find.text('Supermercado'));
      await app.tap(find.text('Excluir'));
      expect(find.text('Excluir gasto?'), findsOneWidget);
      await app.tap(find.text('Excluir').last);

      expect(find.text('Supermercado'), findsNothing);
    },
    seed: (memory) async {
      await memory.repository.setIncome(brl('100,00'));
      await memory.repository.addExpense(
        variable('Mercado', '150,00', on: defaultToday),
      );
    },
  );

  testApp('rejects a date left in the future by the clock', (app) async {
    await app.tap(addVariableButton);
    await app.enter(field('Nome'), 'Pão');
    await app.enter(field('Valor'), '700');
    app.memory.clock.now = DateTime.utc(2026, 11, 6, 12);
    await app.tap(saveButton);
    expect(find.text('Data no futuro'), findsOneWidget);

    await app.tap(find.text('Data no futuro'));

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testApp('a double tap on save stores the item once', (app) async {
    await app.tap(addVariableButton);
    await app.enter(field('Nome'), 'Pão');
    await app.enter(field('Valor'), '700');

    await app.tester.tap(saveButton);
    await app.tester.tap(saveButton, warnIfMissed: false);
    await app.settle();

    expect(find.text('Pão'), findsOneWidget);
    final month = await app.wait(app.memory.repository.openMonth());
    expect(month.entries, hasLength(1));
  });

  testApp(
    'a failed save says so and keeps the form open',
    (app) async {
      await app.tap(addVariableButton);
      await app.enter(field('Nome'), 'Pão');
      await app.enter(field('Valor'), '700');
      await app.tap(saveButton);

      expect(app.tester.takeException(), isA<SqliteException>());
      expect(
        find.text('Erro. Nada foi alterado.'),
        findsOneWidget,
      );
      expect(find.text(addedToast), findsNothing);
      expect(find.text('Novo gasto variável'), findsOneWidget);
      expect(isEnabled(app.tester, saveButton), isTrue);
    },
    seed: failingOn('expenses'),
  );

  testApp(
    'names added in this session are suggested next time',
    (app) async {
      await app.tap(addVariableButton);
      await app.enter(field('Nome'), 'Farmácia');
      await app.enter(field('Valor'), '2000');
      await app.tap(saveButton);

      await app.tap(addVariableButton);
      await app.enter(field('Nome'), 'farm');

      expect(find.widgetWithText(ListTile, 'Farmácia'), findsOneWidget);
    },
    seed: (memory) => memory.repository.addExpense(
      variable('Pão', '7,00', on: defaultToday),
    ),
  );

  testApp('back is ignored while a save is in progress', (app) async {
    await app.tap(addVariableButton);
    await app.enter(field('Nome'), 'Pão');
    await app.enter(field('Valor'), '700');
    app.repository.holdWrites();
    await app.tap(saveButton);

    await app.pressBack();
    expect(find.text('Novo gasto variável'), findsOneWidget);

    app.repository.releaseWrites();
    await app.settle();
    expect(find.text('Pão'), findsOneWidget);
    expect(find.text('nov/2026'), findsOneWidget);
  });

  testApp(
    'saving an item deleted meanwhile says so and keeps the form open',
    (app) async {
      await app.tap(find.text('Condomínio'));
      final month = await app.wait(app.memory.repository.openMonth());
      await app.wait(
        app.memory.repository.deleteExpense(month.entries.single.id),
      );
      await app.enter(field('Valor'), '80000');

      await app.tap(saveButton);

      expect(app.tester.takeException(), isA<Exception>());
      expect(find.text('Erro. Nada foi alterado.'), findsOneWidget);
      expect(find.text('Gasto fixo'), findsOneWidget);
      expect(isEnabled(app.tester, saveButton), isTrue);
    },
    seed: seedRent,
  );

  testApp(
    'the form still works when the used names fail to load',
    (app) async {
      await app.tap(addVariableButton);
      await app.enter(field('Nome'), 'Pão');
      await app.enter(field('Valor'), '700');
      await app.tap(saveButton);

      expect(find.text('Pão'), findsOneWidget);
    },
    overrides: [
      usedNamesProvider.overrideWith(
        (ref, category) => Future.error(Exception('names')),
      ),
    ],
  );
}
