import 'package:drift/drift.dart';
import 'package:excel/excel.dart';

import '../../core/format.dart';
import '../../db/database.dart';

class StockedProduct {
  StockedProduct(this.product, this.stock);
  final Product product;
  final int stock;

  bool get isService => product.isService;
  bool get isLow => !isService && stock <= product.minStock;
}

class PurchaseLine {
  PurchaseLine({required this.productId, required this.qty, required this.unitCost});
  final int productId;
  final int qty;
  final int unitCost;
}

/// Satu baris hasil baca file import (sudah divalidasi).
class ProductRow {
  ProductRow({
    required this.rowNo,
    required this.name,
    this.sku,
    this.category,
    this.unit = 'PCS',
    this.isService = false,
    this.buyPrice,
    this.sellPrice,
    this.minStock,
    this.openingStock,
    this.incentive,
  });
  final int rowNo;
  final String name;
  final String unit;
  final bool isService;
  // null = sel kosong di file: tidak menimpa nilai produk yang sudah ada.
  final String? sku, category;
  final int? buyPrice, sellPrice, minStock, incentive, openingStock;
}

class ImportResult {
  ImportResult(this.rows, this.errors);
  final List<ProductRow> rows;
  final List<String> errors; // "Baris 12: …"
}

/// Header export/template: kompatibel template produk Kledo + kolom tambahan app.
const productHeaders = [
  '*Nama Produk',
  'Kode / SKU Produk',
  '*Kategori Produk',
  '*Unit Produk (Satuan)',
  'Harga Pembelian',
  'Harga Penjualan',
  'Stok Minimal',
  'Tipe',
  'Stok Awal',
  'Tarif Insentif',
];

String _key(String h) => h.replaceAll('*', '').trim().toLowerCase();

String _cellText(Data? d) => switch (d?.value) {
  null => '',
  TextCellValue(:final value) => (value.text ?? '').trim(),
  IntCellValue(:final value) => '$value',
  DoubleCellValue(:final value) => value == value.roundToDouble() ? '${value.round()}' : '$value',
  final v => v.toString().trim(),
};

/// "3400000", "3400000.0", "Rp 3.400.000", "Rp 3.400.000,00" -> 3400000. null bila kosong.
int? _cellInt(Data? d) {
  final v = d?.value;
  if (v is IntCellValue) return v.value;
  if (v is DoubleCellValue) return v.value.round();
  final t = _cellText(d);
  if (t.isEmpty) return null;
  // Rupiah tanpa sen: buang pecahan 1–2 digit di akhir ("…,00" / "….5") sebelum ambil digit.
  return parseRupiah(t.replaceFirst(RegExp(r'[.,]\d{1,2}$'), ''));
}

/// Baca sheet pertama file .xlsx. Kolom dicari dari nama header, bukan posisi.
ImportResult parseProductsXlsx(List<int> bytes) {
  final excel = Excel.decodeBytes(bytes);
  final sheet = excel.tables.values.first;
  final rows = sheet.rows;
  if (rows.isEmpty) return ImportResult([], ['File kosong']);
  final col = {for (var i = 0; i < rows.first.length; i++) _key(_cellText(rows.first[i])): i};
  Data? at(List<Data?> r, String header) {
    final i = col[_key(header)];
    return i == null || i >= r.length ? null : r[i];
  }

  if (!col.containsKey('nama produk')) {
    return ImportResult([], ['Kolom "*Nama Produk" tidak ditemukan — pakai template dari tombol Template']);
  }

  final out = <ProductRow>[];
  final errors = <String>[];
  final seenSku = <String>{};
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    final rowNo = i + 1;
    final name = _cellText(at(r, 'Nama Produk'));
    if (r.every((c) => _cellText(c).isEmpty)) continue;
    if (name.isEmpty) {
      errors.add('Baris $rowNo: nama produk kosong');
      continue;
    }
    final sku = _cellText(at(r, 'Kode / SKU Produk'));
    if (sku.isNotEmpty && !seenSku.add(sku.toUpperCase())) {
      errors.add('Baris $rowNo: SKU "$sku" dipakai lebih dari sekali di file ("$name")');
      continue;
    }
    final type = _cellText(at(r, 'Tipe')).toLowerCase();
    out.add(
      ProductRow(
        rowNo: rowNo,
        name: name,
        sku: sku.isEmpty ? null : sku,
        category: _cellText(at(r, 'Kategori Produk')).nullIfEmpty,
        unit: _cellText(at(r, 'Unit Produk (Satuan)')).ifEmpty('PCS'),
        isService: type == 'jasa',
        buyPrice: _cellInt(at(r, 'Harga Pembelian')),
        sellPrice: _cellInt(at(r, 'Harga Penjualan')),
        minStock: _cellInt(at(r, 'Stok Minimal')),
        openingStock: _cellInt(at(r, 'Stok Awal')) ?? _cellInt(at(r, 'Stok')),
        incentive: _cellInt(at(r, 'Tarif Insentif')),
      ),
    );
  }
  return ImportResult(out, errors);
}

/// File .xlsx berisi produk (atau template kosong bila [items] kosong).
List<int> buildProductsXlsx(List<StockedProduct> items) {
  final excel = Excel.createExcel();
  final name = excel.getDefaultSheet()!;
  excel.appendRow(name, [for (final h in productHeaders) TextCellValue(h)]);
  for (final s in items) {
    final p = s.product;
    excel.appendRow(name, [
      TextCellValue(p.name),
      TextCellValue(p.sku ?? ''),
      TextCellValue(p.category),
      TextCellValue(p.unit),
      IntCellValue(p.buyPrice),
      IntCellValue(p.sellPrice),
      IntCellValue(p.minStock),
      TextCellValue(p.isService ? 'Jasa' : 'Barang'),
      p.isService ? null : IntCellValue(s.stock),
      IntCellValue(p.incentive),
    ]);
  }
  excel.rename(name, 'Produk');
  return excel.encode()!;
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
  String? get nullIfEmpty => isEmpty ? null : this;
}

extension GudangRepo on AppDb {
  Stream<List<StockedProduct>> watchProducts() => customSelect(
    'SELECT p.*, COALESCE(SUM(m.qty), 0) AS stock FROM products p '
    'LEFT JOIN stock_moves m ON m.product_id = p.id '
    'GROUP BY p.id ORDER BY p.name COLLATE NOCASE',
    readsFrom: {products, stockMoves},
  ).watch().map((rows) => [for (final r in rows) StockedProduct(products.map(r.data), r.read<int>('stock'))]);

  Future<int> stockOf(int productId) async {
    final sum = stockMoves.qty.sum();
    final row =
        await (selectOnly(stockMoves)
              ..addColumns([sum])
              ..where(stockMoves.productId.equals(productId)))
            .getSingle();
    return row.read(sum) ?? 0;
  }

  Stream<List<StockMove>> watchMoves(int productId) =>
      (select(stockMoves)
            ..where((m) => m.productId.equals(productId))
            ..orderBy([(m) => OrderingTerm.desc(m.at), (m) => OrderingTerm.desc(m.id)]))
          .watch();

  /// Simpan produk baru/lama. Untuk barang baru, [openingStock] > 0 dicatat sebagai stok awal.
  /// Melempar [ArgumentError] dengan pesan untuk pengguna bila data tidak valid.
  Future<int> saveProduct(ProductsCompanion p, {int openingStock = 0}) async {
    final name = p.name.value.trim();
    if (name.isEmpty) throw ArgumentError('Nama produk wajib diisi');
    final sku = p.sku.present ? p.sku.value?.trim() : null;
    final clean = p.copyWith(name: Value(name), sku: Value(sku == null || sku.isEmpty ? null : sku));
    if (clean.sku.value != null) {
      final dup =
          await (select(products)..where(
                (x) =>
                    x.sku.equals(clean.sku.value!) &
                    (p.id.present ? x.id.equals(p.id.value).not() : const Constant(true)),
              ))
              .getSingleOrNull();
      if (dup != null) throw ArgumentError('SKU "${clean.sku.value}" sudah dipakai "${dup.name}"');
    }
    return transaction(() async {
      if (p.id.present) {
        await (update(products)..where((x) => x.id.equals(p.id.value))).write(clean);
        return p.id.value;
      }
      final id = await into(products).insert(clean);
      if (openingStock > 0 && !(clean.isService.present && clean.isService.value)) {
        await into(stockMoves)
            .insert(StockMovesCompanion.insert(at: DateTime.now(), productId: id, qty: openingStock, kind: 'opening'));
      }
      return id;
    });
  }

  /// Stok opname: set stok menjadi [actual]; selisihnya dicatat sebagai penyesuaian.
  Future<void> adjustStock(int productId, int actual, String note) async {
    if (note.trim().isEmpty) throw ArgumentError('Alasan penyesuaian wajib diisi');
    await transaction(() async {
      final delta = actual - await stockOf(productId);
      if (delta == 0) return;
      await into(stockMoves).insert(
        StockMovesCompanion.insert(
          at: DateTime.now(),
          productId: productId,
          qty: delta,
          kind: 'adjust',
          note: Value(note.trim()),
        ),
      );
    });
  }

  /// Pembelian stok: stok bertambah, harga beli produk diperbarui, saldo rekening berkurang.
  Future<int> recordPurchase({
    required DateTime at,
    required int accountId,
    required List<PurchaseLine> lines,
    String supplier = '',
    String note = '',
  }) {
    if (lines.isEmpty) throw ArgumentError('Belum ada barang');
    if (lines.any((l) => l.qty <= 0 || l.unitCost < 0)) {
      throw ArgumentError('Qty harus lebih dari 0 dan harga tidak boleh minus');
    }
    final total = lines.fold(0, (s, l) => s + l.qty * l.unitCost);
    return transaction(() async {
      final acc = await (select(accounts)..where((a) => a.id.equals(accountId))).getSingleOrNull();
      if (acc == null || !acc.active) throw ArgumentError('Rekening tidak ditemukan atau nonaktif');
      final ids = lines.map((l) => l.productId).toSet();
      final items = await (select(products)..where((x) => x.id.isIn(ids))).get();
      if (items.length != ids.length || items.any((x) => x.isService)) {
        throw ArgumentError('Pembelian stok hanya untuk barang (bukan jasa)');
      }
      final id = await into(purchases).insert(
        PurchasesCompanion.insert(
          at: at,
          accountId: accountId,
          total: total,
          supplier: Value(supplier.trim()),
          note: Value(note.trim()),
        ),
      );
      for (final l in lines) {
        await into(stockMoves).insert(
          StockMovesCompanion.insert(
            at: at,
            productId: l.productId,
            qty: l.qty,
            kind: 'purchase',
            refId: Value(id),
            unitCost: Value(l.unitCost),
          ),
        );
        await (update(
          products,
        )..where((x) => x.id.equals(l.productId))).write(ProductsCompanion(buyPrice: Value(l.unitCost)));
      }
      await into(cashEntries).insert(
        CashEntriesCompanion.insert(
          at: at,
          accountId: accountId,
          amount: -total,
          kind: 'purchase',
          refId: Value(id),
          description: supplier.trim().isEmpty ? 'Pembelian stok' : 'Pembelian stok — ${supplier.trim()}',
          note: Value(note.trim()),
        ),
      );
      return id;
    });
  }

  /// Terapkan hasil import: cocokkan ke produk lama via SKU (atau nama bila tanpa SKU).
  /// Barang baru tanpa stok awal diisi 1 (keputusan client). Stok produk lama tidak diubah.
  Future<({int created, int updated})> applyImport(List<ProductRow> rows) => transaction(() async {
    var created = 0, updated = 0;
    final existing = await select(products).get();
    final bySku = {
      for (final p in existing)
        if (p.sku != null) p.sku!.toUpperCase(): p,
    };
    final byName = {for (final p in existing) p.name.toUpperCase(): p};
    for (final r in rows) {
      final match = r.sku != null ? bySku[r.sku!.toUpperCase()] : byName[r.name.toUpperCase()];
      // Sel kosong = biarkan nilai lama. SKU tidak pernah dihapus, tipe barang/jasa tidak diubah.
      final data = ProductsCompanion(
        name: Value(r.name),
        sku: r.sku == null ? const Value.absent() : Value(r.sku),
        category: r.category == null ? const Value.absent() : Value(r.category!),
        unit: Value(r.unit),
        buyPrice: r.buyPrice == null ? const Value.absent() : Value(r.buyPrice!),
        sellPrice: r.sellPrice == null ? const Value.absent() : Value(r.sellPrice!),
        minStock: r.minStock == null ? const Value.absent() : Value(r.minStock!),
        incentive: r.incentive == null ? const Value.absent() : Value(r.incentive!),
      );
      if (match != null) {
        await (update(products)..where((x) => x.id.equals(match.id))).write(data);
        updated++;
      } else {
        await saveProduct(
          data.copyWith(isService: Value(r.isService)),
          openingStock: r.isService ? 0 : (r.openingStock ?? 1),
        );
        created++;
      }
    }
    return (created: created, updated: updated);
  });
}
