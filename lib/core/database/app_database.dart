import 'package:drift/drift.dart';
import 'connection/connection.dart'
    if (dart.library.io) 'connection/native.dart'
    if (dart.library.html) 'connection/web.dart';

part 'app_database.g.dart';

// ═══════════════════════════════════════════
// TABLE: Income
// ═══════════════════════════════════════════
class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  TextColumn get incomeType => text()();
  RealColumn get amount => real()();
  BoolColumn get isNet => boolean().withDefault(const Constant(true))();
  RealColumn get inssDeducted => real().nullable()();
  RealColumn get irrfDeducted => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════
// TABLE: Expenses
// ═══════════════════════════════════════════
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  TextColumn get payType => text()();
  TextColumn get category => text()();
  TextColumn get subcategory => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text()();
  IntColumn get installments => integer().withDefault(const Constant(1))();
  BoolColumn get isFixed => boolean().withDefault(const Constant(false))();
  TextColumn get storeDescription => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════
// TABLE: Card Installments
// ═══════════════════════════════════════════
class CardInstallments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get totalValue => real()();
  IntColumn get numInstallments => integer()();
  IntColumn get currentInstallment => integer()();
  RealColumn get monthlyAmount => real()();
  TextColumn get status =>
      text().withDefault(const Constant('Active'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════
// TABLE: Investments
// ═══════════════════════════════════════════
class Investments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get productName => text()();
  TextColumn get institution => text()();
  DateTimeColumn get dateAdded => dateTime()();
  RealColumn get totalInvested => real()();
  RealColumn get currentBalance => real()();
  RealColumn get returnAmount => real().withDefault(const Constant(0.0))();
  TextColumn get liquidity => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════
// TABLE: Net Worth Snapshots
// ═══════════════════════════════════════════
class NetWorthSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  RealColumn get fgtsBalance => real().withDefault(const Constant(0.0))();
  RealColumn get investmentsTotal =>
      real().withDefault(const Constant(0.0))();
  RealColumn get emergencyFund =>
      real().withDefault(const Constant(0.0))();
  RealColumn get pendingInstallments =>
      real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════
// TABLE: Budget Goals
// ═══════════════════════════════════════════
class BudgetGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  RealColumn get targetPercentage => real()();
  RealColumn get targetAmount => real()();
  TextColumn get type => text()(); // Need | Want | Invest
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════
// TABLE: User Settings
// ═══════════════════════════════════════════
class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

// ═══════════════════════════════════════════
// DATABASE
// ═══════════════════════════════════════════
@DriftDatabase(tables: [
  Incomes,
  Expenses,
  CardInstallments,
  Investments,
  NetWorthSnapshots,
  BudgetGoals,
  UserSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // ═══════════════════════════════════════════
  // INCOME DAOs
  // ═══════════════════════════════════════════
  Future<List<Income>> getIncomesByMonth(int month, int year) {
    return (select(incomes)
          ..where((t) => t.month.equals(month) & t.year.equals(year)))
        .get();
  }

  Future<int> insertIncome(IncomesCompanion entry) {
    return into(incomes).insert(entry);
  }

  Future<bool> updateIncome(Income entry) {
    return update(incomes).replace(entry);
  }

  Future<int> deleteIncome(int id) {
    return (delete(incomes)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Income>> watchIncomesByMonth(int month, int year) {
    return (select(incomes)
          ..where((t) => t.month.equals(month) & t.year.equals(year)))
        .watch();
  }

  Future<List<Income>> getIncomesByRange(
      int startMonth, int startYear, int endMonth, int endYear) {
    return (select(incomes)
          ..where((t) =>
              (t.year.isBiggerThanValue(startYear) |
                  (t.year.equals(startYear) &
                      t.month.isBiggerOrEqualValue(startMonth))) &
              (t.year.isSmallerThanValue(endYear) |
                  (t.year.equals(endYear) &
                      t.month.isSmallerOrEqualValue(endMonth)))))
        .get();
  }

  // ═══════════════════════════════════════════
  // EXPENSE DAOs
  // ═══════════════════════════════════════════
  Future<List<Expense>> getExpensesByMonth(int month, int year) {
    return (select(expenses)
          ..where((t) => t.month.equals(month) & t.year.equals(year)))
        .get();
  }

  Future<int> insertExpense(ExpensesCompanion entry) {
    return into(expenses).insert(entry);
  }

  Future<bool> updateExpense(Expense entry) {
    return update(expenses).replace(entry);
  }

  Future<int> deleteExpense(int id) {
    return (delete(expenses)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Expense>> watchExpensesByMonth(int month, int year) {
    return (select(expenses)
          ..where((t) => t.month.equals(month) & t.year.equals(year))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<Expense>> getExpensesByRange(
      int startMonth, int startYear, int endMonth, int endYear) {
    return (select(expenses)
          ..where((t) =>
              (t.year.isBiggerThanValue(startYear) |
                  (t.year.equals(startYear) &
                      t.month.isBiggerOrEqualValue(startMonth))) &
              (t.year.isSmallerThanValue(endYear) |
                  (t.year.equals(endYear) &
                      t.month.isSmallerOrEqualValue(endMonth)))))
        .get();
  }

  Future<List<Expense>> getCashExpensesByMonth(int month, int year) {
    return (select(expenses)
          ..where((t) =>
              t.month.equals(month) &
              t.year.equals(year) &
              t.payType.equals('Cash')))
        .get();
  }

  Future<List<Expense>> searchExpenses(String query) {
    return (select(expenses)
          ..where((t) =>
              t.storeDescription.like('%$query%') |
              t.subcategory.like('%$query%') |
              t.category.like('%$query%')))
        .get();
  }

  // ═══════════════════════════════════════════
  // CARD INSTALLMENTS DAOs
  // ═══════════════════════════════════════════
  Future<List<CardInstallment>> getAllInstallments() {
    return select(cardInstallments).get();
  }

  Future<List<CardInstallment>> getActiveInstallments() {
    return (select(cardInstallments)
          ..where((t) => t.status.equals('Active')))
        .get();
  }

  Future<int> insertInstallment(CardInstallmentsCompanion entry) {
    return into(cardInstallments).insert(entry);
  }

  Future<bool> updateInstallment(CardInstallment entry) {
    return update(cardInstallments).replace(entry);
  }

  Future<int> deleteInstallment(int id) {
    return (delete(cardInstallments)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<CardInstallment>> watchActiveInstallments() {
    return (select(cardInstallments)
          ..where((t) => t.status.equals('Active')))
        .watch();
  }

  // ═══════════════════════════════════════════
  // INVESTMENTS DAOs
  // ═══════════════════════════════════════════
  Future<List<Investment>> getAllInvestments() {
    return select(investments).get();
  }

  Future<int> insertInvestment(InvestmentsCompanion entry) {
    return into(investments).insert(entry);
  }

  Future<bool> updateInvestment(Investment entry) {
    return update(investments).replace(entry);
  }

  Future<int> deleteInvestment(int id) {
    return (delete(investments)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Investment>> watchAllInvestments() {
    return select(investments).watch();
  }

  // ═══════════════════════════════════════════
  // NET WORTH SNAPSHOTS DAOs
  // ═══════════════════════════════════════════
  Future<NetWorthSnapshot?> getSnapshotByMonth(int month, int year) {
    return (select(netWorthSnapshots)
          ..where((t) => t.month.equals(month) & t.year.equals(year)))
        .getSingleOrNull();
  }

  Future<int> insertSnapshot(NetWorthSnapshotsCompanion entry) {
    return into(netWorthSnapshots).insert(entry);
  }

  Future<bool> updateSnapshot(NetWorthSnapshot entry) {
    return update(netWorthSnapshots).replace(entry);
  }

  Future<List<NetWorthSnapshot>> getAllSnapshots() {
    return (select(netWorthSnapshots)
          ..orderBy([
            (t) => OrderingTerm.asc(t.year),
            (t) => OrderingTerm.asc(t.month)
          ]))
        .get();
  }

  Future<void> upsertSnapshot(NetWorthSnapshotsCompanion entry) async {
    final existing = await getSnapshotByMonth(
      entry.month.value,
      entry.year.value,
    );
    if (existing != null) {
      await (update(netWorthSnapshots)
            ..where((t) => t.id.equals(existing.id)))
          .write(entry);
    } else {
      await into(netWorthSnapshots).insert(entry);
    }
  }

  // ═══════════════════════════════════════════
  // BUDGET GOALS DAOs
  // ═══════════════════════════════════════════
  Future<List<BudgetGoal>> getAllBudgetGoals() {
    return select(budgetGoals).get();
  }

  Future<int> insertBudgetGoal(BudgetGoalsCompanion entry) {
    return into(budgetGoals).insert(entry);
  }

  Future<bool> updateBudgetGoal(BudgetGoal entry) {
    return update(budgetGoals).replace(entry);
  }

  Future<int> deleteBudgetGoal(int id) {
    return (delete(budgetGoals)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<BudgetGoal>> watchBudgetGoals() {
    return select(budgetGoals).watch();
  }

  // ═══════════════════════════════════════════
  // USER SETTINGS DAOs
  // ═══════════════════════════════════════════
  Future<String?> getSetting(String key) async {
    final result = await (select(userSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  Future<Map<String, String>> getAllSettings() async {
    final results = await select(userSettings).get();
    return {for (var s in results) s.key: s.value};
  }
}
