import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'money.dart';

part 'db.g.dart';

enum ProductType { barang, jasa, paket }

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().withDefault(const Constant(''))();
  TextColumn get name => text()();
  IntColumn get type => intEnum<ProductType>()();
  IntColumn get sellPrice => integer()();
  IntColumn get minStock => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// Komposisi paket: paket [bundleId] berisi [qty] x [productId].
class BundleItems extends Table {
  IntColumn get bundleId => integer().references(Products, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get qty => integer()();
  @override
  Set<Column> get primaryKey => {bundleId, productId};
}

/// Buku stok. Stok = SUM(qty). Hanya produk `barang` yang punya move.
class StockMoves extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get qty => integer()();
  IntColumn get unitCost => integer().withDefault(const Constant(0))();
  TextColumn get refType => text()(); // purchase | sale | void | adjust
  IntColumn get refId => integer().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
}

class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supplier => text().withDefault(const Constant(''))();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().unique()();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get no => text().unique()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  TextColumn get car => text().withDefault(const Constant(''))();
  TextColumn get plate => text().withDefault(const Constant(''))();
  BoolColumn get ppn => boolean().withDefault(const Constant(false))();
  TextColumn get payMethod => text()(); // Cash | Transfer | QRIS
  IntColumn get subtotal => integer()();
  IntColumn get total => integer()();
  BoolColumn get isVoid => boolean().withDefault(const Constant(false))();
  TextColumn get voidReason => text().withDefault(const Constant(''))();
}

class InvoiceLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get name => text()(); // snapshot
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get qty => integer()();
  IntColumn get price => integer()();
  IntColumn get discountPct => integer().withDefault(const Constant(0))();
  IntColumn get total => integer()();
  IntColumn get cost => integer()(); // HPP per unit saat jual
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class CartLine {
  CartLine(this.product, {this.qty = 1, int? price, this.discountPct = 0, this.description = ''})
      : price = price ?? product.sellPrice;
  final Product product;
  int qty;
  int price;
  int discountPct;
  String description;
  int get total => lineTotal(qty, price, discountPct);
}

@DriftDatabase(tables: [
  Products, BundleItems, StockMoves, Purchases, Customers, Invoices,
  InvoiceLines, Settings,
])
class AppDb extends _$AppDb {
  AppDb([QueryExecutor? e]) : super(e ?? driftDatabase(name: 'star_garage'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
      );

  // ---- settings ----
  Future<String> setting(String key, [String fallback = '']) async =>
      (await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull())
          ?.value ??
      fallback;

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  // ---- stok & HPP ----
  Future<int> stockOf(int productId) async {
    final sum = stockMoves.qty.sum();
    final row = await (selectOnly(stockMoves)
          ..addColumns([sum])
          ..where(stockMoves.productId.equals(productId)))
        .getSingle();
    return row.read(sum) ?? 0;
  }

  /// HPP rata-rata tertimbang dari semua pembelian.
  // ponytail: weighted average over all purchases, not perpetual moving average; fine while cost prices are stable.
  Future<int> avgCost(int productId) async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(qty * unit_cost) * 1.0 / NULLIF(SUM(qty), 0), 0) AS c '
      "FROM stock_moves WHERE product_id = ? AND ref_type = 'purchase'",
      variables: [Variable.withInt(productId)],
      readsFrom: {stockMoves},
    ).getSingle();
    return (row.read<double>('c')).round();
  }

  Future<List<BundleItem>> bundleOf(int bundleId) =>
      (select(bundleItems)..where((b) => b.bundleId.equals(bundleId))).get();

  Future<void> setBundle(int bundleId, Map<int, int> items) => transaction(() async {
        await (delete(bundleItems)..where((b) => b.bundleId.equals(bundleId))).go();
        for (final e in items.entries) {
          await into(bundleItems).insert(
              BundleItemsCompanion.insert(bundleId: bundleId, productId: e.key, qty: e.value));
        }
      });

  /// Barang fisik yang berkurang untuk 1 unit produk ini: {productId: qty}.
  Future<Map<int, int>> _components(Product p) async => switch (p.type) {
        ProductType.barang => {p.id: 1},
        ProductType.jasa => {},
        ProductType.paket => {for (final b in await bundleOf(p.id)) b.productId: b.qty},
      };

  Future<int> unitCost(Product p) async {
    var c = 0;
    for (final e in (await _components(p)).entries) {
      c += await avgCost(e.key) * e.value;
    }
    return c;
  }

  Future<int> recordPurchase(String supplier, List<({int productId, int qty, int unitCost})> lines) =>
      transaction(() async {
        final id = await into(purchases).insert(PurchasesCompanion.insert(supplier: Value(supplier)));
        for (final l in lines) {
          await into(stockMoves).insert(StockMovesCompanion.insert(
              productId: l.productId, qty: l.qty, unitCost: Value(l.unitCost),
              refType: 'purchase', refId: Value(id)));
        }
        return id;
      });

  Future<void> adjustStock(int productId, int delta, String note) =>
      into(stockMoves).insert(StockMovesCompanion.insert(
          productId: productId, qty: delta, refType: 'adjust', note: Value(note)));

  // ---- customer ----
  /// Cari by HP; buat baru kalau belum ada, update nama kalau berubah.
  Future<int?> upsertCustomer(String name, String phone) async {
    final p = normalizePhone(phone);
    if (p.isEmpty) return null;
    final existing = await (select(customers)..where((c) => c.phone.equals(p))).getSingleOrNull();
    if (existing == null) {
      return into(customers).insert(CustomersCompanion.insert(name: name.trim(), phone: p));
    }
    if (name.trim().isNotEmpty && name.trim() != existing.name) {
      await (update(customers)..where((c) => c.id.equals(existing.id)))
          .write(CustomersCompanion(name: Value(name.trim())));
    }
    return existing.id;
  }

  // ---- invoice ----
  Future<String> _nextInvoiceNo() async {
    final n = int.parse(await setting('last_invoice_no', '0')) + 1;
    await setSetting('last_invoice_no', '$n');
    return 'INV/${n.toString().padLeft(5, '0')}';
  }

  Future<Invoice> createInvoice({
    required List<CartLine> lines,
    required String payMethod,
    int? customerId,
    String car = '',
    String plate = '',
    bool ppn = false,
  }) {
    if (lines.isEmpty) throw ArgumentError('Keranjang kosong');
    return transaction(() async {
      final subtotal = lines.fold(0, (s, l) => s + l.total);
      final total = subtotal + (ppn ? ppnOf(subtotal) : 0);
      final id = await into(invoices).insert(InvoicesCompanion.insert(
        no: await _nextInvoiceNo(),
        customerId: Value(customerId),
        car: Value(car.trim()),
        plate: Value(plate.trim().toUpperCase()),
        ppn: Value(ppn),
        payMethod: payMethod,
        subtotal: subtotal,
        total: total,
      ));
      for (final l in lines) {
        await into(invoiceLines).insert(InvoiceLinesCompanion.insert(
          invoiceId: id, productId: l.product.id, name: l.product.name,
          description: Value(l.description), qty: l.qty, price: l.price,
          discountPct: Value(l.discountPct), total: l.total,
          cost: await unitCost(l.product),
        ));
        // Stok boleh minus: toko sering jual dulu sebelum input pembelian.
        for (final c in (await _components(l.product)).entries) {
          await into(stockMoves).insert(StockMovesCompanion.insert(
              productId: c.key, qty: -c.value * l.qty, refType: 'sale', refId: Value(id)));
        }
      }
      return (select(invoices)..where((i) => i.id.equals(id))).getSingle();
    });
  }

  /// Void: tandai batal + balikkan semua stok keluar dari nota ini.
  Future<void> voidInvoice(int id, String reason) => transaction(() async {
        final inv = await (select(invoices)..where((i) => i.id.equals(id))).getSingle();
        if (inv.isVoid) return;
        await (update(invoices)..where((i) => i.id.equals(id)))
            .write(InvoicesCompanion(isVoid: const Value(true), voidReason: Value(reason)));
        final moves = await (select(stockMoves)
              ..where((m) => m.refType.equals('sale') & m.refId.equals(id)))
            .get();
        for (final m in moves) {
          await into(stockMoves).insert(StockMovesCompanion.insert(
              productId: m.productId, qty: -m.qty, refType: 'void', refId: Value(id)));
        }
      });
}
