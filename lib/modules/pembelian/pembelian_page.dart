import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/range_picker.dart';
import '../../core/table.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import '../../shell.dart' show Nav;
import '../gudang/gudang_controller.dart';
import '../gudang/gudang_dialogs.dart';
import '../gudang/gudang_repo.dart';
import 'pembelian_controller.dart';

/// Pembelian stok (owner): riwayat (tanggal beli + tanggal lunas bila beda hari) dan, lewat
/// sidebar Pembelian ▸ Tagihan Pembelian, hanya yang belum dibayar.
class PembelianPage extends StatelessWidget {
  const PembelianPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Get.find<AppDb>();
    final c = Get.put(PembelianController(db));
    final nav = Get.find<Nav>();
    final owner = Get.find<OwnerController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => PageHeader(
            title: nav.pembelianTagihan.value ? 'Tagihan Pembelian' : 'Pembelian',
            subtitle: nav.pembelianTagihan.value
                ? 'Pembelian stok yang belum dibayar.'
                : 'Riwayat pembelian stok: tanggal beli dan tanggal pelunasan.',
            actions: [
              FilledButton.icon(
                onPressed: () async {
                  if (!await owner.ensure(context)) return;
                  if (!context.mounted) return;
                  final ok = await showPurchaseDialog(context, Get.put(GudangController(db)));
                  if (ok == true && context.mounted) notify(context, 'Pembelian tersimpan, stok bertambah');
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Pembelian stok'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xl),
            child: OwnerGate(
              message: 'Pembelian berisi harga beli, khusus owner.',
              builder: (_) => Obx(() {
                final tagihan = nav.pembelianTagihan.value;
                final range = c.range.value;
                final rows = c.purchases
                    .where((r) => (!tagihan || !r.paid) && (range == null || range.covers(r.purchase.at)))
                    .toList();
                final opened = c.purchases.firstWhereOrNull((r) => r.purchase.id == c.purchaseId.value);
                return MasterDetail(
                  panelWidth: 420,
                  list: AppTable<PurchaseRow>(
                    rows: rows,
                    searchHint: 'Cari supplier, no. nota, keterangan…',
                    searchText: (r) => '${r.purchase.supplier} ${r.purchase.billNo} ${r.purchase.note} ${r.account}',
                    selected: (r) => r.purchase.id == c.purchaseId.value,
                    onTap: (r) => c.purchaseId.value = r.purchase.id,
                    toolbar: [RangeButton(range: range, onChanged: (r) => c.range.value = r, clearable: true)],
                    emptyMessage: tagihan ? 'Tidak ada tagihan pembelian.' : 'Belum ada pembelian stok.',
                    columns: [
                      Col('Tgl beli', (r) => Text(tgl(r.purchase.at)), flex: 2),
                      Col('Supplier', (r) => Text(r.purchase.supplier.isEmpty ? '—' : r.purchase.supplier), flex: 3),
                      Col('No. nota', (r) => Text(r.purchase.billNo.isEmpty ? '—' : r.purchase.billNo), flex: 2),
                      Col('Total', (r) => Text(rp(r.purchase.total), style: T.money), flex: 2, numeric: true),
                      Col(
                        'Status',
                        (r) => Pill(r.paid ? 'Lunas' : 'Belum bayar', r.paid ? Tone.success : Tone.warning),
                        flex: 3,
                      ),
                      Col(
                        'Tgl lunas',
                        (r) => Text(
                          r.paidAt == null || DateUtils.isSameDay(r.paidAt, r.purchase.at) ? '—' : tgl(r.paidAt!),
                        ),
                        flex: 2,
                      ),
                    ],
                  ),
                  panel: opened == null ? null : _PurchasePanel(key: ValueKey(opened.purchase.id), c: c, row: opened),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _PurchasePanel extends StatefulWidget {
  const _PurchasePanel({super.key, required this.c, required this.row});
  final PembelianController c;
  final PurchaseRow row;

  @override
  State<_PurchasePanel> createState() => _PurchasePanelState();
}

class _PurchasePanelState extends State<_PurchasePanel> {
  // Dimuat sekali per pembelian (panel di-key per id), bukan tiap rebuild daftar.
  late final _lines = widget.c.db.purchaseLines(widget.row.purchase.id);

  @override
  Widget build(BuildContext context) {
    final c = widget.c, row = widget.row, p = row.purchase;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(S.xl, S.lg, S.sm, S.sm),
            child: Row(
              children: [
                Expanded(child: Text('Pembelian ${tgl(p.at)}', style: T.section)),
                IconButton(tooltip: 'Tutup', onPressed: () => c.purchaseId.value = null, icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(S.xl),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        [
                          if (p.supplier.isNotEmpty) p.supplier,
                          if (p.billNo.isNotEmpty) 'nota ${p.billNo}',
                          'dibayar dari ${row.account}',
                        ].join(' · '),
                        style: T.label,
                      ),
                    ),
                    Pill(row.paid ? 'Lunas' : 'Belum bayar', row.paid ? Tone.success : Tone.warning),
                  ],
                ),
                if (row.paidAt != null && !DateUtils.isSameDay(row.paidAt, p.at)) ...[
                  const SizedBox(height: S.xs),
                  Text('Dilunasi ${tgl(row.paidAt!)}', style: T.label),
                ],
                if (p.note.isNotEmpty) ...[const SizedBox(height: S.xs), Text(p.note, style: T.label)],
                if (p.proofPath.isNotEmpty) ...[
                  const SizedBox(height: S.sm),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.file(p.proofPath)),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Lihat nota'),
                  ),
                ],
                if (!row.paid) ...[
                  const SizedBox(height: S.sm),
                  FilledButton(
                    onPressed: () =>
                        runAction(context, () => c.db.payPurchase(p.id, at: DateTime.now()), 'Pembelian dilunasi'),
                    child: const Text('Lunasi sekarang'),
                  ),
                ],
                const SizedBox(height: S.lg),
                FutureBuilder(
                  future: _lines,
                  builder: (_, snap) => Column(
                    children: [
                      if (snap.hasError) Text('Rincian gagal dimuat: ${snap.error}', style: T.label),
                      for (final l in snap.data ?? const <({StockMove move, Product product})>[])
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: S.sm),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: C.border)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.product.name, overflow: TextOverflow.ellipsis),
                                    Text('${l.move.qty} × ${rp(l.move.unitCost ?? 0)}', style: T.label),
                                  ],
                                ),
                              ),
                              Text(rp(l.move.qty * (l.move.unitCost ?? 0)), style: T.money),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: S.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Total ${rupiah(p.total)}', style: T.section),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
