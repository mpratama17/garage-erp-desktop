import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;

import '../../core/range_picker.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/xlsx.dart';
import '../../db/database.dart';
import '../kas/kas_repo.dart';
import 'akuntansi_repo.dart' show Ac, AkuntansiRepo, Coa;
import 'akuntansi_reports.dart';
import 'laporan_repo.dart';
import 'report_data.dart';

enum LapGroup {
  keuangan('Keuangan'),
  akuntansi('Akuntansi'),
  penjualan('Penjualan'),
  pembelian('Pembelian');

  const LapGroup(this.label);
  final String label;
}

/// Parameter yang dibutuhkan sebuah laporan: [legacy] = laporan lama (navigasi bulan/tahun), selebihnya laporan baru.
enum LapParam { none, range, asOf, legacy }

enum LapReport {
  neraca(LapGroup.keuangan, 'Neraca', LapParam.asOf),
  arusKas(LapGroup.keuangan, 'Arus kas', LapParam.legacy),
  proyeksi(LapGroup.keuangan, 'Proyeksi arus kas', LapParam.none),
  labaRugi(LapGroup.keuangan, 'Laba rugi', LapParam.legacy),
  perubahanModal(LapGroup.keuangan, 'Perubahan modal', LapParam.range),
  ringkasan(LapGroup.keuangan, 'Ringkasan eksekutif', LapParam.range),
  ringkasanBank(LapGroup.akuntansi, 'Ringkasan bank', LapParam.range),
  bukuBesar(LapGroup.akuntansi, 'Buku besar', LapParam.range),
  bukuBesarPembantu(LapGroup.akuntansi, 'Buku besar pembantu', LapParam.none),
  jurnal(LapGroup.akuntansi, 'Jurnal', LapParam.range),
  trialBalance(LapGroup.akuntansi, 'Trial balance', LapParam.asOf),
  penjualanRingkas(LapGroup.penjualan, 'Ringkasan', LapParam.legacy),
  terlaris(LapGroup.penjualan, 'Terlaris', LapParam.legacy),
  penjualanDetail(LapGroup.penjualan, 'Detail penjualan', LapParam.range),
  pembelianDetail(LapGroup.pembelian, 'Detail pembelian', LapParam.range);

  const LapReport(this.group, this.label, this.param);
  final LapGroup group;
  final String label;
  final LapParam param;

  /// Tabel boleh diurutkan per kolom: hanya laporan berbentuk daftar. Laporan berstruktur (neraca, jurnal berkelompok,
  /// buku besar bersaldo berjalan, dst.) urutannya bagian dari artinya, jadi tidak diurutkan.
  bool get sortable => switch (this) {
    ringkasanBank || bukuBesarPembantu || trialBalance || penjualanDetail || pembelianDetail => true,
    _ => false,
  };
}

enum LapRange { bulan, tahun }

class LaporanController extends GetxController {
  LaporanController(this.db);
  final AppDb db;

  // Laporan baru (neraca, akuntansi, detail…): satu laporan terpilih → [data].
  final report = LapReport.neraca.obs;
  final period = thisMonth().obs;
  final asOf = DateTime.now().obs;
  final accountCode = Ac.piutang.obs; // buku besar
  final subledger = 'piutang'.obs; // buku besar pembantu: piutang | utang | persediaan
  final coa = <Coa>[].obs; // pilihan akun buku besar (dimuat saat laporan itu dibuka)
  final data = Rxn<ReportData>();
  final dataError = RxnString();
  var _dataSeq = 0;
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
            db.purchases,
            db.stockMoves,
            db.accounts,
          ]),
        )
        .listen((_) => _reload());
    ever(report, (_) => _reload());
    everAll([range, anchor], (_) => _load());
    everAll([period, asOf, accountCode, subledger], (_) => _loadData());
    _reload();
  }

  /// Muat ulang hanya jenis laporan yang sedang tampil (lama: bulan/tahun; baru: [data]).
  void _reload() => report.value.param == LapParam.legacy ? _load() : _loadData();

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void select(LapReport r) {
    report.value = r;
    if (r == LapReport.bukuBesar && coa.isEmpty) db.chartOfAccounts().then(coa.assignAll);
  }

  Future<void> _loadData() async {
    final r = report.value;
    final seq = ++_dataSeq;
    final p = period.value;
    try {
      final d = await switch (r) {
        LapReport.neraca => db.neraca(asOf.value),
        LapReport.proyeksi => db.proyeksiArusKas(),
        LapReport.perubahanModal => db.perubahanModal(p.start, p.end),
        LapReport.ringkasan => db.ringkasanEksekutif(p.start, p.end),
        LapReport.ringkasanBank => db.ringkasanBank(p.start, p.end),
        LapReport.bukuBesar => db.bukuBesar(accountCode.value, p.start, p.end),
        LapReport.bukuBesarPembantu => db.bukuBesarPembantu(subledger.value),
        LapReport.jurnal => db.jurnalUmum(p.start, p.end),
        LapReport.trialBalance => db.trialBalance(asOf.value),
        LapReport.penjualanDetail => db.detailPenjualan(p.start, p.end),
        LapReport.pembelianDetail => db.detailPembelian(p.start, p.end),
        _ => Future<ReportData?>.value(),
      };
      if (seq != _dataSeq) return;
      data.value = d;
      dataError.value = null;
    } catch (e) {
      if (seq == _dataSeq) dataError.value = e is ArgumentError ? '${e.message}' : 'Gagal memuat laporan: $e';
    }
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
    if (report.value.param != LapParam.legacy) {
      final d = data.value;
      if (d == null) return null;
      final name = report.value.label.toLowerCase().replaceAll(' ', '-');
      final path = await saveXlsx(
        db,
        buildXlsx(report.value.label, d.headers, [for (final r in d.rows) r.cells]),
        '$name.xlsx',
      );
      return path == null ? null : 'Export tersimpan';
    }
    final p = pl.value, s = sales.value;
    if (p == null || s == null) return null;
    final label = _loadedLabel;
    final (String file, List<XlsxSheet> sheets) = switch (report.value) {
      LapReport.labaRugi => (
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
      LapReport.penjualanRingkas => (
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
      LapReport.terlaris => (
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
      _ => (
        // LapReport.arusKas
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
