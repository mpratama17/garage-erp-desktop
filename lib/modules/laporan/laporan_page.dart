import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format.dart';
import '../../core/table.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import '../kas/kas_repo.dart';
import 'laporan_controller.dart';
import 'laporan_repo.dart';
import 'report_data.dart';
import '../../core/range_picker.dart';

/// Laporan — khusus owner (berisi laba & modal).
class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  @override
  Widget build(BuildContext context) =>
      OwnerGate(message: 'Laporan hanya untuk owner.', builder: (_) => const _Laporan());
}

/// Controller hidup selama halaman terbuka & owner terbuka; dihapus saat pindah halaman atau terkunci.
class _Laporan extends StatefulWidget {
  const _Laporan();

  @override
  State<_Laporan> createState() => _LaporanState();
}

class _LaporanState extends State<_Laporan> {
  final c = Get.put(LaporanController(Get.find<AppDb>()));

  @override
  void dispose() {
    Get.delete<LaporanController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Laporan',
          subtitle: 'Keuangan, akuntansi, penjualan, pembelian.',
          actions: [
            OutlinedButton.icon(
              onPressed: () async {
                final msg = await c.export();
                if (msg != null && context.mounted) notify(context, msg);
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Export Excel'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.lg),
          child: Obx(() {
            final r = c.report.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<LapGroup>(
                  showSelectedIcon: false,
                  segments: [for (final g in LapGroup.values) ButtonSegment(value: g, label: Text(g.label))],
                  selected: {r.group},
                  onSelectionChanged: (g) => c.select(LapReport.values.firstWhere((x) => x.group == g.first)),
                ),
                const SizedBox(height: S.md),
                Wrap(
                  spacing: S.sm,
                  runSpacing: S.sm,
                  children: [
                    for (final x in LapReport.values.where((x) => x.group == r.group))
                      ChoiceChip(label: Text(x.label), selected: x == r, onSelected: (_) => c.select(x)),
                  ],
                ),
                const SizedBox(height: S.md),
                _Params(c),
              ],
            );
          }),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xl),
            child: Obx(() {
              if (c.report.value.param != LapParam.legacy) return _ReportView(c);
              final pl = c.pl.value, s = c.sales.value;
              if (c.error.value != null) return EmptyState(message: c.error.value!);
              if (pl == null || s == null) return const Center(child: CircularProgressIndicator());
              final unit = c.range.value == LapRange.bulan ? 'hari' : 'bulan';
              return switch (c.report.value) {
                LapReport.labaRugi => _LabaRugi(pl, unit),
                LapReport.penjualanRingkas => _Penjualan(s, unit),
                LapReport.terlaris => _terlaris(s),
                _ => _arus(c.flow.toList(), unit), // LapReport.arusKas
              };
            }),
          ),
        ),
      ],
    );
    // Jendela pendek: seluruh halaman bisa digulir, tabel tidak terjepit.
    return LayoutBuilder(
      builder: (context, box) =>
          box.maxHeight < 860 ? SingleChildScrollView(child: SizedBox(height: 860, child: page)) : page,
    );
  }

  Widget _terlaris(SalesReport s) {
    final rank = {for (final (i, r) in s.byProduct.indexed) r: i + 1};
    return AppTable<ItemRow>(
      rows: s.byProduct,
      searchHint: 'Cari produk…',
      searchText: (r) => '${r.name} ${r.category}',
      emptyMessage: 'Belum ada penjualan di periode ini.',
      columns: [
        Col('#', (r) => Text('${rank[r]}', style: T.label), flex: 1, sort: (r) => rank[r]),
        Col('Nama', (r) => Text(r.name), flex: 6, sort: (r) => r.name),
        Col('Kategori', (r) => Text(r.category), flex: 3, sort: (r) => r.category),
        Col('Qty', (r) => Text('${r.qty}', style: T.money), flex: 2, numeric: true, sort: (r) => r.qty),
        Col('Omzet', (r) => Text(rp(r.omzet), style: T.money), flex: 3, numeric: true, sort: (r) => r.omzet),
      ],
    );
  }

  Widget _arus(List<FlowRow> rows, String unit) => AppTable<FlowRow>(
    rows: rows,
    searchText: (r) => r.label,
    emptyMessage: 'Belum ada uang masuk/keluar di periode ini.',
    toolbar: [
      Text(
        'Pemasukan ${rp(rows.fold(0, (t, r) => t + r.income))} · '
        'Pengeluaran ${rp(rows.fold(0, (t, r) => t + r.expense))} · Transfer antar rekening tidak dihitung',
        style: T.label,
      ),
    ],
    columns: [
      Col('Per $unit', (r) => Text(r.label), flex: 3),
      Col('Pemasukan', (r) => Text(rp(r.income), style: T.money), flex: 3, numeric: true, sort: (r) => r.income),
      Col('Pengeluaran', (r) => Text(rp(r.expense), style: T.money), flex: 3, numeric: true, sort: (r) => r.expense),
      Col(
        'Bersih',
        (r) => Text(rp(r.net), style: T.money.copyWith(color: r.net < 0 ? C.danger : null)),
        flex: 3,
        numeric: true,
        sort: (r) => r.net,
      ),
    ],
  );
}

Widget _card({required Widget child}) => Container(
  padding: const EdgeInsets.all(S.lg),
  decoration: BoxDecoration(
    color: C.surface,
    borderRadius: BorderRadius.circular(S.rCard),
    border: Border.all(color: C.border),
  ),
  child: child,
);

Widget _line(String label, int value, {bool strong = false, bool minus = false, String? hint}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: Row(
    children: [
      Expanded(
        child: Text.rich(
          TextSpan(
            text: label,
            style: strong ? T.section : null,
            children: [if (hint != null) TextSpan(text: '  $hint', style: T.label)],
          ),
        ),
      ),
      Text(
        minus && value != 0 ? '(${rp(value)})' : rp(value),
        style: T.money.copyWith(
          fontWeight: strong ? FontWeight.w700 : null,
          color: strong && value < 0 ? C.danger : null,
        ),
      ),
    ],
  ),
);

class _LabaRugi extends StatelessWidget {
  const _LabaRugi(this.pl, this.unit);
  final ProfitLoss pl;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = pl.total;
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _line('Pendapatan', t.revenue, hint: 'invoice, setelah diskon'),
              _line('HPP (modal barang terjual)', t.cogs, minus: true),
              const Divider(),
              _line('Laba kotor', t.gross, strong: true),
              _line('Biaya operasional', t.expense, minus: true),
              _line('Gaji', t.salary, minus: true),
              const Divider(),
              _line('Laba bersih usaha', t.net, strong: true),
              _line('Pengeluaran pribadi', t.personal, minus: true),
              const Divider(),
              _line('Sisa', t.rest, strong: true),
            ],
          ),
        ),
        if (pl.missingCost > 0) ...[
          const SizedBox(height: S.md),
          Container(
            padding: const EdgeInsets.all(S.md),
            decoration: BoxDecoration(color: Tone.warning.bg, borderRadius: BorderRadius.circular(S.rInput)),
            child: Text(
              '${pl.missingCost} baris barang belum diisi modalnya (dihitung 0) — HPP lebih kecil dan laba '
              'terlihat lebih besar. Isi modal di detail invoice.',
              style: T.label.copyWith(color: Tone.warning.fg),
            ),
          ),
        ],
        if (pl.expenseByCategory.isNotEmpty) ...[
          const SizedBox(height: S.md),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Biaya per kategori', style: T.section),
                const SizedBox(height: S.sm),
                for (final e in pl.expenseByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                  _line(e.key, e.value),
              ],
            ),
          ),
        ],
        const SizedBox(height: S.md),
        Text(
          'Pembelian stok tidak dihitung biaya — masuk HPP saat barangnya terjual. '
          'DP pemesanan belum dihitung pendapatan sampai dibuatkan invoice.',
          style: T.label,
        ),
      ],
    );
    final table = AppTable<PlRow>(
      rows: pl.rows,
      searchText: (r) => r.label,
      emptyMessage: 'Belum ada transaksi di periode ini.',
      columns: [
        Col('Per $unit', (r) => Text(r.label), flex: 3),
        Col('Pendapatan', (r) => Text(rp(r.revenue), style: T.money), flex: 3, numeric: true, sort: (r) => r.revenue),
        Col('Laba kotor', (r) => Text(rp(r.gross), style: T.money), flex: 3, numeric: true, sort: (r) => r.gross),
        Col('Biaya + gaji', (r) => Text(rp(r.opex), style: T.money), flex: 3, numeric: true, sort: (r) => r.opex),
        Col(
          'Laba bersih',
          (r) => Text(rp(r.net), style: T.money.copyWith(color: r.net < 0 ? C.danger : null)),
          flex: 3,
          numeric: true,
          sort: (r) => r.net,
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < 900
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summary,
                  const SizedBox(height: S.lg),
                  SizedBox(height: 420, child: table),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 400, child: SingleChildScrollView(child: summary)),
                const SizedBox(width: S.lg),
                Expanded(child: table),
              ],
            ),
    );
  }
}

class _Penjualan extends StatelessWidget {
  const _Penjualan(this.s, this.unit);
  final SalesReport s;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final byPeriod = AppTable<SalesRow>(
      rows: s.rows,
      searchText: (r) => r.label,
      emptyMessage: 'Belum ada penjualan di periode ini.',
      toolbar: [
        Text(
          '${s.total.invoices.length} invoice · Diskon ${rp(s.total.discount)} · Omzet ${rp(s.total.omzet)}',
          style: T.label,
        ),
      ],
      columns: [
        Col('Per $unit', (r) => Text(r.label), flex: 3),
        Col(
          'Invoice',
          (r) => Text('${r.invoices.length}', style: T.money),
          flex: 2,
          numeric: true,
          sort: (r) => r.invoices.length,
        ),
        Col('Bruto', (r) => Text(rp(r.gross), style: T.money), flex: 3, numeric: true, sort: (r) => r.gross),
        Col('Diskon', (r) => Text(rp(r.discount), style: T.money), flex: 3, numeric: true, sort: (r) => r.discount),
        Col('Omzet', (r) => Text(rp(r.omzet), style: T.money), flex: 3, numeric: true, sort: (r) => r.omzet),
        Col('PPN', (r) => Text(rp(r.tax), style: T.money), flex: 2, numeric: true, sort: (r) => r.tax),
      ],
    );
    final byCategory = AppTable<ItemRow>(
      rows: s.byCategory,
      searchHint: 'Cari kategori…',
      searchText: (r) => r.name,
      emptyMessage: 'Belum ada penjualan.',
      columns: [
        Col('Kategori', (r) => Text(r.name), flex: 4, sort: (r) => r.name),
        Col('Qty', (r) => Text('${r.qty}', style: T.money), flex: 2, numeric: true, sort: (r) => r.qty),
        Col('Omzet', (r) => Text(rp(r.omzet), style: T.money), flex: 3, numeric: true, sort: (r) => r.omzet),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < 900
          ? SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 420, child: byPeriod),
                  const SizedBox(height: S.lg),
                  SizedBox(height: 360, child: byCategory),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: byPeriod),
                const SizedBox(width: S.lg),
                Expanded(flex: 2, child: byCategory),
              ],
            ),
    );
  }
}

/// Parameter laporan terpilih: periode/tanggal/akun/jenis, atau navigasi bulan-tahun untuk laporan lama.
class _Params extends StatelessWidget {
  const _Params(this.c);
  final LaporanController c;

  @override
  Widget build(BuildContext context) {
    final r = c.report.value;
    switch (r.param) {
      case LapParam.legacy:
        return Wrap(
          spacing: S.lg,
          runSpacing: S.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<LapRange>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: LapRange.bulan, label: Text('Bulanan')),
                ButtonSegment(value: LapRange.tahun, label: Text('Tahunan')),
              ],
              selected: {c.range.value},
              onSelectionChanged: (s) => c.range.value = s.first,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(tooltip: 'Sebelumnya', onPressed: () => c.shift(-1), icon: const Icon(Icons.chevron_left)),
                SizedBox(
                  width: 150,
                  child: Text(c.spanLabel, textAlign: TextAlign.center, style: T.section),
                ),
                IconButton(tooltip: 'Berikutnya', onPressed: () => c.shift(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ],
        );
      case LapParam.range:
        return Wrap(
          spacing: S.md,
          runSpacing: S.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RangeButton(range: c.period.value, onChanged: (v) => c.period.value = v!),
            if (r == LapReport.bukuBesar)
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: c.accountCode.value,
                  items: [for (final a in c.coa) DropdownMenuItem(value: a.code, child: Text('${a.code}  ${a.name}'))],
                  onChanged: (v) => v == null ? null : c.accountCode.value = v,
                ),
              ),
          ],
        );
      case LapParam.asOf:
        return OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: c.asOf.value,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 366)),
            );
            if (d != null) c.asOf.value = d;
          },
          icon: const Icon(Icons.event_outlined, size: 18),
          label: Text('Per tanggal ${tgl(c.asOf.value)}'),
        );
      case LapParam.none:
        return r == LapReport.bukuBesarPembantu
            ? SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'piutang', label: Text('Piutang (customer)')),
                  ButtonSegment(value: 'utang', label: Text('Utang (vendor)')),
                  ButtonSegment(value: 'persediaan', label: Text('Persediaan (produk)')),
                ],
                selected: {c.subledger.value},
                onSelectionChanged: (s) => c.subledger.value = s.first,
              )
            : const SizedBox.shrink();
    }
  }
}

/// Tabel laporan generik dari [ReportData]: kolom angka rata kanan, baris tebal untuk subjudul/total (tetap di akhir saat diurutkan).
class _ReportView extends StatelessWidget {
  const _ReportView(this.c);
  final LaporanController c;

  @override
  Widget build(BuildContext context) => Obx(() => _build());

  Widget _build() {
    final d = c.data.value;
    if (c.dataError.value != null) return EmptyState(message: c.dataError.value!);
    if (d == null) return const Center(child: CircularProgressIndicator());
    bool numericCol(int i) => d.rows.any((r) => r.cells[i] is int);
    String show(Object? v, int i) => v == null ? '' : (v is int ? (d.countCols.contains(i) ? '$v' : rp(v)) : '$v');
    final sortable = c.report.value.sortable;
    // Angka menurut nilainya, tanggal "dd/MM/yyyy" menurut kalender (bukan abjad), kosong → di akhir.
    final date = RegExp(r'^(\d\d)/(\d\d)/(\d{4})$');
    Object? sortKey(Object? v) {
      if (v is int) return v;
      if (v == null || v == '') return null;
      final m = date.firstMatch('$v');
      return m == null ? v : '${m[3]}${m[2]}${m[1]}';
    }

    const wide = {'Keterangan', 'Barang / jasa', 'Akun', 'Barang', 'Indikator', 'Customer', 'Vendor'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AppTable<RRow>(
            key: ValueKey(c.report.value), // ganti laporan = cari & urutan mulai bersih
            rows: d.rows,
            searchHint: 'Cari di ${d.title.toLowerCase()}…',
            searchText: (r) => [for (final (i, v) in r.cells.indexed) show(v, i)].join(' '),
            emptyMessage: 'Tidak ada data pada periode ini.',
            toolbar: [Text(d.title, style: T.section)],
            pinned: sortable ? (r) => r.bold : null,
            columns: [
              for (final (i, h) in d.headers.indexed)
                Col<RRow>(
                  h,
                  (r) {
                    final v = r.cells[i];
                    return Text(
                      show(v, i),
                      style: (v is int ? T.money : T.body).copyWith(
                        fontWeight: r.bold ? FontWeight.w700 : null,
                        color: v is int && v < 0 && !d.countCols.contains(i) ? C.danger : null,
                      ),
                    );
                  },
                  flex: wide.contains(h) ? 5 : (numericCol(i) ? 2 : 3),
                  numeric: numericCol(i),
                  sort: sortable ? (r) => sortKey(r.cells[i]) : null,
                ),
            ],
          ),
        ),
        for (final n in d.notes)
          Padding(
            padding: const EdgeInsets.only(top: S.sm),
            child: Text(n, style: T.label.copyWith(color: n.startsWith('PERHATIAN') ? C.danger : null)),
          ),
      ],
    );
  }
}
