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
    final like = '%${q.toLowerCase()}%';
    // No. HP disimpan polos 08…; "0812-3456" atau "+62 812" tetap ketemu.
    final phone = RegExp(r'^[\d\s+\-]+$').hasMatch(q) ? normalizePhone(q) : '';
    final phoneLike = phone.length >= 4 ? '%$phone%' : null;

    Expression<bool> has(Expression<String> col) => col.lower().like(like);

    final docQ = select(invoices).join([leftOuterJoin(customers, customers.id.equalsExp(invoices.customerId))])
      ..where(
        has(invoices.no) |
            has(invoices.plate) |
            has(invoices.car) |
            has(customers.name) |
            (phoneLike == null ? const Constant(false) : customers.phone.like(phoneLike)),
      )
      ..orderBy([OrderingTerm.desc(invoices.at), OrderingTerm.desc(invoices.id)])
      ..limit(limit);
    final custQ = select(customers)
      ..where(
        (c) =>
            has(c.name) |
            has(c.plate) |
            has(c.car) |
            (phoneLike == null ? const Constant(false) : c.phone.like(phoneLike)),
      )
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
