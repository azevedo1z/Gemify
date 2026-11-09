import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/application/clock.dart';
import 'package:gemify/data/drift_month_repository.dart';
import 'package:gemify/data/gemify_database.dart';
import 'package:gemify/domain/reference_month.dart';
import 'package:gemify/presentation/app.dart';
import 'package:gemify/presentation/providers.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first run, add items, close the month and read the history', (
    tester,
  ) async {
    final database = GemifyDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftMonthRepository(database, clock: systemClock);
    await repository.ensureOpenMonth(ReferenceMonth(2026, 11));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [monthRepositoryProvider.overrideWithValue(repository)],
        child: const GemifyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Entrada pendente'), findsOneWidget);

    await tester.tap(find.text('Entrada Mensal').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '480000',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Adicionar em Gastos Fixos'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome'),
      'Condomínio',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '75000');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Pão');
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '700');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(
      find.text('4.800,00 - (750,00 + 0,00 + 7,00) = 4.043,00'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('Fechar mês'), 200);
    await tester.tap(find.text('Fechar mês'));
    await tester.pumpAndSettle();
    final confirmClose = find.widgetWithText(FilledButton, 'Fechar mês');
    await tester.ensureVisible(confirmClose);
    await tester.pumpAndSettle();
    await tester.tap(confirmClose);
    await tester.pumpAndSettle();
    expect(find.text('dez/2026'), findsOneWidget);
    expect(find.text('Pão'), findsNothing);

    await tester.tap(find.byTooltip('Histórico'));
    await tester.pumpAndSettle();
    expect(find.text('nov/2026'), findsOneWidget);
  });
}
