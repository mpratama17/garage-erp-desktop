import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/proof.dart';
import '../../core/range_picker.dart';
import '../../core/table.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import 'doc_editor.dart';
import 'penjualan_controller.dart';
import 'penjualan_repo.dart';

/// Pil status: selalu berisi teks (design.md §2).
Widget statusPill(DocSummary s) {
  final overdue = s.overdue(DateTime.now());
  return switch (s.status) {
    PayStatus.paid => Pill(PayStatus.paid.label, Tone.success),
    PayStatus.partial => Pill(
      overdue ? 'Sebagian · lewat tempo' : PayStatus.partial.label,
      overdue ? Tone.danger : Tone.warning,
    ),
    PayStatus.unpaid => Pill(overdue ? 'Lewat jatuh tempo' : PayStatus.unpaid.label, overdue ? Tone.danger : Tone.info),
    PayStatus.invoiced || PayStatus.voided => Pill(s.status.label, Tone.neutral),
  };
}

/// Setelah dokumen baru tersimpan: konfirmasi jelas + langkah berikutnya (PDF, WA), bukan sekadar toast.
Future<void> _savedDialog(BuildContext context, PenjualanController c, int id) async {
  final s = await c.db.docSummary(id);
  if (!context.mounted) return;
  final hasPhone = (s.customerPhone ?? '').isNotEmpty;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: Tone.success.bg, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, color: Tone.success.fg, size: 32),
      ),
      title: Text('${s.doc.no} tersimpan', textAlign: TextAlign.center),
      content: Text(
        [
          s.customerName ?? 'UMUM',
          'Total ${rupiah(s.total)}',
          if (s.paid > 0) s.remaining > 0 ? 'Dibayar ${rupiah(s.paid)}' : 'Lunas',
        ].join(' · '),
        textAlign: TextAlign.center,
        style: T.body.copyWith(color: C.inkMuted),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton.icon(
          onPressed: () => runAction(
            ctx,
            () => c.openPdf(id),
            null,
            'PDF gagal dibuat atau dibuka. Cek folder simpan file di Pengaturan, lalu coba lagi.',
          ),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Buka PDF'),
        ),
        if (hasPhone)
          OutlinedButton.icon(
            onPressed: () => runAction(
              ctx,
              () => c.sendWa(id),
              'WhatsApp terbuka. Seret file PDF dari Finder ke chat, lalu kirim.',
              'WhatsApp tidak bisa dibuka. Cek koneksi internet atau nomor HP customer.',
            ),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Kirim WA'),
          ),
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Selesai')),
      ],
    ),
  );
}

class PenjualanPage extends StatelessWidget {
  const PenjualanPage({super.key});

  /// Ringkasan dari daftar yang sudah dimuat (tab aktif).
  static List<Widget> _kpis(PenjualanController c) {
    final now = DateTime.now();
    final docs = c.docs.where((d) => !d.doc.isVoid).toList();
    int sum(Iterable<DocSummary> ds, int Function(DocSummary) f) => ds.fold(0, (t, d) => t + f(d));
    if (c.kind.value == DocKind.order) {
      final open = docs.where((d) => !d.hasInvoice).toList();
      return [
        KpiCard(
          icon: Icons.event_note_outlined,
          tone: Tone.info,
          label: 'Pemesanan terbuka',
          value: '${open.length}',
          hint: 'Nilai ${rupiah(sum(open, (d) => d.total))}',
        ),
        KpiCard(
          icon: Icons.savings_outlined,
          tone: Tone.success,
          label: 'DP diterima',
          value: rupiah(sum(open, (d) => d.paid)),
        ),
        KpiCard(
          icon: Icons.hourglass_bottom,
          tone: Tone.warning,
          label: 'Sisa tagihan',
          value: rupiah(sum(open, (d) => d.remaining)),
        ),
      ];
    }
    final month = docs.where((d) => d.doc.at.year == now.year && d.doc.at.month == now.month).toList();
    final unpaid = docs.where((d) => d.status == PayStatus.unpaid || d.status == PayStatus.partial).toList();
    final overdue = unpaid.where((d) => d.overdue(now)).toList();
    return [
      KpiCard(
        icon: Icons.trending_up,
        tone: Tone.success,
        label: 'Penjualan bulan ini',
        value: rupiah(sum(month, (d) => d.omzet)), // tanpa PPN, sama dengan Dashboard & Laporan
        hint: '${month.length} invoice',
      ),
      KpiCard(
        icon: Icons.receipt_long_outlined,
        tone: Tone.warning,
        label: 'Belum dibayar',
        value: rupiah(sum(unpaid, (d) => d.remaining)),
        hint: '${unpaid.length} invoice',
      ),
      KpiCard(
        icon: Icons.warning_amber_rounded,
        tone: overdue.isEmpty ? Tone.neutral : Tone.danger,
        label: 'Lewat jatuh tempo',
        value: '${overdue.length} invoice',
        hint: overdue.isEmpty ? 'Aman' : rupiah(sum(overdue, (d) => d.remaining)),
        hintColor: overdue.isEmpty ? null : C.danger,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(PenjualanController(Get.find<AppDb>()));

    Future<void> create(String kind, {bool legacy = false}) async {
      final id = await showDocEditor(context, c, kind: kind, legacy: legacy);
      if (id == null) return;
      c.kind.value = kind;
      c.panelId.value = id;
      if (context.mounted) await _savedDialog(context, c, id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final isOrder = c.kind.value == DocKind.order;
          return PageHeader(
            title: isOrder ? 'Pemesanan' : 'Tagihan',
            subtitle: isOrder
                ? 'Pesanan dengan DP; setelah selesai dibuatkan tagihan.'
                : 'Tagihan customer, termasuk yang tanpa pemesanan.',
            actions: [
              OutlinedButton(onPressed: () => create(c.kind.value, legacy: true), child: const Text('Transaksi lama')),
              FilledButton.icon(
                onPressed: () => create(c.kind.value),
                icon: Icon(isOrder ? Icons.event_note_outlined : Icons.point_of_sale, size: 18),
                label: Text(isOrder ? '+ Pemesanan' : '+ Tagihan'),
              ),
            ],
          );
        }),
        Obx(() => KpiRow(_kpis(c))),
        const SizedBox(height: S.lg),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xl),
            child: Obx(
              () => MasterDetail(
                list: AppTable<DocSummary>(
                  rows: c.visible,
                  searchHint: 'Cari nomor, customer, HP, plat…',
                  searchText: (s) => [
                    s.doc.no,
                    s.customerName ?? 'UMUM',
                    s.customerPhone ?? '',
                    s.doc.car,
                    s.doc.plate,
                    s.doc.plate.replaceAll(' ', ''),
                  ].join(' '),
                  selected: (s) => s.doc.id == c.panelId.value,
                  onTap: (s) => c.panelId.value = s.doc.id,
                  emptyMessage: c.kind.value == DocKind.invoice ? 'Belum ada invoice.' : 'Belum ada pemesanan.',
                  toolbar: [
                    RangeButton(range: c.range.value, onChanged: (r) => c.range.value = r, clearable: true),
                    const SizedBox(width: S.sm),
                    DropdownButton<PayStatus?>(
                      value: c.status.value,
                      underline: const SizedBox(),
                      hint: const Text('Semua status'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Semua status')),
                        for (final s in PayStatus.values) DropdownMenuItem(value: s, child: Text(s.label)),
                      ],
                      onChanged: (v) => c.status.value = v,
                    ),
                    const SizedBox(width: S.sm),
                    exportButton(context, c.export),
                  ],
                  columns: [
                    Col(
                      'Nomor',
                      (s) => Text(s.doc.no, style: const TextStyle(fontWeight: FontWeight.w600)),
                      flex: 3,
                      sort: (s) => s.doc.no,
                    ),
                    Col('Tanggal', (s) => Text(tgl(s.doc.at)), flex: 3, sort: (s) => s.doc.at),
                    // Plat digabung ke kolom customer supaya tabel tetap terbaca saat panel terbuka.
                    Col(
                      'Customer · plat',
                      (s) => Text([s.customerName ?? 'UMUM', s.doc.plate].where((x) => x.isNotEmpty).join(' · ')),
                      flex: 4,
                      sort: (s) => s.customerName ?? 'UMUM',
                    ),
                    Col(
                      'Total',
                      (s) => Text(rp(s.total), style: T.money),
                      flex: 2,
                      numeric: true,
                      sort: (s) => s.total,
                    ),
                    Col(
                      'Sisa',
                      (s) => Text(s.outstanding == 0 ? '—' : rp(s.outstanding), style: T.money),
                      flex: 2,
                      numeric: true,
                      sort: (s) => s.outstanding,
                    ),
                    Col('Status', statusPill, flex: 4, sort: (s) => s.status.index),
                  ],
                ),
                panel: c.opened == null ? null : _DocPanel(c: c, s: c.opened!),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DocPanel extends StatelessWidget {
  const _DocPanel({required this.c, required this.s});
  final PenjualanController c;
  final DocSummary s;

  bool get editable => !s.doc.isVoid && s.status != PayStatus.invoiced;

  @override
  Widget build(BuildContext context) {
    final owner = Get.find<OwnerController>();
    final d = s.doc;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(S.xl, S.lg, S.sm, S.sm),
            child: Row(
              children: [
                Text(d.no, style: T.section),
                const SizedBox(width: S.sm),
                statusPill(s),
                if (d.legacy) ...[const SizedBox(width: S.xs), const Pill('Transaksi lama', Tone.neutral)],
                const Spacer(),
                IconButton(tooltip: 'Tutup', onPressed: () => c.panelId.value = null, icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(S.xl),
              children: [
                _kv(
                  'Customer',
                  [s.customerName ?? 'UMUM', if (s.customerPhone != null) displayPhone(s.customerPhone!)].join(' · '),
                ),
                _kv('Mobil', [d.car, d.plate].where((x) => x.isNotEmpty).join(' · ').ifEmpty('—')),
                _kv('Tanggal', [tgl(d.at), if (d.dueAt != null) 'jatuh tempo ${tgl(d.dueAt!)}'].join(' · ')),
                if (d.note.isNotEmpty) _kv('Catatan', d.note),
                if (d.isVoid) _kv('Alasan batal', d.voidReason),
                const SizedBox(height: S.md),
                Wrap(
                  spacing: S.sm,
                  runSpacing: S.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => runAction(
                        context,
                        () => c.openPdf(d.id),
                        null,
                        'PDF gagal dibuat atau dibuka. Cek folder simpan file di Pengaturan, lalu coba lagi.',
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('PDF / Cetak'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => runAction(
                        context,
                        () => c.sendWa(d.id),
                        'WhatsApp terbuka. Seret file PDF dari Finder ke chat, lalu kirim.',
                        'WhatsApp tidak bisa dibuka. Cek koneksi internet atau nomor HP customer.',
                      ),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: const Text('Kirim WA'),
                    ),
                    if (editable && s.remaining > 0)
                      FilledButton(
                        onPressed: () => _payDialog(context),
                        child: Text(s.isOrder ? 'Terima DP' : 'Terima pembayaran'),
                      ),
                    if (s.isOrder && editable)
                      FilledButton(
                        onPressed: () => runAction(context, () async {
                          final id = await c.db.invoiceFromOrder(d.id);
                          c.kind.value = DocKind.invoice;
                          c.panelId.value = id;
                        }, 'Invoice dibuat, DP terbawa'),
                        child: const Text('Buat invoice'),
                      ),
                    if (editable)
                      OutlinedButton(
                        onPressed: () async {
                          // Mengubah dokumen butuh PIN owner (kasir hanya menambah — C18).
                          if (!await owner.ensure(context)) return;
                          if (!context.mounted) return;
                          final id = await showDocEditor(context, c, kind: d.kind, existing: s);
                          if (id != null && context.mounted) notify(context, 'Perubahan tersimpan');
                        },
                        child: const Text('Ubah'),
                      ),
                    if (editable)
                      DangerButton(
                        label: 'Batalkan',
                        onPressed: () async {
                          if (!await owner.ensure(context)) return;
                          if (context.mounted) await _voidDialog(context);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: S.xl),
                Text('Rincian', style: T.section),
                const SizedBox(height: S.sm),
                StreamBuilder<List<InvoiceLine>>(
                  stream: c.db.watchLines(d.id),
                  builder: (_, snap) => Column(
                    children: [for (final l in snap.data ?? const <InvoiceLine>[]) _LineTile(c: c, l: l)],
                  ),
                ),
                const SizedBox(height: S.md),
                if (s.adjustments.isNotEmpty) _total('Subtotal', s.subtotal),
                for (final (label, v) in s.adjustments) _total(label, v),
                _total('Total', s.total, big: true),
                _total(s.isOrder ? 'DP / dibayar' : 'Dibayar', s.paid),
                if (!d.isVoid && s.status != PayStatus.invoiced)
                  _total('Sisa tagihan', s.remaining < 0 ? 0 : s.remaining),
                const SizedBox(height: S.xl),
                Text('Pembayaran', style: T.section),
                const SizedBox(height: S.sm),
                StreamBuilder<List<CashEntry>>(
                  stream: c.db.watchPayments(d),
                  builder: (_, snap) {
                    final pays = snap.data ?? const <CashEntry>[];
                    if (pays.isEmpty) return Text('Belum ada pembayaran.', style: T.pageSubtitle);
                    final names = {for (final a in c.allAccounts) a.id: a.name};
                    return Column(
                      children: [
                        for (final p in pays)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: S.xs),
                            child: Row(
                              children: [
                                SizedBox(width: 88, child: Text(tgl(p.at), style: T.label)),
                                Expanded(
                                  child: Text(
                                    '${names[p.accountId] ?? 'Rekening'}${p.note.isEmpty ? '' : ' · ${p.note}'}',
                                  ),
                                ),
                                if (p.proofPath.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Buka bukti',
                                    onPressed: () => runAction(
                                      context,
                                      () => launchUrl(Uri.file(p.proofPath)),
                                      null,
                                      'File bukti tidak bisa dibuka — mungkin sudah dipindah atau dihapus.',
                                    ),
                                    icon: const Icon(Icons.attach_file, size: 18),
                                  ),
                                Text(rp(p.amount), style: T.money.copyWith(color: p.amount < 0 ? C.danger : null)),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: S.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 96, child: Text(k, style: T.label)),
        Expanded(child: Text(v)),
      ],
    ),
  );

  Widget _total(String k, int v, {bool big = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(k, style: big ? T.section : T.body),
        const Spacer(),
        Text(rupiah(v), style: big ? T.section : T.money),
      ],
    ),
  );

  Future<void> _payDialog(BuildContext context) async {
    final amount = TextEditingController(text: rp(s.remaining));
    final note = TextEditingController();
    int? accountId = c.accounts.firstOrNull?.id;
    var date = DateTime.now();
    String proof = '';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('${s.isOrder ? 'Terima DP' : 'Terima pembayaran'} — ${s.doc.no}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sisa tagihan ${rupiah(s.remaining)}', style: T.label),
                const SizedBox(height: S.md),
                MoneyField(controller: amount, label: 'Nominal *'),
                const SizedBox(height: S.md),
                Row(
                  children: [
                    Expanded(
                      child: Labeled(
                        'Ke rekening *',
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: accountId,
                          items: [for (final a in c.accounts) DropdownMenuItem(value: a.id, child: Text(a.name))],
                          onChanged: (v) => accountId = v,
                        ),
                      ),
                    ),
                    const SizedBox(width: S.md),
                    SizedBox(
                      width: 140,
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => date = d);
                        },
                        child: Labeled(
                          'Tanggal',
                          InputDecorator(decoration: const InputDecoration(), child: Text(tgl(date))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: S.md),
                Labeled('Keterangan', TextField(controller: note)),
                const SizedBox(height: S.md),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final path = await pickProof(s.doc.no);
                        if (path != null) setState(() => proof = path);
                      },
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('Lampirkan bukti'),
                    ),
                    const SizedBox(width: S.sm),
                    Expanded(
                      child: Text(
                        proof.isEmpty ? 'Belum ada bukti' : path.basename(proof),
                        style: T.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (accountId == null) return warn(ctx, 'Pilih rekening');
                await runAction(ctx, () async {
                  await c.db.addPayment(
                    s.doc.id,
                    PaymentInput(
                      accountId: accountId!,
                      amount: parseRupiah(amount.text),
                      at: date,
                      note: note.text,
                      proofPath: proof,
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }, 'Pembayaran diterima');
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _voidDialog(BuildContext context) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: C.danger, size: 32),
        title: Text('Batalkan ${s.doc.no}?'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                [
                  'Dokumen tetap tersimpan dengan status Batal.',
                  if (!s.isOrder && !s.doc.legacy) 'Stok barang dikembalikan.',
                  if (s.paid > 0) 'Uang ${rupiah(s.paid)} dicatat dikembalikan ke rekening asalnya.',
                ].join(' '),
              ),
              const SizedBox(height: S.md),
              Labeled('Alasan *', TextField(controller: reason, autofocus: true)),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan dokumen'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await runAction(context, () => c.db.voidDoc(s.doc.id, reason.text), '${s.doc.no} dibatalkan');
    }
  }
}

/// Satu baris rincian: nama, qty × harga, teknisi. Modal tidak tampil di sini (diambil dari harga beli di Gudang).
class _LineTile extends StatelessWidget {
  const _LineTile({required this.c, required this.l});
  final PenjualanController c;
  final InvoiceLine l;

  @override
  Widget build(BuildContext context) {
    final techs = [l.tech1Id, l.tech2Id].whereType<int>().map(c.employeeName).where((n) => n.isNotEmpty).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: S.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(rp(l.qty * l.price - l.discount), style: T.money),
            ],
          ),
          Text(
            [
              '${l.qty} × ${rp(l.price)}',
              if (l.discount > 0) 'diskon ${rp(l.discount)}',
              if (l.description.isNotEmpty) l.description,
              if (techs.isNotEmpty) 'teknisi: $techs',
            ].join(' · '),
            style: T.label,
          ),
        ],
      ),
    );
  }
}
