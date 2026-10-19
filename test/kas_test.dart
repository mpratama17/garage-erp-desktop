import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';

void main() {
  late AppDb db;
  late int bca, shopee, tunai;
  final d = DateTime(2026, 10, 20);

  setUp(() async {
    db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    final acc = {for (final a in await db.select(db.accounts).get()) a.name: a.id};
    (bca, shopee, tunai) = (acc['BCA']!, acc['ShopeePay']!, acc['Tunai']!);
    await (db.update(
      db.accounts,
    )..where((a) => a.id.equals(bca))).write(const AccountsCompanion(openingBalance: Value(5000000)));
  });
  tearDown(() => db.close());

  Future<Map<String, int>> balances() async => {
    for (final b in await db.watchBalances().first) b.account.name: b.balance,
  };

  test('saldo = saldo awal + semua transaksi dari modul mana pun', () async {
    final jasa = await db.saveProduct(ProductsCompanion.insert(name: 'Jasa', isService: const Value(true)));
    await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      lines: [LineInput(productId: jasa, name: 'Jasa', qty: 1, price: 300000)],
      payNow: PaymentInput(accountId: bca, amount: 300000, at: d),
    );
    expect((await balances())['BCA'], 5300000);
  });

  test('transfer: saldo pindah, total uang tetap, tidak masuk arus kas', () async {
    await db.transfer(fromId: bca, toId: shopee, amount: 1000000, at: d, note: 'top up');
    final b = await balances();
    expect((b['BCA'], b['ShopeePay']), (4000000, 1000000));
    final flow = await db.cashFlow(DateTime(2026), DateTime(2027), Period.monthly);
    expect(flow, isEmpty);
    expect(() => db.transfer(fromId: bca, toId: bca, amount: 1, at: d), throwsArgumentError);
    expect(() => db.transfer(fromId: bca, toId: tunai, amount: 0, at: d), throwsArgumentError);
    // Hapus satu sisi = keduanya terhapus.
    final e = (await db.select(db.cashEntries).get()).first;
    await db.deleteManualEntry(e.id);
    expect(await db.select(db.cashEntries).get(), isEmpty);
  });

  test('mutasi satu rekening membawa saldo berjalan (terbaru di atas)', () async {
    await db.addIncome(
      accountId: bca,
      amount: 200000,
      at: DateTime(2026, 9, 30),
      kind: CashKind.capital,
      description: 'Modal',
    );
    await db.addIncome(
      accountId: bca,
      amount: 100000,
      at: DateTime(2026, 10, 2),
      kind: CashKind.income,
      description: 'Jual kardus',
    );
    await db.transfer(fromId: bca, toId: tunai, amount: 50000, at: DateTime(2026, 10, 3));
    final rows = await db.watchEntries(accountId: bca, from: DateTime(2026, 10), to: DateTime(2026, 11)).first;
    expect(rows.map((r) => (r.entry.amount, r.balanceAfter)), [(-50000, 5250000), (100000, 5300000)]);
    final all = await db.watchEntries(from: DateTime(2026, 10), to: DateTime(2026, 11)).first;
    expect(all.length, 3);
    expect(all.every((r) => r.balanceAfter == null), true);
  });

  test('arus kas per bulan & kuartal; refund dan pembelian = pengeluaran', () async {
    await db.addIncome(
      accountId: tunai,
      amount: 1000000,
      at: DateTime(2026, 9, 5),
      kind: CashKind.capital,
      description: 'Modal',
    );
    final led = await db.saveProduct(ProductsCompanion.insert(name: 'LED'));
    await db.recordPurchase(
      at: DateTime(2026, 10, 1),
      accountId: tunai,
      lines: [PurchaseLine(productId: led, qty: 2, unitCost: 150000)],
    );
    await db.addIncome(
      accountId: bca,
      amount: 400000,
      at: DateTime(2026, 10, 9),
      kind: CashKind.income,
      description: 'Lain',
    );
    final m = await db.cashFlow(DateTime(2026), DateTime(2027), Period.monthly);
    expect(m.map((f) => (f.label, f.income, f.expense, f.net)), [
      ('Sep 2026', 1000000, 0, 1000000),
      ('Okt 2026', 400000, 300000, 100000),
    ]);
    final q = await db.cashFlow(DateTime(2026), DateTime(2027), Period.quarterly);
    expect(q.map((f) => (f.label, f.net)), [('Q3 2026', 1000000), ('Q4 2026', 100000)]);
  });

  test('aturan: rekening (owner, nama unik), hapus hanya transaksi manual, pemasukan wajib keterangan', () async {
    expect(
      () => db.addIncome(accountId: bca, amount: 1, at: d, kind: CashKind.income, description: ' '),
      throwsArgumentError,
    );
    await expectLater(
      db.saveAccount(AccountsCompanion.insert(name: ' Bca ')),
      throwsArgumentError,
    ); // beda huruf besar = sama
    final bri = await db.saveAccount(AccountsCompanion.insert(name: 'BRI', openingBalance: const Value(100)));
    await db.saveAccount(AccountsCompanion(id: Value(bri), name: const Value('BRI'), active: const Value(false)));
    expect(() => db.transfer(fromId: bca, toId: bri, amount: 1, at: d), throwsArgumentError); // nonaktif
    final led = await db.saveProduct(ProductsCompanion.insert(name: 'LED'));
    await db.recordPurchase(
      at: d,
      accountId: tunai,
      lines: [PurchaseLine(productId: led, qty: 1, unitCost: 1)],
    );
    final purchase = (await db.select(db.cashEntries).get()).single;
    await expectLater(
      db.deleteManualEntry(purchase.id),
      throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('modulnya'))),
    );
    db.ownerUnlocked = false;
    await expectLater(db.saveAccount(AccountsCompanion.insert(name: 'X')), throwsArgumentError);
  });

  test('saldo khusus owner: tanpa PIN saldo & saldo berjalan tidak dimuat, mutasi tetap terlihat', () async {
    await db.addIncome(accountId: bca, amount: 100000, at: d, kind: CashKind.income, description: 'Lain');
    db.ownerUnlocked = false;
    expect(() => db.watchBalances(), throwsArgumentError);
    await expectLater(db.balanceBefore(bca, d), throwsArgumentError);
    final rows = await db.watchEntries(accountId: bca, from: DateTime(2026, 10), to: DateTime(2026, 11)).first;
    expect(rows.map((r) => (r.entry.amount, r.balanceAfter)), [(100000, null)]);
    expect((await db.watchAccounts().first).length, 4);
  });
}
