import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/proof.dart';
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
                final all = c.inRange();
                final rows = c.visible(all, tagihan: tagihan);
                final lunas = all.where((r) => r.paid).toList(), belum = all.where((r) => !r.paid).toList();
                int sum(List<PurchaseRow> rs) => rs.fold(0, (t, r) => t + r.purchase.total);

                final opened = c.purchases.firstWhereOrNull((r) => r.purchase.id == c.purchaseId.value);
                final kpis = KpiRow(padding: const EdgeInsets.only(bottom: S.lg), [
                  KpiCard(
                    icon: Icons.check_circle_outline,
                    tone: Tone.success,
                    label: 'Sudah dibayar',
                    value: rupiah(sum(lunas)),
                    hint: '${lunas.length} nota',
                    onTap: () => c.togglePaid(true),
                    selected: !tagihan && c.paid.value == true,
                  ),
                  KpiCard(
                    icon: Icons.request_quote_outlined,
                    tone: belum.isEmpty ? Tone.neutral : Tone.warning,
                    label: 'Belum dibayar',
                    value: rupiah(sum(belum)),
                    hint: '${belum.length} nota',
                    onTap: tagihan ? null : () => c.togglePaid(false),
                    selected: tagihan || c.paid.value == false,
                  ),
                ]);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    kpis,
                    Expanded(
                      child: MasterDetail(
                        panelWidth: 420,
                        list: AppTable<PurchaseRow>(
                          rows: rows,
                          searchHint: 'Cari no., supplier, nota supplier, keterangan…',
                          searchText: (r) =>
                              '${r.purchase.no} ${r.purchase.supplier} ${r.purchase.billNo} ${r.purchase.note} ${r.account}',
                          selected: (r) => r.purchase.id == c.purchaseId.value,
                          onTap: (r) => c.purchaseId.value = r.purchase.id,
                          toolbar: [
                            RangeButton(range: range, onChanged: (r) => c.range.value = r, clearable: true),
                            const SizedBox(width: S.sm),
                            exportButton(context, () => c.export(tagihan: tagihan)),
                          ],
                          emptyMessage: tagihan
                              ? 'Tidak ada tagihan pembelian.'
                              : c.paid.value != null
                              ? 'Tidak ada pembelian untuk saringan ini.'
                              : 'Belum ada pembelian stok.',
                          columns: [
                            Col(
                              'No.',
                              (r) => Text(r.purchase.no.isEmpty ? '—' : r.purchase.no),
                              flex: 2,
                              sort: (r) => r.purchase.no.isEmpty ? null : r.purchase.no,
                            ),
                            Col('Tgl beli', (r) => Text(tgl(r.purchase.at)), flex: 2, sort: (r) => r.purchase.at),
                            Col(
                              'Supplier',
                              (r) => Text(r.purchase.supplier.isEmpty ? '—' : r.purchase.supplier),
                              flex: 3,
                              sort: (r) => r.purchase.supplier.isEmpty ? null : r.purchase.supplier,
                            ),
                            Col(
                              'Nota supplier',
                              (r) => Text(r.purchase.billNo.isEmpty ? '—' : r.purchase.billNo),
                              flex: 2,
                              sort: (r) => r.purchase.billNo.isEmpty ? null : r.purchase.billNo,
                            ),
                            Col(
                              'Total',
                              (r) => Text(rp(r.purchase.total), style: T.money),
                              flex: 2,
                              numeric: true,
                              sort: (r) => r.purchase.total,
                            ),
                            Col(
                              'Status',
                              (r) => Pill(r.paid ? 'Lunas' : 'Belum bayar', r.paid ? Tone.success : Tone.warning),
                              flex: 3,
                              sort: (r) => r.paid,
                            ),
                            Col(
                              'Tgl lunas',
                              (r) => Text(
                                r.paidAt == null || DateUtils.isSameDay(r.paidAt, r.purchase.at) ? '—' : tgl(r.paidAt!),
                              ),
                              flex: 2,
                              sort: (r) => r.paidAt,
                            ),
                          ],
                        ),
                        panel: opened == null
                            ? null
                            : _PurchasePanel(key: ValueKey(opened.purchase.id), c: c, row: opened),
                      ),
                    ),
                  ],
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

  Future<void> _delete(BuildContext context) async {
    final c = widget.c, p = widget.row.purchase;
    if (!await confirmAction(
          context,
          title: 'Hapus pembelian${p.no.isEmpty ? '' : ' ${p.no}'}?',
          message:
              'Stok barang dari pembelian ini ditarik lagi dan uang keluarnya dihapus dari Kas & Bank. '
              'Backup otomatis dibuat dulu. Bila barangnya sudah terjual, pembelian tidak bisa dihapus.',
          confirmLabel: 'Hapus',
          destructive: true,
        ) ||
        !context.mounted) {
      return;
    }
    if (await runAction(context, () async {
      await c.db.backupTo(await c.db.backupDir());
      await c.db.deletePurchase(p.id);
    }, 'Pembelian dihapus')) {
      c.purchaseId.value = null;
    }
  }

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
                Expanded(
                  child: Text(['Pembelian', if (p.no.isNotEmpty) p.no, tgl(p.at)].join(' · '), style: T.section),
                ),
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
                          if (p.billNo.isNotEmpty) 'nota supplier ${p.billNo}',
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
                const SizedBox(height: S.sm),
                Row(
                  children: [
                    DangerButton(label: 'Hapus', onPressed: () => _delete(context)),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => _showEditPurchase(context, c, row),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(p.proofPath.isEmpty ? 'Ubah / upload nota' : 'Ubah'),
                    ),
                  ],
                ),
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

/// Ubah data nota pembelian (R7 #4). Barang/qty/harga tidak bisa diubah: hapus lalu catat ulang.
Future<void> _showEditPurchase(BuildContext context, PembelianController c, PurchaseRow row) async {
  final p = row.purchase;
  final accounts = [
    for (final a in await c.db.select(c.db.accounts).get())
      if (a.active || a.id == p.accountId) a,
  ];
  if (!context.mounted) return;
  final vendors = [for (final v in await c.db.select(c.db.vendors).get()) v.name]..sort();
  if (!context.mounted) return;
  final supplierFocus = FocusNode();
  final supplier = TextEditingController(text: p.supplier),
      billNo = TextEditingController(text: p.billNo),
      note = TextEditingController(text: p.note);
  var date = p.at, accountId = p.accountId, proof = p.proofPath;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Ubah pembelian${p.no.isEmpty ? '' : ' ${p.no}'}'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateField(ctx, date, (d) => setState(() => date = d), label: 'Tanggal beli'),
                const SizedBox(height: S.sm),
                Labeled('Vendor', VendorField(controller: supplier, focusNode: supplierFocus, vendors: vendors)),
                const SizedBox(height: S.sm),
                Labeled('Nota supplier', TextField(controller: billNo)),
                const SizedBox(height: S.sm),
                accountField(
                  row.paid ? 'Dibayar dari' : 'Akan dibayar dari',
                  accountId,
                  accounts,
                  (v) => setState(() => accountId = v!),
                ),
                const SizedBox(height: S.sm),
                Labeled('Keterangan', TextField(controller: note)),
                const SizedBox(height: S.sm),
                proofRow(proof, () async {
                  final f = await pickProof(billNo.text.isEmpty ? 'pembelian' : billNo.text);
                  if (f != null) setState(() => proof = f);
                }),
                const SizedBox(height: S.sm),
                Text('Barang, jumlah atau harga salah? Hapus pembelian ini lalu catat ulang.', style: T.label),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => runAction(ctx, () async {
              await c.db.updatePurchase(
                p.id,
                at: date,
                accountId: accountId,
                supplier: supplier.text,
                billNo: billNo.text,
                note: note.text,
                proofPath: proof,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            }, 'Pembelian diperbarui'),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
  supplierFocus.dispose();
  for (final t in [supplier, billNo, note]) {
    t.dispose();
  }
}
