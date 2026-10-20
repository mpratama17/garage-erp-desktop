import 'package:drift/drift.dart';

import '../../core/format.dart';
import '../../core/xlsx.dart';
import '../../db/database.dart';

class StockedProduct {
  StockedProduct(this.product, this.stock);
  final Product product;
  final int stock;

  bool get isService => product.isService;
  bool get isLow => !isService && stock <= product.minStock;
}

/// Satu baris riwayat stok + asalnya: invoice & customer (penjualan/batal) atau pembelian.
class MoveRow {
  MoveRow(this.move, {this.doc, this.customer, this.purchase});
  final StockMove move;
  final Invoice? doc;
  final String? customer; // null = tanpa customer (UMUM)
  final Purchase? purchase;
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

/// Baca sheet pertama file .xlsx. Kolom dicari dari nama header, bukan posisi.
ImportResult parseProductsXlsx(List<int> bytes) {
  final t = XlsxTable.decode(bytes);
  if (t.rows.isEmpty) return ImportResult([], ['File kosong']);
  if (!t.has('Nama Produk')) {
    return ImportResult([], ['Kolom "*Nama Produk" tidak ditemukan — pakai template dari tombol Template']);
  }

  final out = <ProductRow>[];
  final errors = <String>[];
  final seenSku = <String>{};
  for (final (rowNo, r) in t.dataRows) {
    final name = t.text(r, 'Nama Produk');
    if (name.isEmpty) {
      errors.add('Baris $rowNo: nama produk kosong');
      continue;
    }
    final sku = t.text(r, 'Kode / SKU Produk');
    if (sku.isNotEmpty && !seenSku.add(sku.toUpperCase())) {
      errors.add('Baris $rowNo: SKU "$sku" dipakai lebih dari sekali di file ("$name")');
      continue;
    }
    out.add(
      ProductRow(
        rowNo: rowNo,
        name: name,
        sku: sku.nullIfEmpty,
        category: t.text(r, 'Kategori Produk').nullIfEmpty,
        unit: t.text(r, 'Unit Produk (Satuan)').ifEmpty('PCS'),
        isService: t.text(r, 'Tipe').toLowerCase() == 'jasa',
        buyPrice: t.number(r, 'Harga Pembelian'),
        sellPrice: t.number(r, 'Harga Penjualan'),
        minStock: t.number(r, 'Stok Minimal'),
        openingStock: t.number(r, 'Stok Awal') ?? t.number(r, 'Stok'),
        incentive: t.number(r, 'Tarif Insentif'),
      ),
    );
  }
  return ImportResult(out, errors);
}

/// File .xlsx berisi produk (atau template kosong bila [items] kosong).
List<int> buildProductsXlsx(List<StockedProduct> items) => buildXlsx('Produk', productHeaders, [
  for (final s in items)
    [
      s.product.name,
      s.product.sku ?? '',
      s.product.category,
      s.product.unit,
      s.product.buyPrice,
      s.product.sellPrice,
      s.product.minStock,
      s.isService ? 'Jasa' : 'Barang',
      s.isService ? null : s.stock,
      s.product.incentive,
    ],
]);

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

  Stream<List<MoveRow>> watchMoves(int productId) {
    final q =
        select(stockMoves).join([
            leftOuterJoin(invoices, invoices.id.equalsExp(stockMoves.refId) & stockMoves.kind.isIn(['sale', 'void'])),
            leftOuterJoin(customers, customers.id.equalsExp(invoices.customerId)),
            leftOuterJoin(purchases, purchases.id.equalsExp(stockMoves.refId) & stockMoves.kind.equals('purchase')),
          ])
          ..where(stockMoves.productId.equals(productId))
          ..orderBy([OrderingTerm.desc(stockMoves.at), OrderingTerm.desc(stockMoves.id)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          MoveRow(
            r.readTable(stockMoves),
            doc: r.readTableOrNull(invoices),
            customer: r.readTableOrNull(customers)?.name,
            purchase: r.readTableOrNull(purchases),
          ),
      ],
    );
  }

  /// Riwayat pembelian stok + nama rekening pembayar, terbaru dulu. Khusus owner (berisi harga beli).
  Stream<List<({Purchase purchase, String account})>> watchPurchases() {
    requireOwner();
    final q = select(purchases).join([innerJoin(accounts, accounts.id.equalsExp(purchases.accountId))])
      ..orderBy([OrderingTerm.desc(purchases.at), OrderingTerm.desc(purchases.id)]);
    return q.watch().map(
      (rows) => [for (final r in rows) (purchase: r.readTable(purchases), account: r.readTable(accounts).name)],
    );
  }

  /// Rincian barang satu pembelian (qty & harga beli per unit). Khusus owner.
  Future<List<({StockMove move, Product product})>> purchaseLines(int purchaseId) async {
    requireOwner();
    final q = select(stockMoves).join([innerJoin(products, products.id.equalsExp(stockMoves.productId))])
      ..where(stockMoves.kind.equals('purchase') & stockMoves.refId.equals(purchaseId))
      ..orderBy([OrderingTerm.asc(stockMoves.id)]);
    return [for (final r in await q.get()) (move: r.readTable(stockMoves), product: r.readTable(products))];
  }

  /// Simpan produk baru/lama. Untuk barang baru, [openingStock] > 0 dicatat sebagai stok awal.
  /// Melempar [ArgumentError] dengan pesan untuk pengguna bila data tidak valid.
  Future<int> saveProduct(ProductsCompanion p, {int openingStock = 0}) async {
    requireOwner(); // mode terkunci = hanya lihat (C18)
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
    requireOwner();
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
    requireOwner();
    if (lines.isEmpty) throw ArgumentError('Belum ada barang');
    if (lines.any((l) => l.qty <= 0 || l.unitCost < 0)) {
      throw ArgumentError('Qty harus lebih dari 0 dan harga tidak boleh minus');
    }
    final total = lines.fold(0, (s, l) => s + l.qty * l.unitCost);
    return transaction(() async {
      await requireActiveAccount(accountId);
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
    requireOwner(); // import menulis harga beli
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
