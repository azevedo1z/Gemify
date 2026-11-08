import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_finders.dart';
import '../support/app_harness.dart';

final Finder incomeTile = find.text('Entrada Mensal').first;
final Finder saveButton = button('Salvar');

void main() {
  testApp('back and taps outside are ignored while saving', (app) async {
    await app.tap(incomeTile);
    await app.enter(field('Valor'), '480000');
    app.repository.holdWrites();
    await app.tap(saveButton);

    await app.pressBack();
    await app.tap(find.byType(ModalBarrier).last);
    expect(find.byType(AlertDialog), findsOneWidget);

    app.repository.releaseWrites();
    await app.settle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(textOf(app.tester, const Key('balance')), r'R$ 4.800,00');
  });

  testApp('a failed save says so and allows another try', (app) async {
    await app.tap(incomeTile);
    await app.wait(app.memory.database.delete(app.memory.database.months).go());
    await app.enter(field('Valor'), '480000');

    await app.tap(saveButton);

    expect(app.tester.takeException(), isA<Exception>());
    expect(find.text('Erro. Nada foi alterado.'), findsOneWidget);
    expect(isEnabled(app.tester, saveButton), isTrue);
  });
}
