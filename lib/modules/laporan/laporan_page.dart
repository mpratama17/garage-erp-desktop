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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Laporan',
          subtitle: 'Laba rugi, penjualan, terlaris, arus kas.',
          actions: [
            OutlinedButton(
              onPressed: () async {
                final msg = await c.export();
                if (msg != null && context.mounted) toast(context, msg);
              },
              child: const Text('Export Excel'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.lg),
          child: Obx(
            () => Row(
              children: [
                SegmentedButton<LapTab>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: LapTab.labaRugi, label: Text('Laba rugi')),
                    ButtonSegment(value: LapTab.penjualan, label: Text('Penjualan')),
                    ButtonSegment(value: LapTab.terlaris, label: Text('Terlaris')),
                    ButtonSegment(value: LapTab.arusKas, label: Text('Arus kas')),
                  ],
                  selected: {c.tab.value},
                  onSelectionChanged: (s) => c.tab.value = s.first,
                ),
                const Spacer(),
                SegmentedButton<LapRange>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: LapRange.bulan, label: Text('Bulanan')),
                    ButtonSegment(value: LapRange.tahun, label: Text('Tahunan')),
                  ],
                  selected: {c.range.value},
                  onSelectionChanged: (s) => c.range.value = s.first,
                ),
                const SizedBox(width: S.md),
                IconButton(tooltip: 'Sebelumnya', onPressed: () => c.shift(-1), icon: const Icon(Icons.chevron_left)),
                SizedBox(
                  width: 150,
                  child: Text(c.spanLabel, textAlign: TextAlign.center, style: T.section),
                ),
                IconButton(tooltip: 'Berikutnya', onPressed: () => c.shift(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xl),
            child: Obx(() {
              final pl = c.pl.value, s = c.sales.value;
              if (c.error.value != null) return EmptyState(message: c.error.value!);
              if (pl == null || s == null) return const Center(child: CircularProgressIndicator());
              final unit = c.range.value == LapRange.bulan ? 'hari' : 'bulan';
              return switch (c.tab.value) {
                LapTab.labaRugi => _LabaRugi(pl, unit),
                LapTab.penjualan => _Penjualan(s, unit),
                LapTab.terlaris => _terlaris(s),
                LapTab.arusKas => _arus(c.flow.toList(), unit),
              };
            }),
          ),
        ),
      ],
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
        Col('#', (r) => Text('${rank[r]}', style: T.label), flex: 1),
        Col('Nama', (r) => Text(r.name), flex: 6),
        Col('Kategori', (r) => Text(r.category), flex: 3),
        Col('Qty', (r) => Text('${r.qty}', style: T.money), flex: 2, numeric: true),
        Col('Omzet', (r) => Text(rp(r.omzet), style: T.money), flex: 3, numeric: true),
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
      Col('Pemasukan', (r) => Text(rp(r.income), style: T.money), flex: 3, numeric: true),
      Col('Pengeluaran', (r) => Text(rp(r.expense), style: T.money), flex: 3, numeric: true),
      Col(
        'Bersih',
        (r) => Text(rp(r.net), style: T.money.copyWith(color: r.net < 0 ? C.danger : null)),
        flex: 3,
        numeric: true,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
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
                        for (final e
                            in pl.expenseByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
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
            ),
          ),
        ),
        const SizedBox(width: S.lg),
        Expanded(
          child: AppTable<PlRow>(
            rows: pl.rows,
            searchText: (r) => r.label,
            emptyMessage: 'Belum ada transaksi di periode ini.',
            columns: [
              Col('Per $unit', (r) => Text(r.label), flex: 3),
              Col('Pendapatan', (r) => Text(rp(r.revenue), style: T.money), flex: 3, numeric: true),
              Col('Laba kotor', (r) => Text(rp(r.gross), style: T.money), flex: 3, numeric: true),
              Col('Biaya + gaji', (r) => Text(rp(r.opex), style: T.money), flex: 3, numeric: true),
              Col(
                'Laba bersih',
                (r) => Text(rp(r.net), style: T.money.copyWith(color: r.net < 0 ? C.danger : null)),
                flex: 3,
                numeric: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Penjualan extends StatelessWidget {
  const _Penjualan(this.s, this.unit);
  final SalesReport s;
  final String unit;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 3,
        child: AppTable<SalesRow>(
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
            Col('Invoice', (r) => Text('${r.invoices.length}', style: T.money), flex: 2, numeric: true),
            Col('Bruto', (r) => Text(rp(r.gross), style: T.money), flex: 3, numeric: true),
            Col('Diskon', (r) => Text(rp(r.discount), style: T.money), flex: 3, numeric: true),
            Col('Omzet', (r) => Text(rp(r.omzet), style: T.money), flex: 3, numeric: true),
          ],
        ),
      ),
      const SizedBox(width: S.lg),
      Expanded(
        flex: 2,
        child: AppTable<ItemRow>(
          rows: s.byCategory,
          searchHint: 'Cari kategori…',
          searchText: (r) => r.name,
          emptyMessage: 'Belum ada penjualan.',
          columns: [
            Col('Kategori', (r) => Text(r.name), flex: 4),
            Col('Qty', (r) => Text('${r.qty}', style: T.money), flex: 2, numeric: true),
            Col('Omzet', (r) => Text(rp(r.omzet), style: T.money), flex: 3, numeric: true),
          ],
        ),
      ),
    ],
  );
}
