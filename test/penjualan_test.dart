import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/penjualan/invoice_pdf.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // rootBundle untuk font PDF
  late AppDb db;
  late int lamp, jasa, bca, tunai, budi, tek1, tek2;
  final d = DateTime(2026, 10, 20);

  setUp(() async {
    db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    lamp = await db.saveProduct(
      ProductsCompanion.insert(name: 'Hyperion Prime', sellPrice: const Value(2250000), incentive: const Value(100000)),
      openingStock: 5,
    );
    jasa = await db.saveProduct(
      ProductsCompanion.insert(name: 'Jasa Pasang', isService: const Value(true), sellPrice: const Value(250000)),
    );
    final acc = {for (final a in await db.select(db.accounts).get()) a.name: a.id};
    bca = acc['BCA']!;
    tunai = acc['Tunai']!;
    budi = await db
        .into(db.customers)
        .insert(CustomersCompanion.insert(name: 'BUDI', phone: const Value('081100002222')));
    tek1 = await db.into(db.employees).insert(EmployeesCompanion.insert(name: 'Teknisi A', role: 'teknisi'));
    tek2 = await db.into(db.employees).insert(EmployeesCompanion.insert(name: 'Teknisi B', role: 'teknisi'));
  });
  tearDown(() => db.close());

  LineInput lampLine({int qty = 1, int discount = 0, int? t1, int? t2}) => LineInput(
    productId: lamp,
    name: 'Hyperion Prime',
    qty: qty,
    price: 2250000,
    discount: discount,
    incentive: 100000,
    tech1Id: t1,
    tech2Id: t2,
  );
  LineInput jasaLine() => LineInput(productId: jasa, name: 'Jasa Pasang', qty: 1, price: 250000);

  test('stok 0: barang tidak bisa masuk invoice baru; pemesanan, transaksi lama & ubah invoice lama tetap boleh', () async {
    // Stok 5 habis terjual (qty melebihi stok tetap boleh selama stok > 0, dengan peringatan di form).
    final sold = await db.saveDoc(kind: DocKind.invoice, at: d, lines: [lampLine(qty: 5)]);
    expect(await db.stockOf(lamp), 0);
    expect(() => db.saveDoc(kind: DocKind.invoice, at: d, lines: [lampLine()]), throwsArgumentError);
    // Jasa tidak punya stok.
    await db.saveDoc(kind: DocKind.invoice, at: d, lines: [jasaLine()]);
    final so = await db.saveDoc(kind: DocKind.order, at: d, lines: [lampLine()]);
    await db.saveDoc(kind: DocKind.invoice, at: d, legacyNo: 'KLEDO/1', lines: [lampLine()]);
    // Mengubah invoice lama yang sudah memuat barang itu tidak terhalang.
    await db.saveDoc(id: sold, kind: DocKind.invoice, at: d, lines: [lampLine(qty: 5), jasaLine()]);
    // Pemesanan → invoice juga butuh stok.
    expect(() => db.invoiceFromOrder(so, at: d), throwsArgumentError);
  });

  test('kasir: invoice lunas langsung, nomor lanjut, stok barang berkurang (jasa tidak)', () async {
    final id = await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      customerId: budi,
      plate: 'n 1 ab',
      lines: [lampLine(discount: 50000), jasaLine()],
      payNow: PaymentInput(accountId: bca, amount: 2450000, at: d),
    );
    final s = await db.docSummary(id);
    expect(
      (s.doc.no, s.doc.plate, s.total, s.paid, s.status),
      ('INV/00247', 'N 1 AB', 2450000, 2450000, PayStatus.paid),
    );
    expect(await db.stockOf(lamp), 4);
    final cash = await db.select(db.cashEntries).getSingle();
    expect((cash.accountId, cash.amount, cash.kind, cash.refId), (bca, 2450000, 'payment', id));
  });

  test('mobil & plat customer mengikuti invoice baru terakhir (customer bisa ganti mobil/plat)', () async {
    await db.saveDoc(kind: DocKind.invoice, at: d, customerId: budi, car: 'Avanza', plate: 'n 1 ab', lines: [jasaLine()]);
    Future<Customer> get() => (db.select(db.customers)..where((c) => c.id.equals(budi))).getSingle();
    expect(((await get()).car, (await get()).plate), ('Avanza', 'N 1 AB'));
    await db.saveDoc(kind: DocKind.invoice, at: d, customerId: budi, car: 'Brio', plate: 'L 2 CD', lines: [jasaLine()]);
    expect(((await get()).car, (await get()).plate), ('Brio', 'L 2 CD')); // yang terbaru menang
    // Invoice tanpa mobil/plat (kosong) tidak menghapus yang sudah tercatat.
    await db.saveDoc(kind: DocKind.invoice, at: d, customerId: budi, lines: [jasaLine()]);
    expect(((await get()).car, (await get()).plate), ('Brio', 'L 2 CD'));
    // Mengubah invoice lama (old != null) tidak ikut mengubah data customer lagi.
    final id = await db.saveDoc(kind: DocKind.invoice, at: d, customerId: budi, car: 'Jazz', lines: [jasaLine()]);
    expect((await get()).car, 'Jazz');
    await db.saveDoc(id: id, kind: DocKind.invoice, at: d, customerId: budi, car: 'CR-V', lines: [jasaLine()]);
    expect((await get()).car, 'Jazz'); // ubah dokumen tidak ikut mengubah customer
  });

  test('status: belum lunas -> dibayar sebagian -> lunas; tidak boleh bayar lebih', () async {
    final id = await db.saveDoc(kind: DocKind.invoice, at: d, dueAt: d, lines: [lampLine()]);
    expect((await db.docSummary(id)).status, PayStatus.unpaid);
    expect((await db.docSummary(id)).overdue(d.add(const Duration(days: 1))), true);
    await db.addPayment(id, PaymentInput(accountId: tunai, amount: 1000000, at: d));
    expect((await db.docSummary(id)).status, PayStatus.partial);
    expect(() => db.addPayment(id, PaymentInput(accountId: bca, amount: 1250001, at: d)), throwsArgumentError);
    await db.addPayment(id, PaymentInput(accountId: bca, amount: 1250000, at: d));
    final s = await db.docSummary(id);
    expect((s.status, s.remaining, s.overdue(d.add(const Duration(days: 9)))), (PayStatus.paid, 0, false));
  });

  test('validasi baris di repo: qty, diskon, teknisi ganda, kosong', () async {
    Future<int> save(List<LineInput> l) => db.saveDoc(kind: DocKind.invoice, at: d, lines: l);
    expect(() => save([]), throwsArgumentError);
    expect(() => save([lampLine(qty: 0)]), throwsArgumentError);
    expect(() => save([lampLine(discount: 2250001)]), throwsArgumentError);
    expect(() => save([lampLine(t1: tek1, t2: tek1)]), throwsArgumentError);
    expect(await db.select(db.invoices).get(), isEmpty); // tidak ada yang tersimpan setengah jalan
    expect(await db.setting('next_invoice_no'), '247'); // nomor tidak terpakai sia-sia
  });

  test('ubah invoice: stok dihitung ulang; total tidak boleh di bawah yang sudah dibayar', () async {
    final id = await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      lines: [lampLine(qty: 2)],
      payNow: PaymentInput(accountId: bca, amount: 2000000, at: d),
    );
    expect(await db.stockOf(lamp), 3);
    await db.saveDoc(id: id, kind: DocKind.invoice, at: d, lines: [lampLine(qty: 1), jasaLine()]);
    expect(await db.stockOf(lamp), 4);
    expect((await db.docSummary(id)).total, 2500000);
    expect(() => db.saveDoc(id: id, kind: DocKind.invoice, at: d, lines: [jasaLine()]), throwsArgumentError);
  });

  test('batal: stok kembali, uang dikembalikan ke rekening asal, tidak bisa dibayar lagi', () async {
    final id = await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      lines: [lampLine()],
      payNow: PaymentInput(accountId: tunai, amount: 500000, at: d),
    );
    expect(() => db.voidDoc(id, ' '), throwsArgumentError);
    await db.voidDoc(id, 'salah input');
    await db.voidDoc(id, 'klik dua kali'); // aman diulang
    final s = await db.docSummary(id);
    expect((s.status, s.paid), (PayStatus.voided, 0));
    expect(await db.stockOf(lamp), 5);
    final saldoTunai = (await db.select(db.cashEntries).get())
        .where((c) => c.accountId == tunai)
        .fold(0, (t, c) => t + c.amount);
    expect(saldoTunai, 0);
    expect(() => db.addPayment(id, PaymentInput(accountId: bca, amount: 1, at: d)), throwsArgumentError);
  });

  test('pemesanan + DP -> invoice: stok baru berkurang saat invoice, DP terbawa', () async {
    final so = await db.saveDoc(
      kind: DocKind.order,
      at: d,
      customerId: budi,
      lines: [lampLine(), jasaLine()],
      payNow: PaymentInput(accountId: bca, amount: 1350000, at: d),
    );
    final s = await db.docSummary(so);
    expect((s.doc.no, s.status, s.remaining), ('SO/00013', PayStatus.partial, 1150000));
    expect(await db.stockOf(lamp), 5); // pemesanan tidak mengurangi stok

    final inv = await db.invoiceFromOrder(so);
    final i = await db.docSummary(inv);
    expect(
      (i.doc.no, i.doc.orderId, i.total, i.paid, i.status),
      ('INV/00247', so, 2500000, 1350000, PayStatus.partial),
    );
    expect(await db.stockOf(lamp), 4);
    final o = await db.docSummary(so);
    expect((o.status, o.paid), (PayStatus.invoiced, 1350000)); // DP tetap tercatat di pemesanan
    expect((await db.watchPayments(i.doc).first).single.amount, 1350000); // dan tampil di invoice
    expect(() => db.invoiceFromOrder(so), throwsArgumentError);
    expect(() => db.addPayment(so, PaymentInput(accountId: bca, amount: 1, at: d)), throwsArgumentError);
  });

  test('transaksi lama: nomor manual, tanggal lampau, stok tidak berubah, nomor unik', () async {
    final id = await db.saveDoc(
      kind: DocKind.invoice,
      at: DateTime(2026, 9, 22),
      legacyNo: 'inv/00245',
      lines: [lampLine()],
    );
    final s = await db.docSummary(id);
    expect((s.doc.no, s.doc.legacy), ('INV/00245', true));
    expect(await db.stockOf(lamp), 5);
    expect(await db.setting('next_invoice_no'), '247');
    expect(
      () => db.saveDoc(kind: DocKind.invoice, at: d, legacyNo: 'INV/00245', lines: [lampLine()]),
      throwsArgumentError,
    );
  });

  test('insentif dibagi dua bila dua teknisi', () async {
    final id = await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      lines: [
        lampLine(qty: 2, t1: tek1, t2: tek2),
        lampLine(t1: tek1),
      ],
    );
    final lines = await db.watchLines(id).first;
    expect(lines.map(lineIncentiveShare), [100000, 100000]); // 2×100rb ÷ 2 ; 1×100rb
  });

  test('statistik customer: aktif, % repeat, top', () async {
    final siti = await db.into(db.customers).insert(CustomersCompanion.insert(name: 'SITI'));
    await db.saveDoc(kind: DocKind.invoice, at: DateTime(2026, 9, 1), customerId: budi, lines: [jasaLine()]);
    await db.saveDoc(kind: DocKind.invoice, at: d, customerId: budi, lines: [lampLine()]);
    await db.saveDoc(kind: DocKind.invoice, at: d, customerId: siti, lines: [jasaLine()]);
    final voided = await db.saveDoc(kind: DocKind.invoice, at: d, customerId: siti, lines: [lampLine()]);
    await db.voidDoc(voided, 'batal');
    final st = await db.customerStats(DateTime(2026, 10), DateTime(2026, 11));
    expect((st.active, st.repeatPct), (2, 50.0)); // BUDI repeat, SITI baru sekali (yang batal tidak dihitung)
    expect(st.top.map((t) => (t.customer.name, t.total, t.count)), [('BUDI', 2250000, 1), ('SITI', 250000, 1)]);
  });

  test('PDF invoice terbentuk; pesan & link WA', () async {
    await db.setSetting('shop_name', 'Star Garage');
    await db.setSetting('gmaps_review_url', 'https://g.page/r/contoh/review');
    final id = await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      customerId: budi,
      lines: [lampLine(), jasaLine()],
      payNow: PaymentInput(accountId: bca, amount: 1000000, at: d),
    );
    final pdf = await buildInvoicePdf(db, id);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    final s = await db.docSummary(id);
    final settings = await db.allSettings();
    final msg = waMessage(s, await db.watchLines(id).first, settings);
    expect(msg, contains('INV/00247'));
    expect(msg, contains('- Hyperion Prime 1× = Rp 2.250.000'));
    expect(msg, contains('Sisa tagihan: Rp 1.500.000'));
    expect(msg, isNot(contains('{'))); // semua placeholder terganti
    // Template per keadaan: lunas (dengan link review), pemesanan/DP; template kosong = bawaan.
    await db.addPayment(id, PaymentInput(accountId: bca, amount: 1500000, at: d));
    final paid = waMessage(await db.docSummary(id), [], settings);
    expect(paid, allOf(contains('LUNAS'), contains('https://g.page/r/contoh/review')));
    final order = await db.saveDoc(kind: DocKind.order, at: d, lines: [jasaLine()]);
    await db.setSetting('wa_order', 'DP {no} {dibayar}');
    expect(waMessage(await db.docSummary(order), [], await db.allSettings()), 'DP SO/00013 Rp 0');
    await db.setSetting('wa_order', '  ');
    expect(waMessage(await db.docSummary(order), [], await db.allSettings()), contains('Pemesanan SO/00013'));
    final uri = waUri(s.customerPhone, msg);
    expect(uri.toString(), startsWith('https://wa.me/6281100002222?text='));
  });

  test('aturan owner dicek di repo, bukan hanya UI', () async {
    final id = await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      lines: [lampLine(), jasaLine()],
      payNow: PaymentInput(accountId: bca, amount: 100000, at: d),
    );
    db.ownerUnlocked = false;
    expect(() => db.voidDoc(id, 'x'), throwsArgumentError);
    // Mengubah invoice yang sudah dibayar butuh owner.
    expect(
      () => db.saveDoc(id: id, kind: DocKind.invoice, at: d, lines: [lampLine(), jasaLine()]),
      throwsArgumentError,
    );
  });

  test('modal = harga beli terakhir produk (diisi repo); ubah dokumen mempertahankan modal lama', () async {
    Future<void> buy(int price) => (db.update(
      db.products,
    )..where((p) => p.id.equals(lamp))).write(ProductsCompanion(buyPrice: Value(price)));
    Future<int?> cost(int id) async => (await db.watchLines(id).first).first.cost;
    final noBuy = await db.saveDoc(kind: DocKind.invoice, at: d, lines: [lampLine(), jasaLine()]);
    expect([for (final l in await db.watchLines(noBuy).first) l.cost], [null, 0]); // barang tanpa harga beli = kosong
    await buy(1500000);
    final unpaid = await db.saveDoc(kind: DocKind.invoice, at: d, lines: [lampLine()]);
    expect(await cost(unpaid), 1500000);
    await buy(1600000);
    await db.saveDoc(id: unpaid, kind: DocKind.invoice, at: d, lines: [lampLine(qty: 2)]);
    expect(await cost(unpaid), 1500000);
    expect(await cost(await db.saveDoc(kind: DocKind.invoice, at: d, lines: [lampLine()])), 1600000);
  });

  test('diskon invoice (Rp / %) & PPN: total, omzet, validasi, ikut ke invoice dari pemesanan', () async {
    // Subtotal 2.500.000; diskon 10% = 250.000; PPN 11% × 2.250.000 = 247.500.
    final id = await db.saveDoc(
      kind: DocKind.invoice,
      at: d,
      lines: [lampLine(), jasaLine()],
      discountPct: 10,
      taxPct: 11,
    );
    final s = await db.docSummary(id);
    expect((s.subtotal, s.doc.discount, s.doc.tax, s.total, s.omzet), (2500000, 250000, 247500, 2497500, 2250000));
    expect(s.adjustments, [('Diskon 10%', -250000), ('PPN 11%', 247500)]);
    final plain = await db.docSummary(await db.saveDoc(kind: DocKind.invoice, at: d, lines: [jasaLine()]));
    expect(plain.adjustments, isEmpty); // tanpa diskon/PPN: tidak tampil
    expect(plain.total, 250000);
    final rp = await db.docSummary(
      await db.saveDoc(kind: DocKind.invoice, at: d, lines: [jasaLine()], discount: 50000),
    );
    expect(rp.adjustments, [('Diskon', -50000)]);
    expect(rp.total, 200000);

    expect(() => db.saveDoc(kind: DocKind.invoice, at: d, lines: [jasaLine()], discount: 250001), throwsArgumentError);
    expect(() => db.saveDoc(kind: DocKind.invoice, at: d, lines: [jasaLine()], discountPct: 101), throwsArgumentError);
    // Bayar penuh (dengan PPN) → lunas; tidak boleh lebih.
    await db.addPayment(id, PaymentInput(accountId: bca, amount: 2497500, at: d));
    expect((await db.docSummary(id)).status, PayStatus.paid);

    final order = await db.saveDoc(kind: DocKind.order, at: d, lines: [jasaLine()], discount: 50000, taxPct: 11);
    final inv = await db.docSummary(await db.invoiceFromOrder(order, at: d));
    expect((inv.doc.discount, inv.doc.tax, inv.total), (50000, 22000, 222000));
  });

  test('nomor otomatis melompati nomor yang sudah dipakai transaksi lama', () async {
    await db.saveDoc(kind: DocKind.invoice, at: d, legacyNo: 'INV/00248', lines: [jasaLine()]);
    final a = await db.saveDoc(kind: DocKind.invoice, at: d, lines: [jasaLine()]);
    final b = await db.saveDoc(kind: DocKind.invoice, at: d, lines: [jasaLine()]);
    expect([(await db.docSummary(a)).doc.no, (await db.docSummary(b)).doc.no], ['INV/00247', 'INV/00249']);
  });

  test('invoice dari pemesanan dibatalkan: DP kembali ke pemesanan yang terbuka lagi', () async {
    final so = await db.saveDoc(
      kind: DocKind.order,
      at: d,
      lines: [jasaLine()],
      payNow: PaymentInput(accountId: bca, amount: 100000, at: d),
    );
    final inv = await db.invoiceFromOrder(so);
    await db.voidDoc(inv, 'salah');
    final o = await db.docSummary(so);
    expect((o.status, o.paid), (PayStatus.partial, 100000));
    expect((await db.docSummary(inv)).paid, 0);
  });
}
