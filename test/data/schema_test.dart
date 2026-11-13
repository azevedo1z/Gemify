import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/memory_repository.dart';

const _entities =
    'SELECT name, sql FROM sqlite_master '
    "WHERE name NOT LIKE 'sqlite_%' ORDER BY name";

List<String> _entitiesOf(Iterable<Map<String, Object?>> rows) => [
  for (final row in rows) '${row['name']}: ${row['sql']}',
];

void main() {
  test('the tables match the schema saved for the current version', () async {
    final memory = await MemoryRepository.open();
    addTearDown(memory.close);
    final version = memory.database.schemaVersion;
    final saved =
        jsonDecode(
              File(
                'drift_schemas/offmoney/drift_schema_v$version.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final expected = sqlite3.openInMemory();
    addTearDown(expected.close);
    for (final entity in saved['fixed_sql']! as List<Object?>) {
      final statements = (entity! as Map<String, Object?>)['sql']!;
      for (final statement in statements as List<Object?>) {
        expected.execute(
          (statement! as Map<String, Object?>)['sql']! as String,
        );
      }
    }

    final live = await memory.database.customSelect(_entities).get();

    expect(
      _entitiesOf([for (final row in live) row.data]),
      _entitiesOf(expected.select(_entities)),
    );
  });
}
