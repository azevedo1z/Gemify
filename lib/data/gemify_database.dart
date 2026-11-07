import 'package:drift/drift.dart';

part 'gemify_database.g.dart';

@DataClassName('MonthRow')
@TableIndex.sql(
  "CREATE UNIQUE INDEX one_open_month ON months (status) WHERE status = 'open'",
)
class Months extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get referenceYear => integer()();

  IntColumn get referenceMonth => integer()();

  TextColumn get status => text()();

  IntColumn get incomeCents => integer().nullable()();

  DateTimeColumn get openedAt => dateTime()();

  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {referenceYear, referenceMonth},
  ];

  @override
  List<String> get customConstraints => const [
    'CHECK (reference_month BETWEEN 1 AND 12)',
    "CHECK (status IN ('open', 'closed'))",
    "CHECK ((status = 'open') = (closed_at IS NULL))",
    "CHECK (status = 'open' OR income_cents IS NOT NULL)",
    'CHECK (income_cents BETWEEN 0 AND 99999999999)',
  ];
}

@DataClassName('ExpenseRow')
@TableIndex(name: 'expenses_by_month', columns: {#monthId, #category})
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get monthId => integer().references(Months, #id)();

  TextColumn get category => text()();

  TextColumn get name => text()();

  IntColumn get amountCents => integer()();

  IntColumn get currentInstallment => integer().nullable()();

  IntColumn get totalInstallments => integer().nullable()();

  TextColumn get spentOn => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<String> get customConstraints => const [
    "CHECK (category IN ('fixed', 'installment', 'variable'))",
    'CHECK (amount_cents BETWEEN 1 AND 99999999999)',
    "CHECK ((category = 'installment') = (current_installment IS NOT NULL))",
    "CHECK ((category = 'installment') = (total_installments IS NOT NULL))",
    'CHECK (total_installments >= 2)',
    'CHECK (current_installment BETWEEN 1 AND total_installments)',
    "CHECK (category = 'variable' OR spent_on IS NULL)",
  ];
}

@DataClassName('ChangeLogRow')
class ChangeLog extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get occurredAt => dateTime()();

  IntColumn get monthId => integer().nullable().references(Months, #id)();

  TextColumn get action => text()();

  IntColumn get entityId => integer().nullable()();

  TextColumn get beforeJson => text().nullable()();

  TextColumn get afterJson => text().nullable()();
}

@DriftDatabase(tables: [Months, Expenses, ChangeLog])
class GemifyDatabase extends _$GemifyDatabase {
  GemifyDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
