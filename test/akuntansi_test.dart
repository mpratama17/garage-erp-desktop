// Jurnal turunan & laporan akuntansi: harus seimbang dan cocok dengan Kas & Bank serta Laba Rugi yang sudah ada.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/biaya/biaya_repo.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';
import 'package:garage_erp_desktop/modules/laporan/akuntansi_repo.dart';
import 'package:garage_erp_desktop/modules/laporan/akuntansi_reports.dart';
import 'package:garage_erp_desktop/modules/laporan/laporan_repo.dart';
import 'package:garage_erp_desktop/modules/laporan/report_data.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';

void main() {
  late AppDb db;
  late int bca, tunai, led, jasa;
  final d = DateTime(2026, 10, 10);
  final end = DateTime(2026, 10, 31);

  setUp(() async {
    db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    final acc = {for (final a in await db.select(db.accounts).get()) a.name: a.id};
    bca = acc['BCA']!;
    tunai = acc['Tunai']!;
    await (db.update(
      db.accounts,
    )..where((a) => a.id.equals(bca))).write(const AccountsCompanion(openingBalance: Value(1000000)));
    led = await db.saveProduct(ProductsCompanion.insert(name: 'LED', sellPrice: const Value(120000)));
    jasa = await db.saveProduct(
      ProductsCompanion.insert(name: 'Pasang', isService: const Value(true), sellPrice: const Value(50000)),
    );

    await db.addIncome(accountId: tunai, amount: 500000, at: d, kind: CashKind.capital, description: 'Modal');
    await db.addIncome(accountId: tunai, amount: 20000, at: d, kind: CashKind.income, description: 'Lain');
    // Beli 10 LED @50rb: 5 lunas, lalu satu lagi belum dibayar.
    await db.recordPurchase(
      at: d,
      accountId: bca,
      supplier: 'Toko A',
      lines: [PurchaseLine(productId: led, qty: 10, unitCost: 50000)],
    );
    await db.recordPurchase(
      at: d,
      accountId: bca,
      paidNow: false,
      supplier: 'Toko B',
      lines: [PurchaseLine(productId: led, qty: 2, unitCost: 50000)],
    );
    // Invoice: 2 LED + jasa, diskon 10rb, PPN 11%, lunas dengan Tunai.
    final inv = await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      lines: [
        LineInput(productId: led, name: 'LED', qty: 2, price: 120000),
        LineInput(productId: jasa, name: 'Pasang', qty: 1, price: 50000),
      ],
      discount: 10000,
      taxPct: 11,
    );
    await db.addPayment(inv, PaymentInput(accountId: tunai, amount: (await db.docSummary(inv)).total, at: d));
    // Pemesanan dengan DP lalu dijadikan invoice dan dilunasi.
    final so = await db.saveDoc(
      kind: DocKind.order,
      at: d,
      lines: [LineInput(productId: led, name: 'LED', qty: 1, price: 120000)],
      payNow: PaymentInput(accountId: bca, amount: 40000, at: d),
    );
    final inv2 = await db.invoiceFromOrder(so, at: d);
    await db.addPayment(inv2, PaymentInput(accountId: bca, amount: 80000, at: d));
    // Invoice yang dibatalkan setelah dibayar sebagian (refund).
    final bad = await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      lines: [LineInput(productId: led, name: 'LED', qty: 1, price: 120000)],
      payNow: PaymentInput(accountId: tunai, amount: 30000, at: d),
    );
    await db.voidDoc(bad, 'salah input');
    // Invoice belum lunas (piutang).
    await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      lines: [LineInput(productId: jasa, name: 'Pasang', qty: 1, price: 50000)],
    );

    final cat = {for (final c in await db.watchCategories().first) c.name: c};
    await db.saveExpense(at: d, accountId: tunai, categoryId: cat['Listrik']!.id, description: 'Token', amount: 50000);
    await db.saveExpense(
      at: d,
      accountId: tunai,
      categoryId: cat['Rumah (Listrik/Air/Wifi)']!.id,
      description: 'Wifi rumah',
      amount: 30000,
    );
    await db
        .into(db.cashEntries)
        .insert(
          CashEntriesCompanion.insert(at: d, accountId: bca, amount: -200000, kind: 'salary', description: 'Gaji'),
        );
    await db.transfer(fromId: bca, toId: tunai, amount: 100000, at: d);
  });
  tearDown(() => db.close());

  test('jurnal seimbang: tiap entri debit = kredit, trial balance debit = kredit', () async {
    final j = await db.journal();
    for (final e in j.entries) {
      expect(
        e.lines.fold(0, (t, l) => t + l.debit),
        e.lines.fold(0, (t, l) => t + l.credit),
        reason: '${e.ref} ${e.memo}',
      );
    }
    final tb = await db.trialBalance(end);
    final total = tb.rows.last.cells;
    expect(total[2], total[3]);
    expect(tb.notes, isEmpty);
  });

  test('saldo akun kas di jurnal = saldo Kas & Bank', () async {
    final j = await db.journal();
    final net = j.net();
    for (final b in await db.watchBalances().first) {
      expect(net[Ac.kas(b.account.id)] ?? 0, b.balance, reason: b.account.name);
    }
  });

  test('neraca seimbang dan laba berjalan = laba bersih usaha di Laba Rugi', () async {
    final neraca = await db.neraca(end);
    expect(neraca.notes.where((n) => n.startsWith('PERHATIAN')), isEmpty);
    final rows = {for (final r in neraca.rows) r.cells[0]: r.cells[1]};
    expect(rows['Total aset'], rows['Total kewajiban + modal']);

    final j = await db.journal();
    final pl = (await db.report(DateTime(2026, 10), DateTime(2026, 11), Period.monthly)).pl.total;
    // Selisih satu-satunya: Pemasukan lain (Rp20.000) — dihitung di neraca, tidak ada di menu Laba rugi.
    expect(j.profit(j.net()), pl.net + 20000);
    expect(rows['Laba (rugi) berjalan'], pl.net + 20000);
    // Pengeluaran pribadi masuk Prive, bukan beban.
    expect(j.net()[Ac.prive], 30000);
  });

  test('DP pemesanan: tidak jadi piutang ganda; invoice batal tidak menyisakan uang muka', () async {
    final j = await db.journal();
    final net = j.net();
    // Piutang tersisa hanya invoice jasa Rp50.000 yang belum dibayar.
    expect(net[Ac.piutang], 50000 + 0);
    // Uang muka: pembayaran Rp30.000 + refund Rp30.000 pada invoice batal = 0; DP 40.000 sudah pindah ke invoice.
    expect(net[Ac.uangMuka] ?? 0, 0);
  });

  test('utang usaha = pembelian belum dibayar; persediaan = beli − HPP', () async {
    final net = (await db.journal()).net();
    expect(-(net[Ac.utangUsaha] ?? 0), 100000);
    // Beli 12 LED @50rb = 600rb; terjual 3 (invoice 2 + invoice dari pemesanan 1) → HPP 150rb (modal = harga beli).
    expect(net[Ac.persediaan], 600000 - 150000);
    expect(net[Ac.hpp], 150000);
  });

  test('transaksi lama: HPP-nya tidak mengurangi persediaan (lawannya modal)', () async {
    await db.saveDoc(
      kind: DocKind.invoice,
      at: DateTime(2025, 1, 5),
      legacyNo: 'KLEDO/001',
      lines: [LineInput(productId: led, name: 'LED', qty: 4, price: 120000)],
    );
    final net = (await db.journal()).net();
    expect(net[Ac.persediaan], 600000 - 150000);
    expect(net[Ac.hpp], 150000 + 4 * 50000);
    // Barang lama = setoran barang dari pemilik yang langsung terjual: modal bertambah sebesar HPP-nya.
    expect(-(net[Ac.modal] ?? 0), 1000000 + 500000 + 4 * 50000);
  });

  test('buku besar & ringkasan bank: saldo akhir = saldo di neraca saldo', () async {
    final bb = await db.bukuBesar(Ac.kas(bca), DateTime(2026, 10), end);
    final tb = (await db.journal()).net()[Ac.kas(bca)];
    expect(bb.rows.last.cells[5], tb);
    final bank = await db.ringkasanBank(DateTime(2026, 10), end);
    final all = (await db.watchBalances().first).fold<int>(0, (t, b) => t + b.balance);
    expect(bank.rows.last.cells[4], all);
    expect(bank.rows.last.cells[1], 1000000); // saldo awal
  });

  test('perubahan modal: awal + laba + tambahan − prive = akhir', () async {
    final r = await db.perubahanModal(DateTime(2026, 10), end);
    expect(r.notes, isEmpty);
    expect(r.rows.first.cells[1], 1000000); // saldo awal rekening (BCA) = modal awal
    expect(r.rows[2].cells[1], 500000); // setoran modal Oktober
  });

  test('laporan lain tampil tanpa error dan semuanya tertolak saat owner terkunci', () async {
    final from = DateTime(2026, 10);
    final reports = <String, Future<ReportData> Function()>{
      'neraca': () => db.neraca(end),
      'perubahan modal': () => db.perubahanModal(from, end),
      'proyeksi': () => db.proyeksiArusKas(),
      'ringkasan eksekutif': () => db.ringkasanEksekutif(from, end),
      'ringkasan bank': () => db.ringkasanBank(from, end),
      'buku besar': () => db.bukuBesar(Ac.kas(bca), from, end),
      'pembantu piutang': () => db.bukuBesarPembantu('piutang'),
      'pembantu utang': () => db.bukuBesarPembantu('utang'),
      'pembantu persediaan': () => db.bukuBesarPembantu('persediaan'),
      'jurnal': () => db.jurnalUmum(from, end),
      'trial balance': () => db.trialBalance(end),
      'detail penjualan': () => db.detailPenjualan(from, end),
      'detail pembelian': () => db.detailPembelian(from, end),
    };
    for (final f in reports.values) {
      final r = await f();
      expect(r.headers, isNotEmpty);
      for (final row in r.rows) {
        expect(row.cells.length, r.headers.length, reason: r.title);
      }
    }
    db.ownerUnlocked = false;
    expect(() => db.journal(), throwsA(anything));
    expect(() => db.chartOfAccounts(), throwsA(anything));
    for (final e in reports.entries) {
      await expectLater(e.value(), throwsA(anything), reason: e.key);
    }
  });
}
