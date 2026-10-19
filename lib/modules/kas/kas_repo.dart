import 'package:drift/drift.dart';

import '../../db/database.dart';

/// Jenis transaksi kas yang dicatat langsung di modul ini (bukan dari modul lain).
abstract final class CashKind {
  static const transfer = 'transfer', capital = 'capital', income = 'income';
  static const manual = [transfer, capital, income];
}

/// Label jenis transaksi untuk ditampilkan.
const cashKindLabel = {
  'payment': 'Penjualan',
  'refund': 'Pengembalian',
  'purchase': 'Pembelian stok',
  'expense': 'Biaya',
  'salary': 'Gaji',
  'transfer': 'Transfer',
  'capital': 'Modal masuk',
  'income': 'Pemasukan lain',
};

class AccountBalance {
  AccountBalance(this.account, this.balance);
  final Account account;
  final int balance;
}

class EntryRow {
  EntryRow(this.entry, this.accountName, {this.balanceAfter});
  final CashEntry entry;
  final String accountName;
  final int? balanceAfter; // saldo berjalan; hanya bila difilter satu rekening
}

enum Period { daily, monthly, quarterly, yearly }

class FlowRow {
  FlowRow(this.start, this.label);
  final DateTime start;
  final String label;
  int income = 0, expense = 0; // expense bernilai positif
  int get net => income - expense;
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// Awal periode yang memuat [d] + labelnya.
(DateTime, String) periodOf(DateTime d, Period p) => switch (p) {
  Period.daily => (DateTime(d.year, d.month, d.day), '${d.day} ${_months[d.month - 1]} ${d.year}'),
  Period.monthly => (DateTime(d.year, d.month), '${_months[d.month - 1]} ${d.year}'),
  Period.quarterly => (DateTime(d.year, ((d.month - 1) ~/ 3) * 3 + 1), 'Q${(d.month - 1) ~/ 3 + 1} ${d.year}'),
  Period.yearly => (DateTime(d.year), '${d.year}'),
};

extension KasRepo on AppDb {
  /// Saldo = saldo awal + jumlah semua transaksi kas rekening itu.
  Stream<List<AccountBalance>> watchBalances() => customSelect(
    'SELECT a.*, a.opening_balance + COALESCE((SELECT SUM(amount) FROM cash_entries e WHERE e.account_id = a.id), 0) '
    'AS balance FROM accounts a ORDER BY a.active DESC, a.id',
    readsFrom: {accounts, cashEntries},
  ).watch().map((rows) => [for (final r in rows) AccountBalance(accounts.map(r.data), r.read<int>('balance'))]);

  /// Mutasi pada [from, to) (terbaru di atas). Bila [accountId] diisi, setiap baris membawa saldo berjalan.
  Stream<List<EntryRow>> watchEntries({int? accountId, required DateTime from, required DateTime to}) {
    final q = select(cashEntries).join([innerJoin(accounts, accounts.id.equalsExp(cashEntries.accountId))])
      ..where(
        cashEntries.at.isBiggerOrEqualValue(from) &
            cashEntries.at.isSmallerThanValue(to) &
            (accountId == null ? const Constant(true) : cashEntries.accountId.equals(accountId)),
      )
      ..orderBy([OrderingTerm.asc(cashEntries.at), OrderingTerm.asc(cashEntries.id)]);
    return q.watch().asyncMap((rows) async {
      var running = accountId == null ? null : await balanceBefore(accountId, from);
      final out = <EntryRow>[];
      for (final r in rows) {
        final e = r.readTable(cashEntries);
        if (running != null) running += e.amount;
        out.add(EntryRow(e, r.readTable(accounts).name, balanceAfter: running));
      }
      return out.reversed.toList();
    });
  }

  Future<int> balanceBefore(int accountId, DateTime at) async {
    final acc = await (select(accounts)..where((a) => a.id.equals(accountId))).getSingle();
    final sum = cashEntries.amount.sum();
    final row =
        await (selectOnly(cashEntries)
              ..addColumns([sum])
              ..where(cashEntries.accountId.equals(accountId) & cashEntries.at.isSmallerThanValue(at)))
            .getSingle();
    return acc.openingBalance + (row.read(sum) ?? 0);
  }

  /// Pindah uang antar rekening (mis. top up ShopeePay dari BCA). Tidak dihitung pemasukan/pengeluaran.
  /// Dicatat sebagai pasangan transaksi yang saling menunjuk lewat refId.
  Future<void> transfer({
    required int fromId,
    required int toId,
    required int amount,
    required DateTime at,
    String note = '',
    String proofPath = '',
  }) => transaction(() async {
    if (fromId == toId) throw ArgumentError('Rekening asal dan tujuan sama');
    if (amount <= 0) throw ArgumentError('Nominal harus lebih dari 0');
    final from = await requireActiveAccount(fromId), to = await requireActiveAccount(toId);
    final outId = await into(cashEntries).insert(
      CashEntriesCompanion.insert(
        at: at,
        accountId: fromId,
        amount: -amount,
        kind: CashKind.transfer,
        description: 'Transfer ke ${to.name}',
        note: Value(note.trim()),
        proofPath: Value(proofPath),
      ),
    );
    final inId = await into(cashEntries).insert(
      CashEntriesCompanion.insert(
        at: at,
        accountId: toId,
        amount: amount,
        kind: CashKind.transfer,
        refId: Value(outId),
        description: 'Transfer dari ${from.name}',
        note: Value(note.trim()),
        proofPath: Value(proofPath),
      ),
    );
    await (update(cashEntries)..where((e) => e.id.equals(outId))).write(CashEntriesCompanion(refId: Value(inId)));
  });

  /// Uang masuk di luar penjualan: modal dari owner ([CashKind.capital]) atau pemasukan lain ([CashKind.income]).
  Future<void> addIncome({
    required int accountId,
    required int amount,
    required DateTime at,
    required String kind,
    required String description,
    String note = '',
    String proofPath = '',
  }) async {
    if (kind != CashKind.capital && kind != CashKind.income) throw ArgumentError('Jenis pemasukan tidak dikenal');
    if (amount <= 0) throw ArgumentError('Nominal harus lebih dari 0');
    if (description.trim().isEmpty) throw ArgumentError('Keterangan wajib diisi');
    await requireActiveAccount(accountId);
    await into(cashEntries).insert(
      CashEntriesCompanion.insert(
        at: at,
        accountId: accountId,
        amount: amount,
        kind: kind,
        description: description.trim(),
        note: Value(note.trim()),
        proofPath: Value(proofPath),
      ),
    );
  }

  /// Hapus transaksi yang dicatat di modul ini (owner). Transfer terhapus berpasangan.
  /// Transaksi dari modul lain (penjualan, pembelian, biaya, gaji) diurus di modulnya masing-masing.
  Future<void> deleteManualEntry(int id) => transaction(() async {
    requireOwner();
    final e = await (select(cashEntries)..where((x) => x.id.equals(id))).getSingle();
    if (!CashKind.manual.contains(e.kind)) {
      throw ArgumentError('Transaksi ${cashKindLabel[e.kind] ?? e.kind} diubah dari modulnya, bukan dari Kas & Bank');
    }
    await (delete(cashEntries)..where((x) => x.id.isIn([id, if (e.kind == CashKind.transfer) ?e.refId]))).go();
  });

  /// Tambah/ubah rekening (owner): nama unik, saldo awal, keterangan, aktif.
  Future<int> saveAccount(AccountsCompanion a) async {
    requireOwner();
    final name = a.name.value.trim();
    if (name.isEmpty) throw ArgumentError('Nama rekening wajib diisi');
    final dup =
        await (select(accounts)..where(
              (x) =>
                  x.name.lower().equals(name.toLowerCase()) &
                  (a.id.present ? x.id.equals(a.id.value).not() : const Constant(true)),
            ))
            .getSingleOrNull();
    if (dup != null) throw ArgumentError('Rekening "$name" sudah ada');
    final data = a.copyWith(name: Value(name), note: Value(a.note.present ? a.note.value.trim() : ''));
    if (a.id.present) {
      await (update(accounts)..where((x) => x.id.equals(a.id.value))).write(data);
      return a.id.value;
    }
    return into(accounts).insert(data);
  }

  /// Arus kas per periode pada [from, to). Transfer antar rekening tidak dihitung.
  // ponytail: agregasi di Dart atas semua baris periode; pindah ke SQL GROUP BY kalau kas_entries > ~100rb baris.
  Future<List<FlowRow>> cashFlow(DateTime from, DateTime to, Period period) async {
    final rows =
        await (select(cashEntries)..where(
              (e) =>
                  e.at.isBiggerOrEqualValue(from) &
                  e.at.isSmallerThanValue(to) &
                  e.kind.equals(CashKind.transfer).not(),
            ))
            .get();
    final byStart = <DateTime, FlowRow>{};
    for (final e in rows) {
      final (start, label) = periodOf(e.at, period);
      final f = byStart.putIfAbsent(start, () => FlowRow(start, label));
      if (e.amount >= 0) {
        f.income += e.amount;
      } else {
        f.expense -= e.amount;
      }
    }
    return byStart.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }
}
