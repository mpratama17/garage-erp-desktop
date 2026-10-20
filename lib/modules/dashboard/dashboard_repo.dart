import 'package:drift/drift.dart';

import '../../db/database.dart';
import '../kas/kas_repo.dart' show Period, nextPeriod, periodOf;
import '../penjualan/penjualan_repo.dart';

/// Angka operasional untuk semua pengguna (tanpa modal/laba — itu lewat `report()` yang khusus owner).
class SalesPoint {
  SalesPoint(this.start, this.label);
  final DateTime start; // awal periode
  final String label;
  int omzet = 0, invoices = 0;
}

typedef TopItem = ({String name, int qty, int omzet});

extension DashboardRepo on AppDb {
  /// Omzet & jumlah invoice per [period] pada [from, to). Invoice tidak batal saja; titik kosong tetap
  /// terisi (0) supaya grafik tidak bolong.
  Future<List<SalesPoint>> salesSeries(DateTime from, DateTime to, {Period period = Period.daily}) async {
    final rows = await customSelect(
      // Omzet per invoice = baris − diskon invoice (tanpa PPN).
      'SELECT i.at, SUM(l.qty * l.price - l.discount) - i.discount AS total FROM invoices i '
      'JOIN invoice_lines l ON l.invoice_id = i.id '
      "WHERE i.kind = '${DocKind.invoice}' AND i.is_void = 0 AND i.at >= ? AND i.at < ? GROUP BY i.id",
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {invoices, invoiceLines},
    ).get();
    final points = <DateTime, SalesPoint>{};
    for (var d = periodOf(from, period).$1; d.isBefore(to); d = nextPeriod(d, period)) {
      points[d] = SalesPoint(d, periodOf(d, period).$2);
    }
    for (final r in rows) {
      final p = points[periodOf(r.read<DateTime>('at'), period).$1];
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
