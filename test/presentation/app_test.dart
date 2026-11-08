import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/reference_month.dart';

import '../support/app_finders.dart';
import '../support/app_harness.dart';
import '../support/app_seeds.dart';
import '../support/builders.dart';

void main() {
  testApp('starts in Portuguese on the open month', (app) async {
    expect(find.text('nov/2026'), findsOneWidget);
    expect(
      Localizations.localeOf(app.tester.element(find.byType(Scaffold).first)),
      const Locale('pt'),
    );
  });

  testApp(
    'shows the sections in the Gem order and the audit line',
    (
      app,
    ) async {
      final tester = app.tester;
      final titles = [
        'Entrada Mensal',
        'Gastos Fixos',
        'Gastos Parcelados',
        'Gastos Variáveis',
        'Total de Gastos',
      ];
      final positions = [
        for (final title in titles) tester.getTopLeft(find.text(title)).dy,
      ];

      expect(positions, [...positions]..sort());
      expect(find.text(r'R$ 2.504,00'), findsWidgets);
      expect(find.text(r'R$ 790,50'), findsWidgets);
      expect(find.text('10/10 · Final'), findsOneWidget);
      expect(
        textOf(tester, const Key('auditLine')),
        '4.800,00 - (2.504,00 + 790,50 + 0,00) = 1.505,50',
      );
      expect(textOf(tester, const Key('balance')), r'R$ 1.505,50');
    },
    seed: seedSampleMonth,
  );

  testApp('a month without income shows it as pending', (app) async {
    expect(find.text('Entrada pendente'), findsOneWidget);
    expect(find.byKey(const Key('auditLine')), findsNothing);
  });

  testApp(
    'a negative balance is red, with a warning',
    (app) async {
      final balance = find.byKey(const Key('balance'));

      expect(find.text('Saldo negativo'), findsOneWidget);
      expect(
        app.tester.widget<Text>(balance).style?.color,
        Theme.of(app.tester.element(balance)).colorScheme.error,
      );
    },
    seed: (memory) async {
      await memory.repository.setIncome(brl('100,00'));
      await memory.repository.addExpense(
        variable('Mercado', '150,00', on: defaultToday),
      );
    },
  );

  testApp('sets the income from its tile', (app) async {
    await app.tap(find.text('Entrada Mensal').first);
    await app.enter(field('Valor'), '480000');
    await app.tap(find.text('Salvar'));

    expect(textOf(app.tester, const Key('balance')), r'R$ 4.800,00');
  });

  testApp('adds a variable expense from the floating button', (app) async {
    await app.tap(find.byType(FloatingActionButton));
    expect(find.text('Novo gasto variável'), findsOneWidget);
    expect(find.text('07/11/2026'), findsOneWidget);
    await app.enter(field('Nome'), '  Pão  ');
    await app.enter(field('Valor'), '700');
    await app.tap(find.text('Salvar'));

    expect(find.text('Pão'), findsOneWidget);
    expect(textOf(app.tester, const Key('balance')), r'R$ 1.498,50');
  }, seed: seedSampleMonth);

  testApp(
    'asks before saving more than the remaining balance',
    (app) async {
      await app.tap(find.byType(FloatingActionButton));
      await app.enter(field('Nome'), 'Geladeira');
      await app.enter(field('Valor'), '2000');
      await app.tap(find.text('Salvar'));
      expect(
        find.text(
          r'R$ 20,00 excede o saldo de R$ 10,00',
        ),
        findsOneWidget,
      );
      await app.tap(find.text('Cancelar'));
      await app.tap(find.byType(BackButton));
      expect(find.text('Geladeira'), findsNothing);

      await app.tap(find.byType(FloatingActionButton));
      await app.enter(field('Nome'), 'Geladeira');
      await app.enter(field('Valor'), '2000');
      await app.tap(find.text('Salvar'));
      await app.tap(find.text('Salvar').last);
      expect(find.text('Geladeira'), findsOneWidget);
      expect(find.text('Saldo negativo'), findsOneWidget);
    },
    seed: (memory) => memory.repository.setIncome(brl('10,00')),
  );

  testApp('shows the validation messages of the form', (app) async {
    await app.tap(find.byTooltip('Adicionar em Gastos Parcelados'));
    expect(
      app.tester.widget<TextField>(field('Parcela atual')).controller?.text,
      isEmpty,
    );
    await app.tap(find.text('Salvar'));
    expect(find.text('Obrigatório'), findsNWidgets(2));

    await app.enter(field('Parcela atual'), '1');
    await app.enter(field('Total de parcelas'), '1');
    await app.tap(find.text('Salvar'));
    expect(find.text('Informe o nome'), findsOneWidget);
    expect(find.text('Informe um valor'), findsOneWidget);
    expect(find.text('Mínimo de 2 parcelas'), findsOneWidget);
  });

  testApp(
    'edits and deletes an item, confirming the deletion',
    (app) async {
      await app.tap(find.text('Condomínio'));
      expect(find.text('Gasto fixo'), findsOneWidget);
      await app.enter(field('Valor'), '80000');
      await app.tap(find.text('Salvar'));
      expect(textOf(app.tester, const Key('balance')), r'R$ 200,00');

      await app.tap(find.text('Condomínio'));
      await app.tap(find.byTooltip('Excluir'));
      expect(find.text(r'Condomínio: R$ 800,00'), findsOneWidget);
      await app.tap(find.text('Excluir').last);

      expect(find.text('Condomínio'), findsNothing);
      expect(textOf(app.tester, const Key('balance')), r'R$ 1.000,00');
    },
    seed: (memory) async {
      await memory.repository.setIncome(brl('1.000,00'));
      await memory.repository.addExpense(fixed('Condomínio', '750,00'));
    },
  );

  testApp('the close is blocked while the income is missing', (app) async {
    await app.tap(find.text('Fechar mês'));

    expect(find.text('Informe a Entrada Mensal'), findsOneWidget);
  });

  testApp(
    'closes the month after the preview',
    (app) async {
      await app.tap(find.text('Fechar mês'));
      expect(find.text('Fechar nov/2026'), findsOneWidget);
      expect(find.text('dez/2026'), findsOneWidget);
      expect(find.text(r'R$ 4.800,00 (mantida)'), findsOneWidget);
      expect(row('Ingressos do show', '7/7'), findsOneWidget);
      expect(row('Monitor', '7/9 → 8/9'), findsOneWidget);
      expect(
        row('Variáveis zerados', r'1 item · R$ 7,00'),
        findsOneWidget,
      );
      expect(
        row('Fixos mantidos', r'11 itens · R$ 2.504,00'),
        findsOneWidget,
      );
      expect(row('Saldo final', r'R$ 1.498,50'), findsOneWidget);

      await app.enter(field('Entrada'), '0');
      expect(find.text(r'R$ 0,00 (informada)'), findsOneWidget);
      await app.enter(field('Entrada'), '');
      expect(find.text(r'R$ 4.800,00 (mantida)'), findsOneWidget);

      await app.tap(button('Fechar mês'));

      expect(find.text('dez/2026'), findsOneWidget);
      expect(find.text('Pão'), findsNothing);
      expect(find.text('Ingressos do show'), findsNothing);
      expect(find.text('8/9'), findsOneWidget);
    },
    seed: (memory) async {
      await seedSampleMonth(memory);
      await memory.repository.addExpense(
        variable('Pão', '7,00', on: defaultToday),
      );
    },
  );

  testApp('the history shows closed months read-only', (app) async {
    await app.tap(find.text('Fechar mês'));
    await app.tap(button('Fechar mês'));

    await app.tap(find.byTooltip('Histórico'));
    expect(find.text('nov/2026'), findsOneWidget);
    expect(find.text(r'R$ 4.800,00 - R$ 3.294,50'), findsOneWidget);
    expect(find.text(r'R$ 1.505,50'), findsOneWidget);
    await app.tap(find.text('nov/2026'));

    expect(find.text('Aluguel'), findsOneWidget);
    expect(
      textOf(app.tester, const Key('auditLine')),
      '4.800,00 - (2.504,00 + 790,50 + 0,00) = 1.505,50',
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsNothing);
    expect(find.text('Fechar mês'), findsNothing);
    await app.tap(find.text('Aluguel'));
    expect(find.text('Gasto fixo'), findsNothing);
  }, seed: seedSampleMonth);

  testApp('changes the reference of the open month', (app) async {
    await app.tap(find.text('nov/2026'));
    expect(find.text('Mês de referência'), findsOneWidget);
    await app.tap(find.text('dez/2026'));

    expect(find.text('dez/2026'), findsOneWidget);
    expect(find.text('nov/2026'), findsNothing);
    final month = await app.wait(app.memory.repository.openMonth());
    expect(month.reference, ReferenceMonth(2026, 12));
  });

  testApp('the reference cannot go back to a closed month', (app) async {
    await app.tap(find.text('dez/2026'));
    await app.tap(find.text('nov/2026'));

    expect(
      find.text('Escolha um mês após o último fechado'),
      findsOneWidget,
    );
    expect(find.text('dez/2026'), findsOneWidget);
  }, seed: closeNovember);

  testApp('the audit line stays in view while the list scrolls', (app) async {
    await app.usePhoneScreen();
    final auditLine = find.byKey(const Key('auditLine'));
    final incomeTitle = find.text('Entrada Mensal').hitTestable();
    final bottom = app.tester.getBottomLeft(auditLine).dy;
    expect(incomeTitle, findsOneWidget);

    await app.tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -5000),
    );
    await app.settle();

    expect(incomeTitle, findsNothing);
    expect(auditLine.hitTestable(), findsOneWidget);
    expect(app.tester.getBottomLeft(auditLine).dy, bottom);
    expect(
      bottom,
      lessThanOrEqualTo(
        AppHarness.phoneSize.height / AppHarness.phonePixelRatio,
      ),
    );
  }, seed: seedSampleMonth);

  testApp(
    'suggests names already used, applied only when tapped',
    (app) async {
      await app.tap(find.byType(FloatingActionButton));
      await app.enter(field('Nome'), 'pa');
      expect(find.widgetWithText(ListTile, 'Pão'), findsOneWidget);
      await app.tap(find.widgetWithText(ListTile, 'Pão'));

      expect(
        app.tester.widget<TextField>(field('Nome')).controller?.text,
        'Pão',
      );
    },
    seed: (memory) => memory.repository.addExpense(
      variable('Pão', '7,00', on: defaultToday),
    ),
  );

  testApp('follows the system theme by default', (app) async {
    expect(_themeMode(app), ThemeMode.system);
  });

  testApp('switches to the dark theme and saves the choice', (app) async {
    await app.tap(find.byIcon(Icons.more_horiz_rounded));
    await app.tap(find.text('Tema'));
    await app.tap(find.text('Escuro'));

    expect(_themeMode(app), ThemeMode.dark);
    expect(_brightness(app), Brightness.dark);
    expect(app.themeModeStore.stored, ThemeMode.dark);
  });

  testApp(
    'starts with the saved theme',
    (app) async {
      expect(_themeMode(app), ThemeMode.dark);
      expect(_brightness(app), Brightness.dark);
    },
    themeMode: ThemeMode.dark,
  );

  testApp('the about dialog shows the disclaimer and the licenses', (
    app,
  ) async {
    await app.tap(find.byIcon(Icons.more_horiz_rounded));
    await app.tap(find.text('Sobre'));
    expect(
      find.text(
        'Ferramenta de controle pessoal. Não é consultoria financeira.',
      ),
      findsOneWidget,
    );

    final context = app.tester.element(find.byType(AboutDialog));
    await app.tap(
      find.text(MaterialLocalizations.of(context).viewLicensesButtonLabel),
    );

    expect(find.byType(LicensePage), findsOneWidget);
  });
}

ThemeMode? _themeMode(AppHarness app) =>
    app.tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;

Brightness _brightness(AppHarness app) =>
    Theme.of(app.tester.element(find.byType(Scaffold).first)).brightness;
