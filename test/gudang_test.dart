import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/core/ui.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';

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

  test('stok opname mencatat selisih dan wajib alasan', () async {
    final led = await barang('LED H4', stock: 5);
    await db.adjustStock(led, 3, 'hitung ulang');
    expect(await db.stockOf(led), 3);
    final moves = await db.watchMoves(led).first;
    expect((moves.first.kind, moves.first.qty), ('adjust', -2));
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
        TextCellValue('OSRAM CBI '),
        TextCellValue('OSR/001'),
        TextCellValue('PROJECTOR'),
        null,
        TextCellValue('PCS'),
        DoubleCellValue(3400000.0),
        TextCellValue('5-50000'),
        IntCellValue(6500000),
        IntCellValue(2),
      ],
      [
        TextCellValue('CANBUS LED'),
        TextCellValue('CB/001'),
        TextCellValue('LED'),
        null,
        TextCellValue('PCS'),
        TextCellValue('120750'),
        null,
        TextCellValue('Rp 200.000'),
        null,
      ],
      [
        TextCellValue('T10 WHITE'),
        TextCellValue('cb/001'),
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
    expect(res.rows.map((r) => r.name), ['OSRAM CBI', 'CANBUS LED']);
    expect(res.errors, hasLength(2)); // SKU kembar (beda huruf besar/kecil) + nama kosong
    expect(res.errors.first, contains('Baris 4'));
    expect((res.rows.first.buyPrice, res.rows.first.sellPrice, res.rows.first.minStock), (3400000, 6500000, 2));
    expect(res.rows.last.sellPrice, 200000);

    expect(await db.applyImport(res.rows), (created: 2, updated: 0));
    final list = await db.watchProducts().first;
    expect(list.every((s) => s.stock == 1), true);

    // Import ulang = update, stok tidak berubah.
    expect(await db.applyImport(res.rows), (created: 0, updated: 2));
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
        name: 'CANBUS LED 15',
        sku: const Value('CB/002'),
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
        [TextCellValue('canbus led 15'), null, TextCellValue('Rp 250.000,00'), TextCellValue('Jasa')],
      ]),
    );
    expect(await db.applyImport(res.rows), (created: 0, updated: 1));
    final p = await (db.select(db.products)..where((x) => x.id.equals(id))).getSingle();
    expect((p.sku, p.buyPrice, p.sellPrice, p.isService), ('CB/002', 85000, 250000, false));
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
}
