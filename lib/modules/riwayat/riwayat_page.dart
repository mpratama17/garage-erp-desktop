import 'dart:isolate';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../core/xlsx_values.dart';
import '../../db/database.dart';
import 'riwayat_parser.dart';
import 'riwayat_repo.dart';

/// Isi kartu "Data" di Pengaturan: import catatan lama, samakan saldo, batalkan import, kosongkan transaksi.
/// Semua khusus owner (dicek lagi di repo); yang mengubah data didahului backup otomatis.
class DataActions extends StatelessWidget {
  const DataActions({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(String title, String desc, Widget button) => Padding(
      padding: const EdgeInsets.only(bottom: S.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: T.fieldLabel),
                const SizedBox(height: 2),
                Text(desc, style: T.label.copyWith(fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          const SizedBox(width: S.md),
          button,
        ],
      ),
    );
    return Column(
      children: [
        item(
          'Import catatan lama',
          'Spreadsheet "Pemasukan + Hitung Uang": penjualan & pengeluaran per bulan. Dicek dulu sebelum disimpan.',
          FilledButton(onPressed: () => _import(context), child: const Text('Import…')),
        ),
        item(
          'Samakan saldo rekening',
          'Isi saldo nyata hari ini per rekening; saldo awal dihitung mundur.',
          OutlinedButton(onPressed: () => _balances(context), child: const Text('Samakan…')),
        ),
        item(
          'Batalkan import',
          'Hapus semua data hasil import catatan lama.',
          OutlinedButton(onPressed: () => _undo(context), child: const Text('Batalkan…')),
        ),
        item(
          'Kosongkan transaksi',
          'Hapus semua transaksi (mis. data percobaan). Produk, stok awal, customer, karyawan & rekening tetap.',
          DangerButton(label: 'Kosongkan…', onPressed: () => _wipe(context), icon: Icons.delete_sweep_outlined),
        ),
      ],
    );
  }
}

AppDb get _db => Get.find<AppDb>();
Future<bool> _owner(BuildContext context) => Get.find<OwnerController>().ensure(context);
Future<void> _backup() async => _db.backupTo(await _db.backupDir());

/// Tampilkan pemutar selama [f] berjalan (parse file besar ±1–2 detik).
Future<R> _busy<R>(BuildContext context, Future<R> f) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    return await f;
  } finally {
    if (context.mounted) Navigator.pop(context);
  }
}

Future<void> _import(BuildContext context) async {
  if (!await _owner(context) || !context.mounted) return;
  if (await _db.hasImportedData()) {
    if (context.mounted) {
      warn(context, 'Catatan lama sudah pernah di-import. Batalkan import dulu bila ingin mengulang.');
    }
    return;
  }
  final f = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Excel', extensions: ['xlsx']),
    ],
  );
  if (f == null || !context.mounted) return;
  final bytes = await f.readAsBytes();
  if (!context.mounted) return;
  final OldData data;
  try {
    data = await _busy(context, Isolate.run(() => parseOldWorkbook(XlsxValues.decode(bytes))));
  } catch (e, st) {
    // Bukan .xlsx / isi rusak / format lain: beri tahu, jangan diam (detail ke log).
    if (e is! FormatException) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st, library: 'riwayat'));
    }
    if (context.mounted) {
      warn(context, e is FormatException ? e.message : 'File tidak bisa dibaca sebagai catatan lama');
    }
    return;
  }
  if (!context.mounted) return;
  if (data.checks.isEmpty) return warn(context, 'Tidak ada sheet bulanan yang dikenali di file ini');
  final first = await _db.firstAppTransaction();
  if (!context.mounted) return;
  final before = await showDialog<DateTime>(
    context: context,
    builder: (_) => OldImportPreview(data, firstAppTransaction: first),
  );
  if (before == null || !context.mounted) return;
  OldImportResult? res;
  await runAction(context, () async {
    await _backup();
    res = await _db.importOld(data, before: before);
  });
  if (res == null || !context.mounted) return;
  final r = res!;
  // Catatan yang baru muncul saat menyimpan (mis. kategori/rekening tidak ditemukan di app) — pratinjau tidak tahu.
  final importNotes = r.problems.skip(data.problems.length).toList();
  final next = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      title: const Text('Import selesai'),
      content: Text(
        '${r.invoices} invoice lama, ${r.expenses} biaya, ${r.salaries} gaji, ${r.stockBuys} pembelian stok tersimpan '
        '(${r.skipped} baris sejak ${tgl(before)} dilewati).\n'
        'Customer: ${r.customersMatched} cocok dengan yang sudah ada, ${r.customersCreated} baru.\n'
        '${r.accountsCreated.isEmpty ? '' : 'Rekening baru: ${r.accountsCreated.join(', ')}.\n'}'
        '${importNotes.isEmpty ? '' : '\nCatatan saat import:\n${importNotes.map((n) => '• $n').join('\n')}\n'}'
        '\nLangkah berikutnya: samakan saldo tiap rekening dengan saldo nyata hari ini.',
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nanti')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Samakan saldo')),
      ],
    ),
  );
  if (next == true && context.mounted) await _balances(context);
}

/// Pratinjau sebelum import: total per sheet vs total yang ditulis sheet, pemetaan kategori, catatan, tanggal batas.
/// Hasil dialog = tanggal batas (import hanya yang sebelum tanggal itu), null = batal.
class OldImportPreview extends StatefulWidget {
  const OldImportPreview(this.data, {super.key, this.firstAppTransaction});
  final OldData data;

  /// Transaksi app paling awal: tanggal batas default = sehari sebelumnya (sejak itu sumbernya app).
  final DateTime? firstAppTransaction;

  @override
  State<OldImportPreview> createState() => _OldImportPreviewState();
}

class _OldImportPreviewState extends State<OldImportPreview> {
  final _today = DateUtils.dateOnly(DateTime.now());
  // Tanggal terakhir yang di-import (batas eksklusif = hari sesudahnya). Default: sehari sebelum transaksi app
  // paling awal, supaya periode yang sudah dicatat di app tidak tercatat dua kali; app kosong → hari ini.
  late DateTime _last = switch (widget.firstAppTransaction) {
    final f? => DateUtils.dateOnly(f).subtract(const Duration(days: 1)),
    null => _today,
  };

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final before = _last.add(const Duration(days: 1));
    final dates = [for (final v in d.invoices) v.at, for (final e in d.expenses) e.at]..sort();
    final skipped =
        d.invoices.where((v) => !v.at.isBefore(before)).length + d.expenses.where((e) => !e.at.isBefore(before)).length;
    final cats = <String, (int, int)>{};
    for (final e in d.expenses) {
      final c = cats[e.category] ?? (0, 0);
      cats[e.category] = (c.$1 + 1, c.$2 + e.amount);
    }
    final bad = d.checks.where((c) => !c.ok).length;

    Widget cell(String t, {bool right = false, TextStyle? style}) => Expanded(
      child: Text(t, textAlign: right ? TextAlign.right : TextAlign.left, style: style ?? T.money),
    );
    String vs(int got, int? label) => label == null || label == got ? rp(got) : '${rp(got)} ≠ ${rp(label)}';

    return AlertDialog(
      title: const Text('Periksa catatan lama'),
      content: SizedBox(
        width: 820,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              '${d.invoices.length} invoice & ${d.expenses.length} pengeluaran dari ${d.checks.length} sheet '
              '(${dates.isEmpty ? '-' : '${tgl(dates.first)} – ${tgl(dates.last)}'}). '
              '${bad == 0 ? 'Semua total cocok dengan total yang ditulis sheet.' : '$bad sheet totalnya beda — periksa sebelum import.'}',
              style: T.body.copyWith(color: bad == 0 ? null : C.danger),
            ),
            const SizedBox(height: S.lg),
            Row(
              children: [
                cell('Sheet', style: T.label),
                cell('Invoice', right: true, style: T.label),
                cell('Penjualan', right: true, style: T.label),
                cell('Pengeluaran', right: true, style: T.label),
              ],
            ),
            const Divider(),
            for (final c in d.checks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    cell(c.sheet, style: T.body.copyWith(color: c.ok ? null : C.danger)),
                    cell('${c.invoices}', right: true),
                    cell(vs(c.sales, c.salesLabel), right: true),
                    cell(vs(c.expenses, c.expenseLabel), right: true),
                  ],
                ),
              ),
            const SizedBox(height: S.lg),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Kategori pengeluaran → kategori Biaya (${cats.length})', style: T.fieldLabel),
              children: [
                for (final MapEntry(:key, :value)
                    in cats.entries.toList()..sort((a, b) => b.value.$2.compareTo(a.value.$2)))
                  Row(
                    children: [
                      cell(key, style: T.body),
                      cell(oldCategoryLabel(key), style: T.body),
                      cell('${value.$1}×', right: true),
                      cell(rp(value.$2), right: true),
                    ],
                  ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Catatan (${d.problems.length})', style: T.fieldLabel),
              children: [
                for (final p in d.problems)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('• $p', style: T.label),
                  ),
              ],
            ),
            const SizedBox(height: S.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(width: 220, child: dateField(context, _last, (v) => setState(() => _last = v))),
                const SizedBox(width: S.md),
                Expanded(
                  child: Text(
                    'Import catatan sampai tanggal ini. Transaksi sesudahnya dicatat di app'
                    '${widget.firstAppTransaction == null ? '' : ' (transaksi app pertama: ${tgl(widget.firstAppTransaction!)})'}'
                    '${skipped == 0 ? '.' : ' — $skipped baris sheet sesudah tanggal ini tidak di-import.'}',
                    style: T.label.copyWith(fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, before), child: const Text('Import')),
      ],
    );
  }
}

Future<void> _balances(BuildContext context) async {
  if (!await _owner(context) || !context.mounted) return;
  final balances = await _db.accountBalances();
  if (!context.mounted) return;
  final ctrl = {for (final a in balances.keys) a.id: TextEditingController()};
  final actual = await showDialog<Map<int, int>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Samakan saldo dengan saldo nyata'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Isi saldo sebenarnya hari ini (cek m-banking / hitung uang tunai). Kosong = tidak diubah. '
                'Saldo awal rekening dihitung mundur supaya saldo hari ini sama dengan isian. Catatan lama tidak '
                'mencatat pindah dana antar rekening, jadi saldo per rekening di masa lalu hanya perkiraan; total kas tetap benar.',
                style: T.label.copyWith(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: S.lg),
              for (final MapEntry(key: a, value: v) in balances.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: S.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: S.md),
                          child: Text('${a.name}  ·  di app ${rupiah(v)}', style: T.body),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: MoneyField(controller: ctrl[a.id]!, label: 'Saldo nyata'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, {
            for (final MapEntry(:key, :value) in ctrl.entries)
              if (value.text.trim().isNotEmpty) key: parseRupiah(value.text),
          }),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  for (final c in ctrl.values) {
    c.dispose();
  }
  if (actual == null || actual.isEmpty || !context.mounted) return;
  await runAction(context, () => _db.setActualBalances(actual), 'Saldo ${actual.length} rekening disamakan');
}

Future<void> _undo(BuildContext context) async {
  if (!await _owner(context) || !context.mounted) return;
  if (!await _db.hasImportedData()) {
    if (context.mounted) notify(context, 'Tidak ada data hasil import', kind: Notice.info);
    return;
  }
  if (!context.mounted) return;
  final ok = await confirmAction(
    context,
    title: 'Batalkan import catatan lama?',
    message:
        'Semua invoice, biaya, gaji & pembelian stok hasil import dihapus (backup dibuat dulu). Transaksi yang dicatat '
        'langsung di app tidak tersentuh.',
    confirmLabel: 'Batalkan import',
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  await runAction(context, () async {
    await _backup();
    await _db.undoOldImport();
  }, 'Import dibatalkan');
}

Future<void> _wipe(BuildContext context) async {
  if (!await _owner(context) || !context.mounted) return;
  final counts = await _db.transactionCounts();
  if (!context.mounted) return;
  if (counts.values.every((n) => n == 0)) return notify(context, 'Belum ada transaksi', kind: Notice.info);
  final typed = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: C.danger),
        title: const Text('Kosongkan semua transaksi?'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final MapEntry(:key, :value) in counts.entries)
                if (value > 0) Text('• $key: $value', style: T.body),
              const SizedBox(height: S.md),
              Text(
                'Produk, stok awal & opname, customer, karyawan, rekening, kategori, dan pengaturan tetap. '
                'Saldo awal rekening tidak diubah (samakan lagi bila perlu). Backup dibuat dulu. '
                'Ketik KOSONGKAN untuk melanjutkan.',
                style: T.label.copyWith(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: S.sm),
              TextField(controller: typed, autofocus: true, onChanged: (_) => setState(() {})),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.danger),
            onPressed: typed.text.trim().toUpperCase() == 'KOSONGKAN' ? () => Navigator.pop(ctx, true) : null,
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    ),
  );
  typed.dispose();
  if (ok != true || !context.mounted) return;
  await runAction(context, () async {
    await _backup();
    await _db.wipeTransactions();
  }, 'Transaksi dikosongkan (backup tersimpan)');
}
