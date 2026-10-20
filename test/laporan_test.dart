import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/biaya/biaya_repo.dart';
import 'package:garage_erp_desktop/modules/gaji/gaji_repo.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';
import 'package:garage_erp_desktop/modules/laporan/laporan_repo.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';

void main() {
  late AppDb db;
  late int bca, lampu, kabel, jasa, tek;
  late Map<String, int> cat;
  final (y0, y1) = (DateTime(2026), DateTime(2027));

  setUp(() async {
    db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    bca = (await (db.select(db.accounts)..where((a) => a.name.equals('BCA'))).getSingle()).id;
    lampu = await db.saveProduct(
      ProductsCompanion.insert(name: 'Projector', category: const Value('PROJECTOR'), buyPrice: const Value(900000)),
    );
    kabel = await db.saveProduct(ProductsCompanion.insert(name: 'Kabel set', category: const Value('KABEL')));
    jasa = await db.saveProduct(ProductsCompanion.insert(name: 'Pasang', isService: const Value(true)));
    tek = await db.saveEmployee(
      EmployeesCompanion.insert(name: 'Teknisi A', role: 'teknisi', baseSalary: const Value(1000000)),
    );
    cat = {for (final k in await db.watchCategories().first) k.name: k.id};

    // Oktober: invoice 2 projector (modal = harga beli produk) + jasa, diskon 100rb.
    await db.saveDoc(
      kind: DocKind.invoice,
      at: DateTime(2026, 10, 5),
      lines: [
        LineInput(productId: lampu, name: 'Projector', qty: 2, price: 1500000, discount: 100000),
        LineInput(productId: jasa, name: 'Pasang', qty: 1, price: 300000),
      ],
    );
    // November: kabel tanpa modal (peringatan) + invoice batal + pemesanan ber-DP (belum pendapatan).
    await db.saveDoc(
      kind: DocKind.invoice,
      at: DateTime(2026, 11, 2),
      lines: [LineInput(productId: kabel, name: 'Kabel set', qty: 3, price: 100000)],
    );
    final batal = await db.saveDoc(
      kind: DocKind.invoice,
      at: DateTime(2026, 11, 3),
      lines: [LineInput(productId: lampu, name: 'Projector', qty: 1, price: 1500000)],
    );
    await db.voidDoc(batal, 'salah');
    await db.saveDoc(
      kind: DocKind.order,
      at: DateTime(2026, 11, 4),
      lines: [LineInput(productId: lampu, name: 'Projector', qty: 1, price: 1500000)],
      payNow: PaymentInput(accountId: bca, amount: 500000, at: DateTime(2026, 11, 4)),
    );

    // Uang keluar: pembelian stok (bukan biaya), biaya operasional, pribadi, gaji.
    await db.recordPurchase(
      at: DateTime(2026, 10, 1),
      accountId: bca,
      lines: [PurchaseLine(productId: lampu, qty: 5, unitCost: 900000)],
    );
    Future<void> biaya(String c, int amount, DateTime at) =>
        db.saveExpense(at: at, accountId: bca, categoryId: cat[c]!, description: c, amount: amount);
    await biaya('Listrik', 200000, DateTime(2026, 10, 10));
    await biaya('ART', 150000, DateTime(2026, 10, 11));
    await biaya('Listrik', 50000, DateTime(2026, 11, 10));
    final (start, _) = payrollPeriodOf(DateTime(2026, 10, 20), 27);
    await db.paySlip(employeeId: tek, start: start, accountId: bca, at: DateTime(2026, 10, 27));
  });
  tearDown(() => db.close());

  test('laba rugi: pendapatan − HPP − (biaya + gaji) = laba bersih usaha − pribadi = sisa', () async {
    final pl = (await db.report(y0, y1, Period.monthly)).pl;
    final okt = pl.rows.first;
    expect(
      (okt.label, okt.revenue, okt.cogs, okt.gross, okt.expense, okt.salary, okt.net, okt.personal, okt.rest),
      ('Okt 2026', 3200000, 1800000, 1400000, 200000, 1000000, 200000, 150000, 50000),
    );
    final nov = pl.rows.last;
    expect((nov.revenue, nov.cogs, nov.expense, nov.net), (300000, 0, 50000, 250000)); // DP & batal tidak dihitung
    expect((pl.total.revenue, pl.total.net, pl.total.rest), (3500000, 450000, 300000));
    expect(pl.missingCost, 1); // kabel tanpa modal; jasa tanpa modal tidak diperingatkan
    expect(pl.expenseByCategory, {'Listrik': 250000, 'ART': 150000});
  });

  test('penjualan per periode, per kategori, dan terlaris', () async {
    final s = (await db.report(y0, y1, Period.monthly)).sales;
    expect(s.rows.map((r) => (r.label, r.invoices.length, r.gross, r.discount, r.omzet)), [
      ('Okt 2026', 1, 3300000, 100000, 3200000),
      ('Nov 2026', 1, 300000, 0, 300000),
    ]);
    expect((s.total.invoices.length, s.total.omzet), (2, 3500000));
    expect(s.byCategory.map((c) => (c.name, c.qty, c.omzet)), [
      ('PROJECTOR', 2, 2900000),
      ('KABEL', 3, 300000),
      ('Tanpa kategori', 1, 300000),
    ]);
    expect(s.byProduct.map((p) => (p.name, p.qty)), [('Kabel set', 3), ('Projector', 2), ('Pasang', 1)]);
    final daily = (await db.report(DateTime(2026, 10), DateTime(2026, 11), Period.daily)).sales;
    expect(daily.rows.single.label, '5 Okt 2026');
  });

  test('diskon invoice mengurangi pendapatan (sekali per invoice); PPN dicatat terpisah, bukan omzet', () async {
    final des = DateTime(2026, 12, 1);
    await db.saveDoc(
      kind: DocKind.invoice,
      at: DateTime(2026, 12, 5),
      lines: [
        LineInput(productId: jasa, name: 'Pasang', qty: 1, price: 300000),
        LineInput(productId: jasa, name: 'Pasang', qty: 1, price: 200000),
      ],
      discount: 100000,
      taxPct: 11,
    );
    final r = await db.report(des, y1, Period.monthly);
    expect(r.pl.total.revenue, 400000);
    final t = r.sales.total;
    expect((t.gross, t.discount, t.omzet, t.tax), (500000, 100000, 400000, 44000));
  });

  test('laporan khusus owner (dicek di repo)', () async {
    db.ownerUnlocked = false;
    await expectLater(db.report(y0, y1, Period.monthly), throwsArgumentError);
  });
}
