import 'package:drift/drift.dart';

import '../../db/database.dart';
import '../penjualan/penjualan_repo.dart';

/// Angka operasional untuk semua pengguna (tanpa modal/laba — itu lewat `report()` yang khusus owner).
class SalesPoint {
  SalesPoint(this.start);
  final DateTime start; // awal hari/bulan
  int omzet = 0, invoices = 0;
}

typedef TopItem = ({String name, int qty, int omzet});

extension DashboardRepo on AppDb {
  /// Omzet & jumlah invoice per hari ([monthly] = per bulan) pada [from, to). Invoice tidak batal saja.
  Future<List<SalesPoint>> salesSeries(DateTime from, DateTime to, {bool monthly = false}) async {
    final rows = await customSelect(
      // Omzet per invoice = baris − diskon invoice (tanpa PPN).
      'SELECT i.at, SUM(l.qty * l.price - l.discount) - i.discount AS total FROM invoices i '
      'JOIN invoice_lines l ON l.invoice_id = i.id '
      "WHERE i.kind = '${DocKind.invoice}' AND i.is_void = 0 AND i.at >= ? AND i.at < ? GROUP BY i.id",
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {invoices, invoiceLines},
    ).get();
    DateTime key(DateTime d) => monthly ? DateTime(d.year, d.month) : DateTime(d.year, d.month, d.day);
    // Semua titik terisi (termasuk yang 0) supaya grafik tidak bolong.
    final points = <DateTime, SalesPoint>{};
    for (
      var d = key(from);
      d.isBefore(to);
      d = monthly ? DateTime(d.year, d.month + 1) : DateTime(d.year, d.month, d.day + 1)
    ) {
      points[d] = SalesPoint(d);
    }
    for (final r in rows) {
      final p = points[key(r.read<DateTime>('at'))];
      if (p == null) continue;
      p.omzet += r.read<int>('total');
      p.invoices++;
    }
    return points.values.toList();
  }

  /// Produk/jasa paling banyak terjual (qty) pada [from, to).
  Future<List<TopItem>> topItems(DateTime from, DateTime to, {int limit = 5}) async {
    final rows = await customSelect(
      'SELECT p.name, SUM(l.qty) AS qty, SUM(l.qty * l.price - l.discount) AS omzet FROM invoice_lines l '
      'JOIN invoices i ON i.id = l.invoice_id JOIN products p ON p.id = l.product_id '
      "WHERE i.kind = '${DocKind.invoice}' AND i.is_void = 0 AND i.at >= ? AND i.at < ? "
      'GROUP BY p.id ORDER BY qty DESC, omzet DESC LIMIT ?',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to), Variable(limit)],
      readsFrom: {invoices, invoiceLines, products},
    ).get();
    return [for (final r in rows) (name: r.read<String>('name'), qty: r.read<int>('qty'), omzet: r.read<int>('omzet'))];
  }
}
