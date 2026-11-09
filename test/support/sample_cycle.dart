import 'package:offmoney/domain/expense.dart';

import 'builders.dart';

final sampleFixedExpenses = <FixedExpense>[
  fixed('Reserva', '600,00'),
  fixed('Aluguel', '1.100,00'),
  fixed('Energia', '180,00'),
  fixed('Academia', '99,00'),
  fixed('Plano de saúde', '160,00'),
  fixed('Internet', '110,00'),
  fixed('Farmácia', '60,00'),
  fixed('Água', '85,00'),
  fixed('Celular', '45,00'),
  fixed('Seguro do celular', '25,00'),
  fixed('Streaming', '40,00'),
];

final sampleInstallmentsBeforeClose = <InstallmentExpense>[
  installment('Curso de inglês', '250,00', 2, 4),
  installment('TV', '120,00', 7, 18),
  installment('Óculos', '95,50', 2, 4),
  installment('Armário', '70,00', 9, 10),
  installment('Notebook', '150,00', 6, 10),
  installment('Monitor', '60,00', 6, 9),
  installment('Ingressos do show', '45,00', 6, 7),
  installment('Conserto do celular', '180,00', 3, 3),
  installment('Fone de ouvido', '90,00', 2, 2),
];

final sampleInstallmentsAfterClose = <InstallmentExpense>[
  installment('Curso de inglês', '250,00', 3, 4),
  installment('TV', '120,00', 8, 18),
  installment('Óculos', '95,50', 3, 4),
  installment('Armário', '70,00', 10, 10),
  installment('Notebook', '150,00', 7, 10),
  installment('Monitor', '60,00', 7, 9),
  installment('Ingressos do show', '45,00', 7, 7),
];

final sampleVariableBatches = <List<VariableExpense>>[
  [
    variable('Presente', '30,00', on: defaultToday),
    variable('Açaí com amigos', '64,00', on: defaultToday),
  ],
  [variable('Compras do mês', '520,00', on: defaultToday)],
  [variable('Mercado extra', '48,00', on: defaultToday)],
  [variable('Torneira', '55,00', on: defaultToday)],
  [
    variable('Café da manhã', '18,00', on: defaultToday),
    variable('Pão', '7,00', on: defaultToday),
  ],
  [variable('Jogo', '35,00', on: defaultToday)],
  [variable('Petiscos', '26,00', on: defaultToday)],
  [variable('Bolo', '22,00', on: defaultToday)],
  [variable('Veterinário', '110,00', on: defaultToday)],
];

const sampleBalancesAfterEachBatch = <String>[
  '1.411,50',
  '891,50',
  '843,50',
  '788,50',
  '763,50',
  '728,50',
  '702,50',
  '680,50',
  '570,50',
];
