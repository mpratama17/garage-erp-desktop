import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/core/ui.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';

List<int> _xlsx(List<List<CellValue?>> rows) {
  final excel = Excel.createExcel();
  final s = excel.getDefaultSheet()!;
  for (final r in rows) {
    excel.appendRow(s, r);
  }
  return excel.encode()!;
}

void main() {
  late AppDb db;
  setUp(() => db = AppDb(NativeDatabase.memory())..ownerUnlocked = true);
  tearDown(() => db.close());

  Future<int> barang(String name, {String? sku, int stock = 0, int min = 0}) => db.saveProduct(
    ProductsCompanion.insert(name: name, sku: Value(sku), minStock: Value(min), sellPrice: const Value(100)),
    openingStock: stock,
  );

  test('stok = jumlah buku stok; jasa tidak punya stok awal', () async {
    final led = await barang('LED H4', sku: 'LED/1', stock: 5, min: 5);
    await db.saveProduct(ProductsCompanion.insert(name: 'Jasa Pasang', isService: const Value(true)), openingStock: 3);
    final list = await db.watchProducts().first;
    expect(list.map((s) => (s.product.name, s.stock)), [('Jasa Pasang', 0), ('LED H4', 5)]);
    expect(list.last.isLow, true); // 5 <= min 5
    expect(list.first.isLow, false); // jasa tidak pernah "menipis"
    expect(await db.stockOf(led), 5);
  });

  test('validasi produk: nama wajib, SKU unik', () async {
    await barang('A', sku: 'X1');
    expect(() => barang('  '), throwsArgumentError);
    expect(() => barang('B', sku: ' X1 '), throwsArgumentError);
    final b = await barang('B', sku: '');
    expect((await (db.select(db.products)..where((p) => p.id.equals(b))).getSingle()).sku, isNull);
  });

  test('pembelian: stok naik, harga beli ikut, saldo rekening berkurang', () async {
    final led = await barang('LED H4', stock: 1);
    final bca = (await db.select(db.accounts).get()).firstWhere((a) => a.name == 'BCA').id;
    await db.recordPurchase(
      at: DateTime(2026, 10, 20),
      accountId: bca,
      supplier: 'Toko Lampu',
      lines: [PurchaseLine(productId: led, qty: 4, unitCost: 120000)],
    );
    expect(await db.stockOf(led), 5);
    final p = await (db.select(db.products)..where((x) => x.id.equals(led))).getSingle();
    expect(p.buyPrice, 120000);
    final cash = await db.select(db.cashEntries).getSingle();
    expect((cash.accountId, cash.amount, cash.kind), (bca, -480000, 'purchase'));
    expect(() => db.recordPurchase(at: DateTime.now(), accountId: bca, lines: []), throwsArgumentError);
  });

  test('riwayat stok tahu asalnya (invoice+customer / pembelian); riwayat pembelian khusus owner', () async {
    final led = await barang('LED H4', stock: 2);
    final bca = (await db.select(db.accounts).get()).firstWhere((a) => a.name == 'BCA').id;
    final pid = await db.recordPurchase(
      at: DateTime(2026, 10, 19),
      accountId: bca,
      supplier: 'Toko Lampu',
      lines: [PurchaseLine(productId: led, qty: 3, unitCost: 120000)],
    );
    final budi = await db.into(db.customers).insert(CustomersCompanion.insert(name: 'BUDI'));
    final inv = await db.saveDoc(
      kind: DocKind.invoice,
      at: DateTime(2026, 10, 20),
      customerId: budi,
      lines: [LineInput(productId: led, name: 'LED H4', qty: 1, price: 100)],
    );
    final moves = await db.watchMoves(led).first;
    expect([
      for (final m in moves) (m.move.kind, m.doc?.id, m.customer, m.purchase?.id),
    ], unorderedEquals([('sale', inv, 'BUDI', null), ('purchase', null, null, pid), ('opening', null, null, null)]));

    final list = await db.watchPurchases().first;
    expect((list.single.purchase.supplier, list.single.account), ('Toko Lampu', 'BCA'));
    final lines = await db.purchaseLines(pid);
    expect((lines.single.product.name, lines.single.move.qty, lines.single.move.unitCost), ('LED H4', 3, 120000));

    db.ownerUnlocked = false;
    expect(() => db.watchPurchases(), throwsArgumentError);
    expect(() => db.purchaseLines(pid), throwsArgumentError);
  });

  test('stok opname mencatat selisih dan wajib alasan', () async {
    final led = await barang('LED H4', stock: 5);
    await db.adjustStock(led, 3, 'hitung ulang');
    expect(await db.stockOf(led), 3);
    final moves = await db.watchMoves(led).first;
    expect((moves.first.move.kind, moves.first.move.qty), ('adjust', -2));
    expect(() => db.adjustStock(led, 1, ''), throwsArgumentError);
  });

  test('import template Kledo: kolom dicari dari header, error dilaporkan, stok kosong = 1', () async {
    final bytes = _xlsx([
      [
        TextCellValue('*Nama Produk'),
        TextCellValue('Kode / SKU Produk'),
        TextCellValue('*Kategori Produk'),
        TextCellValue('Gambar Produk'),
        TextCellValue('*Unit Produk (Satuan)'),
        TextCellValue('Harga Pembelian'),
        TextCellValue('Kode Akun Pembelian'),
        TextCellValue('Harga Penjualan'),
        TextCellValue('Stok Minimal'),
      ],
      [
        TextCellValue('LUMA X '),
        TextCellValue('LUM/001'),
        TextCellValue('PROJECTOR'),
        null,
        TextCellValue('PCS'),
        DoubleCellValue(3100000.0),
        TextCellValue('5-50000'),
        IntCellValue(5900000),
        IntCellValue(2),
      ],
      [
        TextCellValue('DECODER LED'),
        TextCellValue('DC/001'),
        TextCellValue('LED'),
        null,
        TextCellValue('PCS'),
        TextCellValue('110500'),
        null,
        TextCellValue('Rp 200.000'),
        null,
      ],
      [
        TextCellValue('T10 WHITE'),
        TextCellValue('dc/001'),
        TextCellValue('LED'),
        null,
        TextCellValue('PCS'),
        IntCellValue(70000),
        null,
        IntCellValue(200000),
        null,
      ],
      [null, TextCellValue('X/9'), null, null, null, null, null, null, null],
    ]);
    final res = parseProductsXlsx(bytes);
    expect(res.rows.map((r) => r.name), ['LUMA X', 'DECODER LED']);
    expect(res.errors, hasLength(2)); // SKU kembar (beda huruf besar/kecil) + nama kosong
    expect(res.errors.first, contains('Baris 4'));
    expect((res.rows.first.buyPrice, res.rows.first.sellPrice, res.rows.first.minStock), (3100000, 5900000, 2));
    expect(res.rows.last.sellPrice, 200000);

    expect(await db.applyImport(res.rows), (created: 2, updated: 0, stocked: 0));
    final list = await db.watchProducts().first;
    expect(list.every((s) => s.stock == 1), true);

    // Import ulang = update, stok tidak berubah.
    expect(await db.applyImport(res.rows), (created: 0, updated: 2, stocked: 0));
    expect((await db.watchProducts().first).every((s) => s.stock == 1), true);
  });

  test('export lalu import kembali menghasilkan data yang sama', () async {
    await barang('LED H4', sku: 'LED/1', stock: 7, min: 2);
    await db.saveProduct(
      ProductsCompanion.insert(name: 'Cleaning Coating', isService: const Value(true), incentive: const Value(100000)),
    );
    final res = parseProductsXlsx(buildProductsXlsx(await db.watchProducts().first));
    expect(res.errors, isEmpty);
    final jasa = res.rows.firstWhere((r) => r.isService);
    expect((jasa.name, jasa.incentive, jasa.openingStock), ('Cleaning Coating', 100000, null));
    final led = res.rows.firstWhere((r) => !r.isService);
    expect((led.sku, led.openingStock, led.minStock), ('LED/1', 7, 2));
  });

  test('import ulang: sel kosong tidak menimpa, SKU tidak hilang, tipe tidak berubah', () async {
    final id = await db.saveProduct(
      ProductsCompanion.insert(
        name: 'DECODER LED 15',
        sku: const Value('DC/002'),
        buyPrice: const Value(85000),
        sellPrice: const Value(200000),
      ),
      openingStock: 3,
    );
    final res = parseProductsXlsx(
      _xlsx([
        [
          TextCellValue('*Nama Produk'),
          TextCellValue('Harga Pembelian'),
          TextCellValue('Harga Penjualan'),
          TextCellValue('Tipe'),
        ],
        [TextCellValue('decoder led 15'), null, TextCellValue('Rp 250.000,00'), TextCellValue('Jasa')],
      ]),
    );
    expect(await db.applyImport(res.rows), (created: 0, updated: 1, stocked: 0));
    final p = await (db.select(db.products)..where((x) => x.id.equals(id))).getSingle();
    expect((p.sku, p.buyPrice, p.sellPrice, p.isService), ('DC/002', 85000, 250000, false));
    expect(await db.stockOf(id), 3);
  });

  test('pembelian ditolak untuk jasa dan rekening nonaktif (aturan di repo, bukan di UI)', () async {
    final jasa = await db.saveProduct(ProductsCompanion.insert(name: 'Jasa Pasang', isService: const Value(true)));
    final led = await barang('LED');
    final acc = await db.select(db.accounts).get();
    expect(
      () => db.recordPurchase(
        at: DateTime.now(),
        accountId: acc.first.id,
        lines: [PurchaseLine(productId: jasa, qty: 1, unitCost: 1)],
      ),
      throwsArgumentError,
    );
    await (db.update(
      db.accounts,
    )..where((a) => a.id.equals(acc.first.id))).write(const AccountsCompanion(active: Value(false)));
    expect(
      () => db.recordPurchase(
        at: DateTime.now(),
        accountId: acc.first.id,
        lines: [PurchaseLine(productId: led, qty: 1, unitCost: 1)],
      ),
      throwsArgumentError,
    );
    expect(await db.stockOf(led), 0);
    expect(await db.select(db.cashEntries).get(), isEmpty);
  });

  test('pembelian belum dibayar: stok & harga beli tetap jalan, tidak ada kas keluar sampai dilunasi', () async {
    final led = await barang('LED', stock: 1);
    final bca = (await db.select(db.accounts).get()).firstWhere((a) => a.name == 'BCA').id;
    final id = await db.recordPurchase(
      at: DateTime(2026, 10, 18),
      accountId: bca,
      supplier: 'Toko Lampu',
      billNo: 'NOTA-9',
      paidNow: false,
      lines: [PurchaseLine(productId: led, qty: 4, unitCost: 120000)],
    );
    expect(await db.stockOf(led), 5); // stok & harga beli tetap berjalan walau belum dibayar
    expect((await (db.select(db.products)..where((p) => p.id.equals(led))).getSingle()).buyPrice, 120000);
    expect(await db.select(db.cashEntries).get(), isEmpty);
    expect((await db.watchPurchases().first).single.paid, false);

    await db.payPurchase(id, at: DateTime(2026, 10, 20));
    final cash = await db.select(db.cashEntries).getSingle();
    expect((cash.accountId, cash.amount, cash.kind, cash.refId), (bca, -480000, 'purchase', id));
    expect((await db.watchPurchases().first).single.paid, true);
    expect(() => db.payPurchase(id, at: DateTime.now()), throwsArgumentError); // sudah lunas

    db.ownerUnlocked = false;
    expect(() => db.payPurchase(id, at: DateTime.now()), throwsArgumentError);
  });

  test('input Rupiah: format ribuan, kursor tidak melompat, batas digit', () {
    final f = ThousandsFormatter();
    TextEditingValue edit(String old, String now, int cursor) => f.formatEditUpdate(
      TextEditingValue(text: old),
      TextEditingValue(
        text: now,
        selection: TextSelection.collapsed(offset: cursor),
      ),
    );
    expect(edit('', '2250000', 7).text, '2.250.000');
    // Sisip "1" setelah "2." pada "2.250.000" -> "21.250.000", kursor setelah digit ke-2.
    final r = edit('2.250.000', '2.1250.000', 3);
    expect((r.text, r.selection.end), ('21.250.000', 2));
    expect(edit('1', '1234567890123456', 16).text, '1');
  });
  test('SKU otomatis: lanjut nomor terbesar per prefix, prefix ditebak dari nama yang mirip', () {
    // Contoh data Gudang (fiktif): prefix = merek, tidak selalu tertulis di nama.
    const data = [
      ('LUMA X LASER G2', 'LUM/001'),
      ('LUMA LED V3 (HB3,H11)', 'LUM/004'),
      ('ZR800.3', 'ZR/001'),
      ('ZR1 AERO', 'ZR/004'),
      ('LED NVX PRO SERIES (H4) 65W', 'NVX/003'),
      ('MINI PROJ ALPHA YY', 'NVX/008'),
      ('NVX 2\' LASER FL', 'NVX/017'),
      ('T20 YELLOW', 'KTX/001'),
      ('T20 WHITE', 'KTX/003'),
      ('T20 WHITE BASIC', 'QB/004'),
      ('LAMA', 'ZR800.3'), // di luar pola: diabaikan
      ('TANPA SKU', null),
    ];
    final skus = data.map((d) => d.$2);
    expect(nextSku('NVX', skus), 'NVX/018');
    expect(nextSku('lum', skus), 'LUM/005');
    expect(nextSku('ABC', skus), 'ABC/001'); // prefix baru
    expect(skuPrefixes(skus), ['KTX', 'LUM', 'NVX', 'QB', 'ZR']);
    expect(guessSkuPrefix('LUMA X NEW', data), 'LUM');
    expect(guessSkuPrefix('LED NVX PRO SERIES (H9) 65W', data), 'NVX');
    expect(guessSkuPrefix('MINI PROJ ALPHA WW', data), 'NVX');
    expect(guessSkuPrefix('ZR1 NANO', data), 'ZR');
    expect(guessSkuPrefix('T20 RED', data), 'KTX');
    expect(guessSkuPrefix('T15 WHITE BASIC', data), 'QB');
    expect(guessSkuPrefix('KABEL', data), isNull);
  });

  test('R7: hapus produk — total bila belum dipakai, nonaktif + stok 0 bila sudah punya riwayat', () async {
    final baru = await barang('Barang Uji A', stock: 2);
    await db.adjustStock(baru, 3, 'hitung ulang'); // stok awal & opname bukan riwayat transaksi
    expect(await db.productHasHistory(baru), false);
    expect(await db.deleteProduct(baru), true);
    expect(await (db.select(db.products)..where((p) => p.id.equals(baru))).getSingleOrNull(), isNull);
    expect(await (db.select(db.stockMoves)..where((m) => m.productId.equals(baru))).get(), isEmpty);

    final dipakai = await barang('Barang Uji B', stock: 4);
    await db.saveDoc(
      kind: DocKind.order,
      at: DateTime(2026, 11, 1),
      lines: [LineInput(productId: dipakai, name: 'Barang Uji B', qty: 1, price: 100)],
    );
    expect(await db.productHasHistory(dipakai), true);
    expect(await db.deleteProduct(dipakai), false);
    final p = await (db.select(db.products)..where((x) => x.id.equals(dipakai))).getSingle();
    expect((p.active, await db.stockOf(dipakai)), (false, 0));
    expect(await db.select(db.invoiceLines).get(), hasLength(1)); // riwayat pemesanan tetap

    // Diimport lagi = aktif kembali (tidak tersembunyi).
    await db.applyImport([ProductRow(rowNo: 2, name: 'Barang Uji B')]);
    expect((await (db.select(db.products)..where((x) => x.id.equals(dipakai))).getSingle()).active, true);

    db.ownerUnlocked = false;
    await expectLater(db.deleteProduct(dipakai), throwsArgumentError);
  });

  test('R7: "Import & samakan stok" menyamakan stok barang lama; import biasa tidak', () async {
    final a = await barang('Barang Uji A', sku: 'UJI/1', stock: 5);
    final b = await barang('Barang Uji B', sku: 'UJI/2', stock: 2);
    final rows = [
      ProductRow(rowNo: 2, name: 'Barang Uji A', sku: 'UJI/1', openingStock: 3),
      ProductRow(rowNo: 3, name: 'Barang Uji B', sku: 'UJI/2'), // kosong = stok tidak diubah
    ];
    // Import biasa (mis. file setup lama berkolom Stok Awal) tidak menyentuh stok barang lama.
    expect(await db.applyImport(rows), (created: 0, updated: 2, stocked: 0));
    expect(await db.stockOf(a), 5);
    final r = await db.applyImport(rows, syncStock: true);
    expect(r, (created: 0, updated: 2, stocked: 1));
    expect((await db.stockOf(a), await db.stockOf(b)), (3, 2));
    final m = (await db.watchMoves(a).first).first.move;
    expect((m.kind, m.qty, m.note), ('adjust', -2, 'Import produk'));
  });

  test('R7: ubah data nota pembelian & hapus pembelian (stok ditarik, ditolak bila sudah terjual)', () async {
    final a = await barang('Barang Uji A');
    final accs = await db.select(db.accounts).get();
    final bca = accs.firstWhere((x) => x.name == 'BCA').id, tunai = accs.firstWhere((x) => x.name == 'Tunai').id;
    final id = await db.recordPurchase(
      at: DateTime(2026, 11, 2),
      accountId: bca,
      supplier: 'Toko Uji',
      lines: [PurchaseLine(productId: a, qty: 3, unitCost: 1000)],
    );
    await db.updatePurchase(
      id,
      at: DateTime(2026, 11, 1),
      accountId: tunai,
      supplier: 'Toko Uji Dua',
      billNo: 'N-1',
      proofPath: '/tmp/nota.jpg',
    );
    final p = await (db.select(db.purchases)..where((x) => x.id.equals(id))).getSingle();
    expect(
      (p.at, p.accountId, p.supplier, p.billNo, p.proofPath),
      (DateTime(2026, 11, 1), tunai, 'Toko Uji Dua', 'N-1', '/tmp/nota.jpg'),
    );
    final cash = await db.select(db.cashEntries).getSingle();
    expect(
      (cash.accountId, cash.at, cash.description),
      (tunai, DateTime(2026, 11, 1), 'Pembelian stok — Toko Uji Dua'),
    );
    expect((await db.watchMoves(a).first).single.move.at, DateTime(2026, 11, 1));

    // Sudah terjual 2 dari 3 → stok tinggal 1, menarik 3 akan minus → ditolak.
    await db.saveDoc(
      kind: DocKind.invoice,
      at: DateTime(2026, 11, 3),
      lines: [LineInput(productId: a, name: 'Barang Uji A', qty: 2, price: 100)],
    );
    await expectLater(db.deletePurchase(id), throwsArgumentError);

    final b = await barang('Barang Uji B');
    final id2 = await db.recordPurchase(
      at: DateTime(2026, 11, 4),
      accountId: bca,
      paidNow: false,
      lines: [PurchaseLine(productId: b, qty: 2, unitCost: 500)],
    );
    await db.deletePurchase(id2);
    expect(await db.stockOf(b), 0);

    // Dua baris barang sama (5 + 5), stok tinggal 7 → dihitung per produk, ditolak.
    final id3 = await db.recordPurchase(
      at: DateTime(2026, 11, 5),
      accountId: bca,
      lines: [
        PurchaseLine(productId: b, qty: 5, unitCost: 1),
        PurchaseLine(productId: b, qty: 5, unitCost: 1),
      ],
    );
    await db.adjustStock(b, 7, 'hitung ulang');
    await expectLater(db.deletePurchase(id3), throwsArgumentError);

    // Dilunasi belakangan: tanggal beli tidak boleh digeser melewati tanggal lunas.
    final id4 = await db.recordPurchase(
      at: DateTime(2026, 11, 1),
      accountId: bca,
      paidNow: false,
      lines: [PurchaseLine(productId: b, qty: 1, unitCost: 1)],
    );
    await db.payPurchase(id4, at: DateTime(2026, 11, 5));
    await expectLater(db.updatePurchase(id4, at: DateTime(2026, 11, 10), accountId: bca), throwsArgumentError);
    await db.updatePurchase(id4, at: DateTime(2026, 11, 3), accountId: bca, note: 'baru');
    final paidCash = await (db.select(db.cashEntries)..where((x) => x.refId.equals(id4))).getSingle();
    expect((paidCash.at, paidCash.note), (DateTime(2026, 11, 5), '')); // tanggal & keterangan lunas tetap
    expect(await (db.select(db.purchases)..where((x) => x.id.equals(id2))).getSingleOrNull(), isNull);

    db.ownerUnlocked = false;
    await expectLater(db.deletePurchase(id), throwsArgumentError);
    await expectLater(db.updatePurchase(id, at: DateTime(2026, 11, 1), accountId: bca), throwsArgumentError);
  });
}
