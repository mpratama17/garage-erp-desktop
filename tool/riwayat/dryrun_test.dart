// ignore_for_file: avoid_print
// Dry-run import catatan lama pada file asli client — BUKAN test CI, hanya dijalankan manual:
//   RIWAYAT_XLSX="/path/PEMASUKAN + HITUNG UANG.xlsx" flutter test tool/riwayat
// Tahap import: + RIWAYAT_DB=<db app> RIWAYAT_OUT=<folder kerja di luar repo> [RIWAYAT_SEBELUM=2026-11-01].
// DB disalin ke RIWAYAT_OUT dulu; yang asli tidak disentuh. Transaksi di salinan dikosongkan (simulasi
// "kosongkan data dummy") sebelum import.
// File client tidak pernah masuk repo (repo publik). Yang dicetak hanya angka agregat, bukan nama/isi baris.
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/core/xlsx_values.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';
import 'package:garage_erp_desktop/modules/laporan/laporan_repo.dart';
import 'package:garage_erp_desktop/modules/riwayat/riwayat_parser.dart';
import 'package:garage_erp_desktop/modules/riwayat/riwayat_repo.dart';

String _rp(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
String _ym(DateTime d) => '${d.year}-${'${d.month}'.padLeft(2, '0')}';

void main() {
  final path = Platform.environment['RIWAYAT_XLSX'];

  test('parse', () {
    if (path == null) return markTestSkipped('RIWAYAT_XLSX tidak diisi');
    final sw = Stopwatch()..start();
    final x = XlsxValues.decode(File(path).readAsBytesSync());
    final data = parseOldWorkbook(x);
    print('baca+parse ${sw.elapsedMilliseconds} ms');

    print('\n## Per sheet: label sheet vs terbaca');
    for (final c in data.checks) {
      print(
        '${c.sheet.padRight(10)} inv ${'${c.invoices}'.padLeft(3)}  jual ${_rp(c.sales).padLeft(12)} / '
        'label ${_rp(c.salesLabel ?? -1).padLeft(12)}  keluar ${_rp(c.expenses).padLeft(12)} / '
        'label ${_rp(c.expenseLabel ?? -1).padLeft(12)} ${c.ok ? 'OK' : 'BEDA'}',
      );
    }
    final consistent = data.invoices.where((v) => v.subtotal - v.sheetDiscount == v.total).length;
    print(
      '\ninvoice ${data.invoices.length}, konsisten (barang − diskon = total) $consistent, '
      'dibayar 2 cara ${data.invoices.where((v) => v.payments.length > 1).length}, '
      'tanpa rincian ${data.invoices.where((v) => v.lines.isEmpty).length} '
      '(${_rp(data.invoices.where((v) => v.lines.isEmpty).fold(0, (s, v) => s + v.total))}), '
      'baris barang ${data.invoices.fold(0, (s, v) => s + v.lines.length)}, '
      'modal kosong ${data.invoices.fold(0, (s, v) => s + v.lines.where((l) => l.cost == null).length)}',
    );

    final byMonth = <String, int>{};
    for (final e in data.expenses) {
      byMonth.update(_ym(e.at), (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    print('\n## Pengeluaran per bulan (tanggal transaksi): ${data.expenses.length} baris');
    for (final k in byMonth.keys.toList()..sort()) {
      print('$k ${_rp(byMonth[k]!).padLeft(12)}');
    }
    print('\n## Masalah: ${data.problems.length}');
    for (final p in data.problems) {
      print('  ${p.replaceAll(RegExp(r'"[^"]*"'), '"…"')}'); // tanpa nama barang/isi sel
    }
  });

  test('import ke salinan DB', () async {
    final src = Platform.environment['RIWAYAT_DB'], out = Platform.environment['RIWAYAT_OUT'];
    if (path == null || src == null || out == null) return markTestSkipped('RIWAYAT_DB/RIWAYAT_OUT tidak diisi');
    final before = DateTime.tryParse(Platform.environment['RIWAYAT_SEBELUM'] ?? '');
    final copy = File('$out/dryrun.sqlite');
    if (copy.existsSync()) copy.deleteSync();
    File(src).copySync(copy.path);
    final db = AppDb(NativeDatabase(copy))..ownerUnlocked = true;
    addTearDown(db.close);
    print('versi skema salinan: ${(await db.customSelect('PRAGMA user_version').getSingle()).data.values.first}');
    await db.wipeTransactions(); // fungsi app yang sama dengan tombol Kosongkan
    final before0 = {
      for (final t in ['customers', 'products', 'stock_moves'])
        t: (await db.customSelect('SELECT COUNT(*) AS n FROM $t').getSingle()).read<int>('n'),
    };

    final data = parseOldWorkbook(XlsxValues.decode(File(path).readAsBytesSync()));
    final sw = Stopwatch()..start();
    final res = await db.importOld(data, before: before);
    print('\nimport ${sw.elapsedMilliseconds} ms; batas: ${before ?? 'tanpa batas'}');
    print(
      'invoice ${res.invoices}, baris ${res.lines}, pembayaran ${res.payments}, biaya ${res.expenses}, '
      'gaji ${res.salaries}, pembelian stok ${res.stockBuys}, dilewati (≥ batas) ${res.skipped}',
    );
    print(
      'customer: cocok ${res.customersMatched}, baru ${res.customersCreated} | produk cocok nama ${res.productsMatched} baris',
    );
    print('rekening baru: ${res.accountsCreated}; produk penampung: ${res.placeholderProducts}');
    final after = {
      for (final t in before0.keys)
        t: (await db.customSelect('SELECT COUNT(*) AS n FROM $t').getSingle()).read<int>('n'),
    };
    print('jumlah baris sebelum → sesudah: $before0 → $after');
    final kinds = <String, int>{};
    for (final p in res.problems) {
      final k = p.replaceFirst(RegExp(r'^\S+ baris \d+: '), '').replaceAll(RegExp(r'"[^"]*"'), '"…"');
      kinds.update(k, (v) => v + 1, ifAbsent: () => 1);
    }
    print('\n## Catatan import (jenis × jumlah)');
    kinds.forEach((k, v) => print('  $v× $k'));

    print('\n## Pemetaan kategori pengeluaran (sheet → app): baris, total');
    final byCat = <String, (int, int)>{};
    for (final e in data.expenses.where((e) => before == null || e.at.isBefore(before))) {
      final c = byCat[e.category] ?? (0, 0);
      byCat[e.category] = (c.$1 + 1, c.$2 + e.amount);
    }
    final cats = {for (final c in await db.select(db.expenseCategories).get()) c.name: c};
    for (final MapEntry(:key, :value) in byCat.entries.toList()..sort((a, b) => b.value.$2.compareTo(a.value.$2))) {
      final label = oldCategoryLabel(key);
      final kind = '$label${cats[label]?.personal ?? false ? ' [PRIBADI]' : ''}';
      print('  ${key.padRight(16)} → ${kind.padRight(30)} ${'${value.$1}'.padLeft(4)} ${_rp(value.$2).padLeft(13)}');
    }

    final from = DateTime(2024, 12), to = DateTime(2027);
    final flow = await db.cashFlow(from, to, Period.monthly);
    final pl = {for (final r in (await db.report(from, to, Period.monthly)).pl.rows) _ym(r.start): r};
    print('\n## Per bulan (fungsi app): arus kas masuk/keluar, laba rugi');
    print(
      'bulan        kas masuk     kas keluar  | pendapatan        HPP      biaya       gaji    pribadi  laba usaha',
    );
    for (final f in flow) {
      final p = pl[_ym(f.start)];
      print(
        '${_ym(f.start)} ${_rp(f.income).padLeft(13)} ${_rp(f.expense).padLeft(13)}  | '
        '${_rp(p?.revenue ?? 0).padLeft(11)} ${_rp(p?.cogs ?? 0).padLeft(10)} ${_rp(p?.expense ?? 0).padLeft(10)} '
        '${_rp(p?.salary ?? 0).padLeft(10)} ${_rp(p?.personal ?? 0).padLeft(10)} ${_rp(p?.net ?? 0).padLeft(11)}',
      );
    }
    print('\n## Net per rekening hasil import (saldo awal = saldo nyata hari ini − angka ini)');
    for (final a in await db.select(db.accounts).get()) {
      final n = await db
          .customSelect(
            'SELECT COALESCE(SUM(amount), 0) AS n FROM cash_entries WHERE account_id = ?',
            variables: [Variable.withInt(a.id)],
          )
          .getSingle();
      print('  ${a.name.padRight(10)} ${_rp(n.read<int>('n')).padLeft(13)}');
    }
    final unpaid = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM invoices i WHERE i.imported = 1 AND '
          '(SELECT COALESCE(SUM(qty * price - discount), 0) FROM invoice_lines WHERE invoice_id = i.id) - i.discount <> '
          "(SELECT COALESCE(SUM(amount), 0) FROM cash_entries WHERE kind = 'payment' AND ref_id = i.id)",
        )
        .getSingle();
    print('\ninvoice import yang tidak lunas: ${unpaid.read<int>('n')}');
    expect(unpaid.read<int>('n'), 0);
  });
}
