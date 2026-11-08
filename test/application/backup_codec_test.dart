import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/application/backup/backup_actions.dart';
import 'package:gemify/application/backup/backup_codec.dart';
import 'package:gemify/application/backup/backup_snapshot.dart';
import 'package:gemify/application/change_log_entry.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/domain/reference_month.dart';

import '../support/backup_fixture.dart';
import '../support/builders.dart';
import '../support/memory_repository.dart';

BackupReading read(Map<String, Object?> backup) =>
    BackupCodec.decode(jsonEncode(backup), today: defaultToday);

Map<String, Object?> month(Map<String, Object?> backup, int index) =>
    (backup['months']! as List<Object?>)[index]! as Map<String, Object?>;

void main() {
  test('accepts a valid file, including dateless items in closed months', () {
    final reading = read(validBackup());

    final snapshot = (reading as BackupAccepted).snapshot;
    expect(snapshot.months, hasLength(2));
    expect(snapshot.months.last.reference, ReferenceMonth(2026, 11));
    expect(
      snapshot.months.last.entries.last.expense,
      variable(
        'Pão',
        '7,00',
        on: defaultToday,
      ),
    );
    expect(snapshot.changeLog.single.action, ChangeAction.expenseCreated);
    expect(
      snapshot.months.first.entries.single.updatedAt,
      DateTime.utc(2026, 10, 3, 9, 30),
    );
  });

  test('accepts a file saved with a byte order mark', () {
    final reading = BackupCodec.decode(
      '\uFEFF${jsonEncode(validBackup())}',
      today: defaultToday,
    );

    expect(reading, isA<BackupAccepted>());
  });

  group('rejects, without writing anything,', () {
    final cases =
        <String, (BackupProblem, void Function(Map<String, Object?>))>{
          'a file of another app': (
            BackupProblem.notGemifyBackup,
            (backup) => backup['format'] = 'other',
          ),
          'an unknown version': (
            BackupProblem.unknownVersion,
            (backup) => backup['version'] = 2,
          ),
          'an amount written as a decimal': (
            BackupProblem.invalidStructure,
            (backup) => month(backup, 1)['incomeCents'] = 480000.0,
          ),
          'an amount written as text': (
            BackupProblem.invalidStructure,
            (backup) => month(backup, 1)['incomeCents'] = '480000',
          ),
          'an income above the cap': (
            BackupProblem.invalidStructure,
            (backup) => month(backup, 1)['incomeCents'] = 100000000000,
          ),
          'an unknown status': (
            BackupProblem.invalidStructure,
            (backup) => month(backup, 1)['status'] = 'paused',
          ),
          'a month 13': (
            BackupProblem.invalidStructure,
            (backup) => month(backup, 1)['reference'] = '2026-13',
          ),
          'a repeated id': (
            BackupProblem.invalidStructure,
            (backup) => month(backup, 1)['id'] = 1,
          ),
          'a repeated item id': (
            BackupProblem.invalidStructure,
            (backup) => _expenses(backup, 1)[1]['id'] = 11,
          ),
          'a month id of zero': (
            BackupProblem.invalidStructure,
            (backup) => month(backup, 1)['id'] = 0,
          ),
          'a negative item id': (
            BackupProblem.invalidStructure,
            (backup) => _expenses(backup, 1)[0]['id'] = -1,
          ),
          'an id that would exhaust the database sequence': (
            BackupProblem.invalidStructure,
            (backup) => month(backup, 1)['id'] = 9223372036854775807,
          ),
          'a change id above the limit': (
            BackupProblem.invalidStructure,
            (backup) => _changes(backup).single['id'] = 2147483648,
          ),
          'a missing field': (
            BackupProblem.invalidStructure,
            (backup) => month(backup, 1).remove('openedAt'),
          ),
          'a date that does not exist': (
            BackupProblem.invalidStructure,
            (backup) => _expenses(backup, 1)[1]['spentOn'] = '2026-02-30',
          ),
          'counters on a variable item': (
            BackupProblem.invalidStructure,
            (backup) => _expenses(backup, 1)[1]['totalInstallments'] = 2,
          ),
          'no open month': (
            BackupProblem.invalidTimeline,
            (backup) => month(backup, 1)
              ..['status'] = 'closed'
              ..['closedAt'] = '2026-11-07T12:00:00.000Z',
          ),
          'a closed month without a close time': (
            BackupProblem.invalidTimeline,
            (backup) => month(backup, 0)['closedAt'] = null,
          ),
          'two open months': (
            BackupProblem.invalidTimeline,
            (backup) => month(backup, 0)
              ..['status'] = 'open'
              ..['closedAt'] = null,
          ),
          'an open month that is not the latest': (
            BackupProblem.invalidTimeline,
            (backup) => month(backup, 1)['reference'] = '2026-09',
          ),
          'a repeated reference': (
            BackupProblem.invalidTimeline,
            (backup) => month(backup, 1)['reference'] = '2026-10',
          ),
          'a closed month without income': (
            BackupProblem.invalidTimeline,
            (backup) => month(backup, 0)['incomeCents'] = null,
          ),
          'an open month with a close time': (
            BackupProblem.invalidTimeline,
            (backup) =>
                month(backup, 1)['closedAt'] = '2026-11-07T12:00:00.000Z',
          ),
          'a dateless Variable item in the open month': (
            BackupProblem.invalidExpenses,
            (backup) => _expenses(backup, 1)[1]['spentOn'] = null,
          ),
          'an installment beyond its total': (
            BackupProblem.invalidExpenses,
            (backup) => _expenses(backup, 1)[0]['currentInstallment'] = 19,
          ),
          'an item amount of zero': (
            BackupProblem.invalidExpenses,
            (backup) => _expenses(backup, 1)[0]['amountCents'] = 0,
          ),
          'an item amount above the cap': (
            BackupProblem.invalidExpenses,
            (backup) => _expenses(backup, 0)[0]['amountCents'] = 100000000000,
          ),
          'a name with extra spaces': (
            BackupProblem.invalidExpenses,
            (backup) => _expenses(backup, 1)[1]['name'] = 'Pão ',
          ),
          'a name with a line break': (
            BackupProblem.invalidExpenses,
            (backup) => _expenses(backup, 1)[1]['name'] = 'Pão\nSaldo 9.999,00',
          ),
          'a change of a month not in the file': (
            BackupProblem.invalidChangeLog,
            (backup) => _changes(backup).single['monthId'] = 99,
          ),
        };

    for (final MapEntry(key: description, value: (problem, corrupt))
        in cases.entries) {
      test(description, () {
        final backup = validBackup();
        corrupt(backup);

        expect(
          read(backup),
          isA<BackupRejected>().having(
            (rejection) => rejection.problem,
            'problem',
            problem,
          ),
        );
      });
    }

    test('text that is not JSON', () {
      expect(
        (BackupCodec.decode('not json', today: defaultToday) as BackupRejected)
            .problem,
        BackupProblem.invalidStructure,
      );
    });
  });

  test('export then import gives back the same data', () async {
    final memory = await MemoryRepository.open();
    addTearDown(memory.close);
    await memory.repository.setIncome(brl('4.800,00'));
    await memory.repository.addExpense(installment('TV', '120,00', 8, 18));
    await memory.repository.addExpense(
      variable('Pão', '7,00', on: defaultToday),
    );
    memory.clock.advance();
    final tv = (await memory.repository.openMonth()).entries.first;
    await memory.repository.updateExpense(
      tv.id,
      installment('TV', '110,00', 8, 18),
    );
    final export = ExportBackup(memory.repository, memory.clock.call);

    final reading = ImportBackup(
      memory.repository,
      memory.clock.call,
    ).read(await export());

    final original = await memory.repository.snapshot();
    final restored = (reading as BackupAccepted).snapshot;
    expect(_describe(restored), _describe(original));
    expect(export.fileName(), 'gemify-backup-2026-11-07.json');
  });

  test('rejections describe themselves for diagnostics', () {
    expect(
      const BackupRejected(BackupProblem.unknownVersion).toString(),
      contains('unknownVersion'),
    );
  });
}

List<Map<String, Object?>> _expenses(Map<String, Object?> backup, int index) =>
    [
      for (final item in month(backup, index)['expenses']! as List<Object?>)
        item! as Map<String, Object?>,
    ];

List<Map<String, Object?>> _changes(Map<String, Object?> backup) => [
  for (final item in backup['changeLog']! as List<Object?>)
    item! as Map<String, Object?>,
];

List<Object?> _describe(BackupSnapshot snapshot) => [
  for (final Month month in snapshot.months)
    [
      month.id,
      month.reference,
      month.status,
      month.income,
      month.openedAt,
      month.closedAt,
      month.entries,
    ],
  for (final entry in snapshot.changeLog)
    [entry.id, entry.occurredAt, entry.monthId, entry.action, entry.after],
];
