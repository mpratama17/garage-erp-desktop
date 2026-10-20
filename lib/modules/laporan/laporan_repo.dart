import 'package:drift/drift.dart';

import '../../db/database.dart';
import '../biaya/biaya_repo.dart';
import '../gaji/gaji_repo.dart';
import '../kas/kas_repo.dart';
import '../penjualan/penjualan_repo.dart';

/// Laba rugi satu periode (hari/bulan/tahun). Pendapatan & HPP menurut tanggal invoice;
/// biaya & gaji menurut tanggal uang keluar.
class PlRow {
  PlRow(this.start, this.label);
  final DateTime start;
  final String label;
  int revenue = 0, cogs = 0, expense = 0, salary = 0, personal = 0;

  int get gross => revenue - cogs;
  int get opex => expense + salary; // biaya operasional termasuk gaji
  int get net => gross - opex; // laba bersih usaha
  int get rest => net - personal; // sisa setelah pengeluaran pribadi

  void add(PlRow o) {
    revenue += o.revenue;
    cogs += o.cogs;
    expense += o.expense;
    salary += o.salary;
    personal += o.personal;
  }
}

class ProfitLoss {
  ProfitLoss(this.rows, this.total, this.missingCost, this.expenseByCategory);
  final List<PlRow> rows;
  final PlRow total;
  final int missingCost; // baris barang yang modalnya belum diisi owner (dihitung 0)
  final Map<String, int> expenseByCategory; // operasional & pribadi, nama kategori → total
}

class SalesRow {
  SalesRow(this.start, this.label);
  final DateTime start;
  final String label;
  final invoices = <int>{};
  int gross = 0, discount = 0, tax = 0; // diskon = per baris + per invoice; PPN bukan omzet
  int get omzet => gross - discount;
}

class ItemRow {
  ItemRow(this.name, this.category);
  final String name, category;
  int qty = 0, omzet = 0;
}

class SalesReport {
  SalesReport(this.rows, this.total, this.byCategory, this.byProduct);
  final List<SalesRow> rows;
  final SalesRow total;
  final List<ItemRow> byCategory; // name = kategori
  final List<ItemRow> byProduct; // terlaris: qty terbanyak dulu
}

typedef _Line = ({Invoice doc, InvoiceLine line, Product product});

// ponytail: agregasi di Dart atas semua baris periode; cukup untuk 1 bengkel. Pindah ke GROUP BY bila lambat.
extension LaporanRepo on AppDb {
  /// Baris invoice yang dihitung pendapatan: invoice (bukan pemesanan), tidak batal, pada [from, to).
  Future<List<_Line>> _saleLines(DateTime from, DateTime to) async {
    final q =
        select(invoiceLines).join([
          innerJoin(invoices, invoices.id.equalsExp(invoiceLines.invoiceId)),
          innerJoin(products, products.id.equalsExp(invoiceLines.productId)),
        ])..where(
          invoices.kind.equals(DocKind.invoice) &
              invoices.isVoid.equals(false) &
              invoices.at.isBiggerOrEqualValue(from) &
              invoices.at.isSmallerThanValue(to),
        );
    return [
      for (final r in await q.get())
        (doc: r.readTable(invoices), line: r.readTable(invoiceLines), product: r.readTable(products)),
    ];
  }

  /// Laba rugi + penjualan untuk [from, to), dirinci per [period]. Khusus owner (berisi modal & laba).
  Future<({ProfitLoss pl, SalesReport sales})> report(DateTime from, DateTime to, Period period) async {
    requireOwner();
    final lines = await _saleLines(from, to);
    return (pl: await _profitLoss(lines, from, to, period), sales: _sales(lines, from, period));
  }

  Future<ProfitLoss> _profitLoss(List<_Line> lines, DateTime from, DateTime to, Period period) async {
    final byStart = <DateTime, PlRow>{};
    PlRow row(DateTime at) {
      final (start, label) = periodOf(at, period);
      return byStart.putIfAbsent(start, () => PlRow(start, label));
    }

    var missing = 0;
    final seen = <int>{};
    for (final l in lines) {
      final r = row(l.doc.at);
      r.revenue += l.line.qty * l.line.price - l.line.discount;
      if (seen.add(l.doc.id)) r.revenue -= l.doc.discount; // diskon invoice dihitung sekali per invoice
      r.cogs += l.line.qty * (l.line.cost ?? 0);
      if (l.line.cost == null && !l.product.isService) missing++;
    }

    final byCategory = <String, int>{};
    final q =
        select(cashEntries).join([leftOuterJoin(expenseCategories, expenseCategories.id.equalsExp(cashEntries.refId))])
          ..where(
            cashEntries.kind.isIn([expenseKind, salaryKind]) &
                cashEntries.at.isBiggerOrEqualValue(from) &
                cashEntries.at.isSmallerThanValue(to),
          );
    for (final x in await q.get()) {
      final e = x.readTable(cashEntries);
      final r = row(e.at);
      final amount = -e.amount;
      if (e.kind == salaryKind) {
        r.salary += amount;
        continue;
      }
      final cat = e.kind == expenseKind ? x.readTableOrNull(expenseCategories) : null;
      if (cat?.personal ?? false) {
        r.personal += amount;
      } else {
        r.expense += amount;
      }
      final name = cat?.name ?? 'Tanpa kategori';
      byCategory[name] = (byCategory[name] ?? 0) + amount;
    }

    final rows = byStart.values.toList()..sort((a, b) => a.start.compareTo(b.start));
    final total = PlRow(from, 'Total');
    for (final r in rows) {
      total.add(r);
    }
    return ProfitLoss(rows, total, missing, byCategory);
  }

  SalesReport _sales(List<_Line> lines, DateTime from, Period period) {
    final byStart = <DateTime, SalesRow>{}, byCat = <String, ItemRow>{}, byProduct = <int, ItemRow>{};
    final total = SalesRow(from, 'Total');
    for (final l in lines) {
      final (start, label) = periodOf(l.doc.at, period);
      final gross = l.line.qty * l.line.price, omzet = gross - l.line.discount;
      for (final r in [byStart.putIfAbsent(start, () => SalesRow(start, label)), total]) {
        if (r.invoices.add(l.doc.id)) {
          r.discount += l.doc.discount;
          r.tax += l.doc.tax;
        }
        r.gross += gross;
        r.discount += l.line.discount;
      }
      // ponytail: per kategori/produk memakai omzet baris (diskon invoice tidak dibagi ke baris);
      // total di tab Penjualan tetap tepat. Bagi proporsional bila owner butuh margin per produk.
      final category = l.product.category.isEmpty ? 'Tanpa kategori' : l.product.category;
      for (final i in [
        byCat.putIfAbsent(category, () => ItemRow(category, '')),
        byProduct.putIfAbsent(l.product.id, () => ItemRow(l.product.name, category)),
      ]) {
        i.qty += l.line.qty;
        i.omzet += omzet;
      }
    }
    return SalesReport(
      byStart.values.toList()..sort((a, b) => a.start.compareTo(b.start)),
      total,
      byCat.values.toList()..sort((a, b) => b.omzet != a.omzet ? b.omzet.compareTo(a.omzet) : a.name.compareTo(b.name)),
      byProduct.values.toList()..sort((a, b) => b.qty != a.qty ? b.qty.compareTo(a.qty) : b.omzet.compareTo(a.omzet)),
    );
  }
}
