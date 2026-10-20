import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/xlsx.dart';
import '../../db/database.dart';
import '../kas/kas_repo.dart';
import 'laporan_repo.dart';

enum LapTab { labaRugi, penjualan, terlaris, arusKas }

enum LapRange { bulan, tahun }

class LaporanController extends GetxController {
  LaporanController(this.db);
  final AppDb db;

  final tab = LapTab.labaRugi.obs;
  final range = LapRange.bulan.obs;
  final anchor = DateTime(DateTime.now().year, DateTime.now().month).obs; // awal bulan / tahun yang dipilih

  final pl = Rxn<ProfitLoss>();
  final sales = Rxn<SalesReport>();
  final flow = <FlowRow>[].obs;
  final error = RxnString();
  String _loadedLabel = ''; // periode milik data yang sedang tampil (bisa tertinggal saat memuat)

  StreamSubscription<Object?>? _sub;
  var _seq = 0;

  @override
  void onInit() {
    super.onInit();
    _sub = db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            db.invoices,
            db.invoiceLines,
            db.cashEntries,
            db.expenseCategories,
            db.products,
          ]),
        )
        .listen((_) => _load());
    everAll([range, anchor], (_) => _load());
    _load();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// [dari, sampai) dan rinciannya: bulan → per hari, tahun → per bulan.
  (DateTime, DateTime, Period) get span {
    final a = anchor.value;
    return range.value == LapRange.bulan
        ? (DateTime(a.year, a.month), DateTime(a.year, a.month + 1), Period.daily)
        : (DateTime(a.year), DateTime(a.year + 1), Period.monthly);
  }

  String get spanLabel =>
      range.value == LapRange.bulan ? DateFormat('MMMM y', 'id').format(anchor.value) : '${anchor.value.year}';

  void shift(int delta) {
    final a = anchor.value;
    anchor.value = range.value == LapRange.bulan
        ? DateTime(a.year, a.month + delta)
        : DateTime(a.year + delta, a.month);
  }

  Future<void> _load() async {
    final seq = ++_seq;
    final (from, to, period) = span;
    final label = spanLabel;
    try {
      final (r, f) = await (db.report(from, to, period), db.cashFlow(from, to, period)).wait;
      if (seq != _seq) return; // hasil lama selesai belakangan
      pl.value = r.pl;
      sales.value = r.sales;
      flow.assignAll(f);
      _loadedLabel = label;
      error.value = null;
    } catch (e) {
      if (seq == _seq) error.value = e is ArgumentError ? '${e.message}' : 'Gagal memuat laporan: $e';
    }
  }

  /// Export tab yang sedang dibuka. Pesan untuk user, atau null bila dibatalkan.
  Future<String?> export() async {
    final p = pl.value, s = sales.value;
    if (p == null || s == null) return null;
    final label = _loadedLabel;
    final (String file, List<XlsxSheet> sheets) = switch (tab.value) {
      LapTab.labaRugi => (
        'laba-rugi',
        [
          (
            'Laba rugi',
            [
              'Periode',
              'Pendapatan',
              'HPP',
              'Laba kotor',
              'Biaya operasional',
              'Gaji',
              'Laba bersih usaha',
              'Pengeluaran pribadi',
              'Sisa',
            ],
            [
              for (final r in [...p.rows, p.total])
                [r.label, r.revenue, r.cogs, r.gross, r.expense, r.salary, r.net, r.personal, r.rest],
            ],
          ),
          (
            'Biaya per kategori',
            ['Kategori', 'Total'],
            [
              for (final e in p.expenseByCategory.entries) [e.key, e.value],
            ],
          ),
        ],
      ),
      LapTab.penjualan => (
        'penjualan',
        [
          (
            'Penjualan',
            ['Periode', 'Jumlah invoice', 'Penjualan bruto', 'Diskon', 'Omzet', 'PPN'],
            [
              for (final r in [...s.rows, s.total]) [r.label, r.invoices.length, r.gross, r.discount, r.omzet, r.tax],
            ],
          ),
          (
            'Per kategori',
            ['Kategori', 'Qty', 'Omzet'],
            [
              for (final c in s.byCategory) [c.name, c.qty, c.omzet],
            ],
          ),
        ],
      ),
      LapTab.terlaris => (
        'terlaris',
        [
          (
            'Terlaris',
            ['Peringkat', 'Nama', 'Kategori', 'Qty', 'Omzet'],
            [
              for (final (i, r) in s.byProduct.indexed) [i + 1, r.name, r.category, r.qty, r.omzet],
            ],
          ),
        ],
      ),
      LapTab.arusKas => (
        'arus-kas',
        [
          (
            'Arus kas',
            ['Periode', 'Pemasukan', 'Pengeluaran', 'Bersih'],
            [
              for (final f in flow) [f.label, f.income, f.expense, f.net],
              [
                'Total',
                flow.fold<int>(0, (t, f) => t + f.income),
                flow.fold<int>(0, (t, f) => t + f.expense),
                flow.fold<int>(0, (t, f) => t + f.net),
              ],
            ],
          ),
        ],
      ),
    };
    final path = await saveXlsx(db, buildXlsxSheets(sheets), '$file-${label.toLowerCase().replaceAll(' ', '-')}.xlsx');
    return path == null ? null : 'Export tersimpan';
  }
}
