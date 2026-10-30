import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/format.dart';
import '../../core/xlsx.dart';
import '../../db/database.dart';
import '../kontak/kontak_repo.dart' show KontakRepo;

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

/// Satu baris riwayat pembelian stok: [paidAt] = tanggal pelunasan (null = belum dibayar).
typedef PurchaseRow = ({Purchase purchase, String account, bool paid, DateTime? paidAt});

/// Format SKU client: PREFIX/NNN per merek (OSR/001, HVT/017). Kode lain (mis. "SR800.3") tidak dihitung.
final _skuPattern = RegExp(r'^([A-Z]+)/(\d+)$');

/// SKU berikutnya untuk [prefix]: nomor terbesar prefix itu + 1 (HVT/017 → HVT/018); prefix baru mulai /001.
String nextSku(String prefix, Iterable<String?> skus) {
  final p = prefix.trim().toUpperCase();
  var last = 0;
  for (final s in skus) {
    final m = _skuPattern.firstMatch(s?.trim().toUpperCase() ?? '');
    if (m != null && m[1] == p) last = max(last, int.parse(m[2]!));
  }
  return '$p/${(last + 1).toString().padLeft(3, '0')}';
}

/// Prefix SKU yang sudah dipakai produk, urut abjad.
List<String> skuPrefixes(Iterable<String?> skus) =>
    {for (final s in skus) ?_skuPattern.firstMatch(s?.trim().toUpperCase() ?? '')?[1]}.toList()..sort();

/// Tebak prefix SKU dari produk yang namanya paling mirip [name] (prefix tidak selalu ada di nama: "T20 YELLOW"
/// = RCH). Kata yang sama menambah skor; kata umum (dipakai banyak produk, mis. LED, WHITE) bernilai kecil.
/// null = tidak ada yang mirip.
String? guessSkuPrefix(String name, Iterable<(String name, String? sku)> products) {
  Set<String> words(String s) => s.toUpperCase().split(RegExp(r'[^A-Z0-9.]+')).where((w) => w.length >= 2).toSet();
  final coded = [
    for (final (n, sku) in products)
      if (_skuPattern.firstMatch(sku?.trim().toUpperCase() ?? '') case final m?) (words(n), m[1]!),
  ];
  final used = <String, int>{}; // kata → jumlah produk yang memakainya
  for (final (w, _) in coded) {
    for (final x in w) {
      used[x] = (used[x] ?? 0) + 1;
    }
  }
  final target = words(name);
  String? best;
  var bestScore = 0.0;
  for (final (w, prefix) in coded) {
    final score = w.intersection(target).fold(0.0, (t, x) => t + 1 / used[x]!);
    if (score > bestScore) (best, bestScore) = (prefix, score);
  }
  return best;
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
    return ImportResult([], [
      'Kolom "*Nama Produk" tidak ditemukan — pakai template dari menu Import ▸ Unduh template',
    ]);
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
  /// Pola query di repo: `xxxQuery()` → `.watch()` untuk layar, `.get()` untuk sekali jalan (jangan
  /// `watch().first` — bisa macet, lihat c12bfd5).
  Selectable<StockedProduct> productsQuery() => customSelect(
    'SELECT p.*, COALESCE(SUM(m.qty), 0) AS stock FROM products p '
    'LEFT JOIN stock_moves m ON m.product_id = p.id '
    'GROUP BY p.id ORDER BY p.name COLLATE NOCASE',
    readsFrom: {products, stockMoves},
  ).map((r) => StockedProduct(products.map(r.data), r.read<int>('stock')));

  Stream<List<StockedProduct>> watchProducts() => productsQuery().watch();

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

  /// Total seluruh waktu: penjualan barang (invoice tidak batal, sebelum diskon/PPN dokumen) dan pembelian stok.
  /// Pembelian berisi harga beli → 0 selama owner terkunci.
  Future<({int sales, int purchases})> stockFlowTotals() async {
    final sales = await customSelect(
      'SELECT COALESCE(SUM(l.qty * l.price - l.discount), 0) AS t FROM invoice_lines l '
      'JOIN invoices i ON i.id = l.invoice_id JOIN products p ON p.id = l.product_id '
      "WHERE i.kind = 'invoice' AND i.is_void = 0 AND p.is_service = 0",
      readsFrom: {invoiceLines, invoices, products},
    ).getSingle();
    final bought = ownerUnlocked
        ? await customSelect('SELECT COALESCE(SUM(total), 0) AS t FROM purchases', readsFrom: {purchases}).getSingle()
        : null;
    return (sales: sales.read<int>('t'), purchases: bought?.read<int>('t') ?? 0);
  }

  /// Riwayat pembelian stok + nama rekening pembayar, terbaru dulu. Khusus owner (berisi harga beli).
  Stream<List<PurchaseRow>> watchPurchases() => purchasesQuery().watch();

  Selectable<PurchaseRow> purchasesQuery() {
    requireOwner();
    final q = select(purchases).join([
      innerJoin(accounts, accounts.id.equalsExp(purchases.accountId)),
      leftOuterJoin(cashEntries, cashEntries.kind.equals('purchase') & cashEntries.refId.equalsExp(purchases.id)),
    ])..orderBy([OrderingTerm.desc(purchases.at), OrderingTerm.desc(purchases.id)]);
    return q.map(
      (r) => (
        purchase: r.readTable(purchases),
        account: r.readTable(accounts).name,
        paid: r.readTableOrNull(cashEntries) != null,
        paidAt: r.readTableOrNull(cashEntries)?.at,
      ),
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
  /// [paidNow] = false: dicatat belum dibayar (barang & harga beli tetap diperbarui), dilunasi lewat
  /// [payPurchase]. Client: pembelian selalu lunas penuh, kadang beberapa hari kemudian (tidak dicicil).
  Future<int> recordPurchase({
    required DateTime at,
    required int accountId,
    required List<PurchaseLine> lines,
    String supplier = '',
    String note = '',
    String billNo = '',
    String proofPath = '',
    bool paidNow = true,
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
      final vendor = await vendorByName(supplier);
      final no = await takeNumber(
        'next_purchase_no',
        '',
        width: 7,
        taken: (no) async =>
            await (select(purchases)
                  ..where((x) => x.no.equals(no))
                  ..limit(1))
                .getSingleOrNull() !=
            null,
      );
      final id = await into(purchases).insert(
        PurchasesCompanion.insert(
          at: at,
          accountId: accountId,
          total: total,
          supplier: Value(vendor?.name ?? ''), // nama baku vendor, bukan ejaan yang diketik
          vendorId: Value(vendor?.id),
          note: Value(note.trim()),
          billNo: Value(billNo.trim()),
          proofPath: Value(proofPath),
          no: Value(no),
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
      if (paidNow) await _payPurchase(id, accountId, total, supplier, at, note);
      return id;
    });
  }

  Future<void> _payPurchase(int id, int accountId, int total, String supplier, DateTime at, String note) =>
      into(cashEntries).insert(
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

  /// Lunasi pembelian yang tadinya [recordPurchase]-nya [paidNow]=false. Dibayar dari rekening yang
  /// dipilih saat pembelian dicatat (bukan dipilih ulang) — selaras dengan dialog pembelian.
  Future<void> payPurchase(int purchaseId, {required DateTime at}) => transaction(() async {
    requireOwner();
    final p = await (select(purchases)..where((x) => x.id.equals(purchaseId))).getSingle();
    final already = await (select(
      cashEntries,
    )..where((c) => c.kind.equals('purchase') & c.refId.equals(purchaseId))).getSingleOrNull();
    if (already != null) throw ArgumentError('${p.supplier.isEmpty ? 'Pembelian' : p.supplier} sudah dibayar');
    await requireActiveAccount(p.accountId);
    await _payPurchase(purchaseId, p.accountId, p.total, p.supplier, at, '');
  });

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
