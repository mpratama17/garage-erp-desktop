import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/biaya/biaya_repo.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';

void main() {
  late AppDb db;
  late int tunai;
  late Map<String, ExpenseCategory> cat;
  final d = DateTime(2026, 10, 20);

  setUp(() async {
    db = AppDb(NativeDatabase.memory());
    tunai = (await (db.select(db.accounts)..where((a) => a.name.equals('Tunai'))).getSingle()).id;
    cat = {for (final c in await db.watchCategories().first) c.name: c};
  });
  tearDown(() => db.close());

  Future<int> add(String category, int amount, {DateTime? at}) => db.saveExpense(
    at: at ?? d,
    accountId: tunai,
    categoryId: cat[category]!.id,
    description: category,
    amount: amount,
  );

  test('kategori awal terisi, pribadi ditandai', () {
    expect(cat.length, defaultExpenseCategories.length);
    expect(cat['Listrik']!.personal, false);
    expect(cat['ART']!.personal, true);
  });

  test('biaya mengurangi saldo dan masuk arus kas; tanpa PIN owner pun bisa dicatat', () async {
    await add('Listrik', 250000);
    await add('ART', 100000, at: DateTime(2026, 10, 21));
    final rows = await db.watchExpenses(from: DateTime(2026, 10), to: DateTime(2026, 11)).first;
    expect(rows.map((r) => (r.entry.description, r.amount, r.personal, r.accountName)), [
      ('ART', 100000, true, 'Tunai'),
      ('Listrik', 250000, false, 'Tunai'),
    ]);
    final saldo = {for (final b in await db.watchBalances().first) b.account.name: b.balance};
    expect(saldo['Tunai'], -350000);
    final flow = await db.cashFlow(DateTime(2026), DateTime(2027), Period.monthly);
    expect(flow.single.expense, 350000);
  });

  test('ubah & hapus biaya hanya owner; hapus kas manual tidak bisa menghapus biaya', () async {
    final id = await add('Listrik', 250000);
    await expectLater(
      db.saveExpense(id: id, at: d, accountId: tunai, categoryId: cat['Air']!.id, description: 'Air', amount: 1),
      throwsArgumentError,
    );
    await expectLater(db.deleteExpense(id), throwsArgumentError);
    db.ownerUnlocked = true;
    await expectLater(db.deleteManualEntry(id), throwsArgumentError);
    await db.saveExpense(
      id: id,
      at: d,
      accountId: tunai,
      categoryId: cat['Air']!.id,
      description: 'PDAM',
      amount: 90000,
    );
    final e = (await db.watchExpenses(from: DateTime(2026), to: DateTime(2027)).first).single;
    expect((e.category!.name, e.entry.description, e.amount), ('Air', 'PDAM', 90000));
    await db.deleteExpense(id);
    expect(await db.select(db.cashEntries).get(), isEmpty);
  });

  test('aturan: nominal > 0, nama wajib, kategori nonaktif ditolak untuk biaya baru, nama kategori unik', () async {
    await expectLater(add('Listrik', 0), throwsArgumentError);
    await expectLater(
      db.saveExpense(at: d, accountId: tunai, categoryId: cat['Listrik']!.id, description: ' ', amount: 1),
      throwsArgumentError,
    );
    final id = await add('Wifi', 300000);
    db.ownerUnlocked = true;
    await db.saveCategory(
      ExpenseCategoriesCompanion(id: Value(cat['Wifi']!.id), name: const Value('Wifi'), active: const Value(false)),
    );
    await expectLater(add('Wifi', 1), throwsArgumentError);
    // Biaya lama dengan kategori yang sudah nonaktif tetap bisa diubah.
    await db.saveExpense(
      id: id,
      at: d,
      accountId: tunai,
      categoryId: cat['Wifi']!.id,
      description: 'Wifi',
      amount: 310000,
    );
    await expectLater(db.saveCategory(ExpenseCategoriesCompanion.insert(name: ' listrik ')), throwsArgumentError);
    db.ownerUnlocked = false;
    await expectLater(db.saveCategory(ExpenseCategoriesCompanion.insert(name: 'Parkir')), throwsArgumentError);
  });
}
