import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
                    tone: Tone.success,
                    label: 'Omzet bulan ini',
                    value: rupiah(c.monthOmzet),
                    hint: _delta(c.monthOmzet, c.lastMonthToDate.value),
                    hintColor: (c.lastMonthToDate.value ?? 0) > c.monthOmzet ? C.danger : Tone.success.fg,
                  ),
                  KpiCard(
                    icon: Icons.receipt_long_outlined,
                    tone: c.overdueCount > 0 ? Tone.danger : Tone.warning,
                    label: 'Belum lunas',
                    value: rupiah(c.unpaidTotal),
                    hint: '${c.unpaid.length} invoice · ${c.overdueCount} lewat tempo',
                    hintColor: c.overdueCount > 0 ? C.danger : null,
                  ),
                  KpiCard(
                    icon: Icons.inventory_2_outlined,
                    tone: c.lowStock.isEmpty ? Tone.neutral : Tone.warning,
                    label: 'Stok menipis',
                    value: '${c.lowStock.length} barang',
                    hint: c.lowStock.isEmpty ? 'Aman' : 'Perlu belanja',
                  ),
                ]),
                const SizedBox(height: S.lg),
                SizedBox(
                  height: 320,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _SalesChart(c)),
                      const SizedBox(width: S.lg),
                      Expanded(
                        child: Column(
                          children: [
                            KpiCard(
                              icon: Icons.savings_outlined,
                              tone: Tone.success,
                              label: 'Laba bersih bulan ini',
                              value: c.profit.value == null ? '—' : rupiah(c.profit.value!),
                              hint: 'Detail di Laporan',
                              ownerOnly: true,
                            ),
                            const SizedBox(height: S.lg),
                            KpiCard(
                              icon: Icons.account_balance_wallet_outlined,
                              tone: Tone.info,
                              label: 'Saldo semua rekening',
                              value: c.balance.value == null ? '—' : rupiah(c.balance.value!),
                              hint: 'Detail di Kas & Bank',
                              ownerOnly: true,
                            ),
                            const SizedBox(height: S.lg),
                            KpiCard(
                              icon: Icons.description_outlined,
                              tone: Tone.neutral,
                              label: 'Invoice bulan ini',
                              value: '${c.monthInvoices}',
                            ),
                          ],
                        ),
                      ),
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

class _SalesChart extends StatelessWidget {
  const _SalesChart(this.c);
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    final points = c.months;
    final maxY = points.fold<int>(0, (m, p) => p.omzet > m ? p.omzet : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(S.lg, S.lg, S.xl, S.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Omzet 12 bulan', style: T.section),
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
                              interval: 1,
                              getTitlesWidget: (v, meta) {
                                final i = v.round();
                                if (i < 0 || i >= points.length || v != i) return const SizedBox();
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(DateFormat('MMM', 'id').format(points[i].start), style: T.label),
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
                                  '${DateFormat('MMMM y', 'id').format(points[s.x.round()].start)}\n${rupiah(s.y.round())}',
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
                            color: C.brandOrange,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: C.brandOrange.withValues(alpha: 0.12)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
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
