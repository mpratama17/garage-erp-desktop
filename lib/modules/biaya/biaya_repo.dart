import 'package:drift/drift.dart';

import '../../db/database.dart';

/// Biaya = baris buku kas berjenis `expense` (nominal minus); refId menunjuk kategori.
/// Tidak ada tabel biaya terpisah: tanggal, rekening, nominal, keterangan, bukti sudah ada di cash_entries.
const expenseKind = 'expense';

class ExpenseRow {
  ExpenseRow(this.entry, this.category, this.accountName);
  final CashEntry entry;
  final ExpenseCategory? category;
  final String accountName;

  int get amount => -entry.amount; // positif untuk ditampilkan
  bool get personal => category?.personal ?? false;
}

extension BiayaRepo on AppDb {
  Selectable<ExpenseCategory> categoriesQuery() =>
      select(expenseCategories)..orderBy([(c) => OrderingTerm.asc(c.personal), (c) => OrderingTerm.asc(c.name)]);

  Stream<List<ExpenseCategory>> watchCategories() => categoriesQuery().watch();

  /// Biaya pada [from, to), terbaru di atas.
  Stream<List<ExpenseRow>> watchExpenses({required DateTime from, required DateTime to}) {
    final q =
        select(cashEntries).join([
            innerJoin(accounts, accounts.id.equalsExp(cashEntries.accountId)),
            leftOuterJoin(expenseCategories, expenseCategories.id.equalsExp(cashEntries.refId)),
          ])
          ..where(
            cashEntries.kind.equals(expenseKind) &
                cashEntries.at.isBiggerOrEqualValue(from) &
                cashEntries.at.isSmallerThanValue(to),
          )
          ..orderBy([OrderingTerm.desc(cashEntries.at), OrderingTerm.desc(cashEntries.id)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          ExpenseRow(r.readTable(cashEntries), r.readTableOrNull(expenseCategories), r.readTable(accounts).name),
      ],
    );
  }

  /// Catat biaya baru ([id] null; siapa saja) atau ubah biaya lama (owner).
  /// Rekening/kategori nonaktif hanya ditolak bila baru dipilih — biaya lama tetap bisa diubah.
  Future<int> saveExpense({
    int? id,
    required DateTime at,
    required int accountId,
    required int categoryId,
    required String description,
    required int amount,
    String note = '',
    String proofPath = '',
  }) => transaction(() async {
    if (amount <= 0) throw ArgumentError('Nominal harus lebih dari 0');
    if (description.trim().isEmpty) throw ArgumentError('Nama biaya wajib diisi');
    CashEntry? old;
    if (id != null) {
      requireOwner();
      old = await (select(cashEntries)..where((e) => e.id.equals(id))).getSingleOrNull();
      if (old == null || old.kind != expenseKind) throw ArgumentError('Biaya tidak ditemukan');
    }
    if (old?.accountId != accountId) await requireActiveAccount(accountId);
    if (old?.refId != categoryId) {
      final cat = await (select(expenseCategories)..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      if (cat == null || !cat.active) throw ArgumentError('Kategori tidak ditemukan atau nonaktif');
    }
    final data = CashEntriesCompanion(
      at: Value(at),
      accountId: Value(accountId),
      amount: Value(-amount),
      kind: const Value(expenseKind),
      refId: Value(categoryId),
      description: Value(description.trim()),
      note: Value(note.trim()),
      proofPath: Value(proofPath),
    );
    if (id == null) return into(cashEntries).insert(data);
    await (update(cashEntries)..where((e) => e.id.equals(id))).write(data);
    return id;
  });

  Future<void> deleteExpense(int id) async {
    requireOwner();
    final n = await (delete(cashEntries)..where((e) => e.id.equals(id) & e.kind.equals(expenseKind))).go();
    if (n == 0) throw ArgumentError('Biaya tidak ditemukan');
  }

  /// Tambah/ubah kategori (owner). Nama unik tanpa membedakan huruf besar/kecil.
  /// Kategori tidak dihapus, cukup dinonaktifkan — biaya lama tetap menunjuknya.
  Future<int> saveCategory(ExpenseCategoriesCompanion c) async {
    requireOwner();
    final name = c.name.value.trim();
    if (name.isEmpty) throw ArgumentError('Nama kategori wajib diisi');
    final dup =
        await (select(expenseCategories)..where(
              (x) =>
                  x.name.lower().equals(name.toLowerCase()) &
                  (c.id.present ? x.id.equals(c.id.value).not() : const Constant(true)),
            ))
            .get();
    if (dup.isNotEmpty) throw ArgumentError('Kategori "$name" sudah ada');
    final data = c.copyWith(name: Value(name));
    if (c.id.present) {
      await (update(expenseCategories)..where((x) => x.id.equals(c.id.value))).write(data);
      return c.id.value;
    }
    return into(expenseCategories).insert(data);
  }

  // ---- biaya berulang (v3) ----

  Stream<List<RecurringExpense>> watchRecurring() =>
      (select(recurringExpenses)..orderBy([(r) => OrderingTerm.asc(r.name)])).watch();

  /// Tambah/ubah templat biaya berulang (owner).
  Future<int> saveRecurring(RecurringExpensesCompanion r) => transaction(() async {
    requireOwner();
    if (r.name.value.trim().isEmpty) throw ArgumentError('Nama biaya berulang wajib diisi');
    if (r.amount.value <= 0) throw ArgumentError('Nominal harus lebih dari 0');
    final data = r.copyWith(name: Value(r.name.value.trim()));
    if (r.id.present) {
      await (update(recurringExpenses)..where((x) => x.id.equals(r.id.value))).write(data);
      return r.id.value;
    }
    return into(recurringExpenses).insert(data);
  });

  /// Catat biaya dari templat [templateId] pada tanggal [at]: satu biaya per pegawai di [employeeIds]
  /// (templat per-pegawai), atau satu biaya saja. Nama biaya = "templat — pegawai". Siapa saja boleh mencatat
  /// (seperti biaya biasa); semua atau tidak sama sekali. Mengembalikan jumlah biaya yang dicatat.
  Future<int> recordRecurring(int templateId, DateTime at, {List<int> employeeIds = const []}) => transaction(() async {
    final t = await (select(recurringExpenses)..where((x) => x.id.equals(templateId))).getSingleOrNull();
    if (t == null || !t.active) throw ArgumentError('Biaya berulang tidak ditemukan atau nonaktif');
    if (!t.perEmployee) {
      await saveExpense(
        at: at,
        accountId: t.accountId,
        categoryId: t.categoryId,
        description: t.name,
        amount: t.amount,
      );
      return 1;
    }
    if (employeeIds.isEmpty) throw ArgumentError('Pilih minimal satu pegawai');
    final ids = employeeIds.toSet();
    final people = await (select(employees)..where((e) => e.id.isIn(ids) & e.active.equals(true))).get();
    if (people.length != ids.length) throw ArgumentError('Ada pegawai yang tidak ditemukan atau sudah nonaktif');
    for (final e in people) {
      await saveExpense(
        at: at,
        accountId: t.accountId,
        categoryId: t.categoryId,
        description: '${t.name} — ${e.name}',
        amount: t.amount,
      );
    }
    return people.length;
  });
}
