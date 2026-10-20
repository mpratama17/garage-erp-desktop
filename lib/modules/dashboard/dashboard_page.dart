import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../kas/kas_repo.dart' show Period;

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import '../../shell.dart';
import '../penjualan/penjualan_page.dart';
import 'dashboard_controller.dart';

/// Beranda: ringkasan untuk semua pengguna; laba & saldo hanya terlihat owner (••••).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final c = Get.put(DashboardController(Get.find<AppDb>()));

  @override
  void dispose() {
    Get.delete<DashboardController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const PageHeader(title: 'Dashboard', subtitle: 'Ringkasan bengkel bulan ini.'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xl),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KpiRow(padding: EdgeInsets.zero, [
                  KpiCard(
                    icon: Icons.today_outlined,
                    tone: Tone.info,
                    label: 'Omzet hari ini',
                    value: rupiah(c.today?.omzet ?? 0),
                    hint: '${c.today?.invoices ?? 0} invoice',
                  ),
                  KpiCard(
                    icon: Icons.trending_up,
                    tone: Tone.purple,
                    label: 'Omzet bulan ini',
                    value: rupiah(c.monthOmzet),
                    hint: _delta(c.monthOmzet, c.lastMonthToDate.value),
                    hintColor: (c.lastMonthToDate.value ?? 0) > c.monthOmzet ? C.danger : Tone.success.fg,
                  ),
                  KpiCard(
                    icon: Icons.receipt_long_outlined,
                    tone: Tone.warning, // merah hanya di teks "lewat tempo"
                    label: 'Belum lunas',
                    value: rupiah(c.unpaidTotal),
                    hint: '${c.unpaid.length} invoice · ${c.overdueCount} lewat tempo',
                    hintColor: c.overdueCount > 0 ? C.danger : null,
                  ),
                  KpiCard(
                    icon: Icons.inventory_2_outlined,
                    tone: Tone.success,
                    label: 'Stok menipis',
                    value: '${c.lowStock.length} barang',
                    hint: c.lowStock.isEmpty ? 'Aman' : 'Perlu belanja',
                  ),
                ]),
                const SizedBox(height: S.lg),
                Row(
                  children: [
                    Expanded(
                      child: KpiCard(
                        icon: Icons.savings_outlined,
                        tone: Tone.success,
                        label: 'Laba bersih bulan ini',
                        value: c.profit.value == null ? '—' : rupiah(c.profit.value!),
                        hint: 'Detail di Laporan',
                        ownerOnly: true,
                      ),
                    ),
                    const SizedBox(width: S.lg),
                    Expanded(
                      child: KpiCard(
                        icon: Icons.account_balance_wallet_outlined,
                        tone: Tone.info,
                        label: 'Saldo semua rekening',
                        value: c.balance.value == null ? '—' : rupiah(c.balance.value!),
                        hint: 'Detail di Kas & Bank',
                        ownerOnly: true,
                      ),
                    ),
                    const SizedBox(width: S.lg),
                    Expanded(
                      child: KpiCard(
                        icon: Icons.description_outlined,
                        tone: Tone.neutral,
                        label: 'Invoice bulan ini',
                        value: '${c.monthInvoices}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: S.lg),
                _ChartToolbar(c),
                const SizedBox(height: S.sm),
                SizedBox(
                  height: 300,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _SalesChart(c)),
                      const SizedBox(width: S.lg),
                      Expanded(child: _FlowChart(c)),
                    ],
                  ),
                ),
                const SizedBox(height: S.lg),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ListCard(
                          title: 'Belum lunas',
                          page: AppPage.penjualan,
                          empty: 'Semua invoice lunas.',
                          rows: [
                            for (final d in c.unpaid.take(5))
                              _Line(
                                '${d.doc.no} · ${d.customerName ?? 'UMUM'}',
                                rp(d.remaining),
                                pill: d.overdue(DateTime.now()) ? statusPill(d) : null,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: S.lg),
                      Expanded(
                        child: _ListCard(
                          title: 'Terlaris bulan ini',
                          page: AppPage.laporan,
                          empty: 'Belum ada penjualan bulan ini.',
                          rows: [for (final t in c.top) _Line(t.name, '${t.qty}×')],
                        ),
                      ),
                      const SizedBox(width: S.lg),
                      Expanded(
                        child: _ListCard(
                          title: 'Stok menipis',
                          page: AppPage.gudang,
                          empty: 'Tidak ada stok menipis.',
                          rows: [
                            for (final s in c.lowStock.take(5))
                              _Line(s.product.name, '${s.stock} ${s.product.unit}'.trim(), danger: s.stock <= 0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  /// "▲ 12% dari bulan lalu" — selalu dengan panah, bukan hanya warna (design.md §6).
  static String? _delta(int now, int? before) {
    if (before == null || before == 0) return null;
    final pct = ((now - before) * 100 / before).round();
    return '${pct >= 0 ? '▲' : '▼'} ${pct.abs()}% vs periode sama bulan lalu';
  }
}

/// Jarak antar label sumbu X supaya tidak sesak (maks. ~6 label).
double _axisInterval(int n) => (n / 6).ceilToDouble().clamp(1, double.infinity);

/// fl_chart selalu memaksa label di titik terakhir (meta.max) di luar kelipatan [interval] — kalau
/// dibiarkan, tanda kisi terdekat bertabrakan dengannya. Lewati tanda itu, titik terakhir tetap tampil.
bool _showAxisLabel(int i, int n, double interval) {
  if (i == 0 || i == n - 1) return true;
  return (n - 1 - i) >= interval;
}

class _ChartToolbar extends StatelessWidget {
  const _ChartToolbar(this.c);
  final DashboardController c;

  Future<void> _pickRange(BuildContext context) async {
    final today = DateTime.now();
    final end = c.chartTo.value.subtract(const Duration(days: 1));
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: c.chartFrom.value.isAfter(today) ? today : c.chartFrom.value,
        end: end.isAfter(today) ? today : end,
      ),
    );
    if (r != null) c.setChartRange(r.start, r.end);
  }

  @override
  Widget build(BuildContext context) => Obx(
    () => Row(
      children: [
        SegmentedButton<Period>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: Period.daily, label: Text('Harian')),
            ButtonSegment(value: Period.monthly, label: Text('Bulanan')),
            ButtonSegment(value: Period.yearly, label: Text('Tahunan')),
          ],
          selected: {c.chartPeriod.value},
          onSelectionChanged: (s) => c.setChartPeriod(s.first),
        ),
        const SizedBox(width: S.md),
        OutlinedButton.icon(
          onPressed: () => _pickRange(context),
          icon: const Icon(Icons.date_range_outlined, size: 18),
          label: Text('${tgl(c.chartFrom.value)} – ${tgl(c.chartTo.value.subtract(const Duration(days: 1)))}'),
        ),
      ],
    ),
  );
}

/// Omzet per titik (harian/bulanan/tahunan, rentang bisa diganti) — semua pengguna (C16).
class _SalesChart extends StatelessWidget {
  const _SalesChart(this.c);
  final DashboardController c;

  @override
  Widget build(BuildContext context) => Obx(() {
    final points = c.chartPoints.toList();
    final maxY = points.fold<int>(0, (m, p) => p.omzet > m ? p.omzet : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(S.lg, S.lg, S.xl, S.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Omzet', style: T.section),
            const SizedBox(height: S.lg),
            Expanded(
              child: points.isEmpty
                  ? const SizedBox()
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxY == 0 ? 1 : maxY * 1.15,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(color: C.border, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 52,
                              getTitlesWidget: (v, meta) => SideTitleWidget(
                                meta: meta,
                                child: Text(v == meta.max ? '' : rpShort(v.round()), style: T.label),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: _axisInterval(points.length),
                              getTitlesWidget: (v, meta) {
                                final i = v.round();
                                if (i < 0 || i >= points.length || v != i) return const SizedBox();
                                if (!_showAxisLabel(i, points.length, meta.appliedInterval)) return const SizedBox();
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(points[i].label, style: T.label),
                                );
                              },
                            ),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => C.ink,
                            getTooltipItems: (spots) => [
                              for (final s in spots)
                                LineTooltipItem(
                                  '${points[s.x.round()].label}\n${rupiah(s.y.round())}',
                                  T.label.copyWith(color: C.surface),
                                ),
                            ],
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [for (final (i, p) in points.indexed) FlSpot(i.toDouble(), p.omzet.toDouble())],
                            isCurved: true,
                            preventCurveOverShooting: true,
                            color: C.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: C.primary.withValues(alpha: 0.12)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  });
}

/// Bagan pemasukan vs pengeluaran per titik — semua pengguna (saldo tidak ditampilkan, tetap khusus
/// owner di Kas & Bank). Mencakup penjualan/pembelian & kas-bank sekaligus (C14/C15).
class _FlowChart extends StatelessWidget {
  const _FlowChart(this.c);
  final DashboardController c;

  @override
  Widget build(BuildContext context) => Obx(() {
    final rows = c.flowPoints.toList();
    final maxY = rows.fold<int>(0, (m, f) => [f.income, f.expense, m].reduce((a, b) => a > b ? a : b));
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(S.lg, S.lg, S.xl, S.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Pemasukan & pengeluaran', style: T.section),
                const Spacer(),
                _Dot(Tone.success.fg, 'Masuk'),
                const SizedBox(width: S.md),
                _Dot(C.danger, 'Keluar'),
              ],
            ),
            const SizedBox(height: S.lg),
            Expanded(
              child: rows.isEmpty
                  ? const SizedBox()
                  : BarChart(
                      BarChartData(
                        maxY: maxY == 0 ? 1 : maxY * 1.15,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(color: C.border, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 52,
                              getTitlesWidget: (v, meta) => SideTitleWidget(
                                meta: meta,
                                child: Text(v == meta.max ? '' : rpShort(v.round()), style: T.label),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: _axisInterval(rows.length),
                              getTitlesWidget: (v, meta) {
                                final i = v.round();
                                if (i < 0 || i >= rows.length || v != i) return const SizedBox();
                                if (!_showAxisLabel(i, rows.length, meta.appliedInterval)) return const SizedBox();
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(rows[i].label, style: T.label),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => C.ink,
                            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                              '${rows[group.x].label}\n${rupiah(rod.toY.round())}',
                              T.label.copyWith(color: C.surface),
                            ),
                          ),
                        ),
                        barGroups: [
                          for (final (i, f) in rows.indexed)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(toY: f.income.toDouble(), color: Tone.success.fg, width: 7),
                                BarChartRodData(toY: f.expense.toDouble(), color: C.danger, width: 7),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  });
}

class _Dot extends StatelessWidget {
  const _Dot(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: S.xs),
      Text(label, style: T.label),
    ],
  );
}

class _Line {
  const _Line(this.label, this.value, {this.pill, this.danger = false});
  final String label, value;
  final Widget? pill;
  final bool danger;
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.title, required this.page, required this.empty, required this.rows});
  final String title, empty;
  final AppPage page;
  final List<_Line> rows;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(S.lg, S.md, S.sm, S.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: T.section)),
              TextButton(onPressed: () => Get.find<Nav>().page.value = page, child: const Text('Lihat semua')),
            ],
          ),
          const SizedBox(height: S.sm),
          if (rows.isEmpty) Text(empty, style: T.pageSubtitle),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(right: S.sm, bottom: S.sm),
              child: Row(
                children: [
                  Expanded(child: Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (r.pill != null) ...[r.pill!, const SizedBox(width: S.sm)],
                  Text(r.value, style: T.money.copyWith(color: r.danger ? C.danger : null)),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
