import 'package:drift/drift.dart';

import '../core/format.dart';
import '../db/database.dart';

/// Hasil cari global (topbar): maks. [limit] per kelompok. Harga beli tidak pernah ikut.
class SearchResults {
  SearchResults(this.docs, this.customers, this.products);
  final List<({Invoice doc, String customer})> docs;
  final List<Customer> customers;
  final List<Product> products;
  bool get isEmpty => docs.isEmpty && customers.isEmpty && products.isEmpty;
}

extension SearchRepo on AppDb {
  Future<SearchResults> search(String query, {int limit = 5}) async {
    final q = query.trim();
    if (q.length < 2) return SearchResults([], [], []);
    String esc(String s) => s.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}'); // % dan _ = huruf biasa
    final like = '%${esc(q.toLowerCase())}%';
    Expression<bool> has(Expression<String> col) => col.lower().like(like, escapeChar: '\\');

    // No. HP disimpan polos 08…: cocokkan potongan angka ("4567") dan bentuk awalan ("+62 812", "0812-3456").
    Expression<bool> phoneHas(Expression<String> col) {
      if (!RegExp(r'^[\d\s+\-]+$').hasMatch(q)) return const Constant(false);
      final digits = q.replaceAll(RegExp(r'\D'), ''), norm = normalizePhone(q);
      if (digits.length < 4) return const Constant(false);
      return col.like('%$digits%') | col.like('%$norm%');
    }

    final docQ = select(invoices).join([leftOuterJoin(customers, customers.id.equalsExp(invoices.customerId))])
      ..where(
        has(invoices.no) | has(invoices.plate) | has(invoices.car) | has(customers.name) | phoneHas(customers.phone),
      )
      ..orderBy([OrderingTerm.desc(invoices.at), OrderingTerm.desc(invoices.id)])
      ..limit(limit);
    final custQ = select(customers)
      ..where((c) => has(c.name) | has(c.plate) | has(c.car) | phoneHas(c.phone))
      ..orderBy([(c) => OrderingTerm.asc(c.name)])
      ..limit(limit);
    final prodQ = select(products)
      ..where((p) => has(p.name) | has(p.sku) | has(p.category))
      ..orderBy([(p) => OrderingTerm.desc(p.active), (p) => OrderingTerm.asc(p.name)])
      ..limit(limit);

    return SearchResults(
      [
        for (final r in await docQ.get())
          (doc: r.readTable(invoices), customer: r.readTableOrNull(customers)?.name ?? 'UMUM'),
      ],
      await custQ.get(),
      await prodQ.get(),
    );
  }
}
