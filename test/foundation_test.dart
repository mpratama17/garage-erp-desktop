import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/core/format.dart';
import 'package:garage_erp_desktop/db/database.dart';

void main() {
  test('format Rupiah, terbilang, no. HP', () {
    expect(rupiah(2250000), 'Rp 2.250.000');
    expect(parseRupiah('Rp 2.250.000'), 2250000);
    expect(parseRupiah(''), 0);
    expect(terbilang(2250000), 'Dua Juta Dua Ratus Lima Puluh Ribu Rupiah');
    expect(terbilang(2800000), 'Dua Juta Delapan Ratus Ribu Rupiah');
    expect(terbilang(11000), 'Sebelas Ribu Rupiah');
    expect(terbilang(-50000), "Minus Lima Puluh Ribu Rupiah");
    expect(normalizePhone('\n0812 3456-7890'), '081234567890');
    expect(normalizePhone('+62 812 345'), '0812345');
    expect(displayPhone('081234567890'), '0812-3456-7890');
  });

  late AppDb db;
  setUp(() => db = AppDb(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('rekening awal: BCA, Mandiri, ShopeePay, Tunai', () async {
    final names = (await db.select(db.accounts).get()).map((a) => a.name);
    expect(names, defaultAccounts);
  });

  test('nomor nota melanjutkan nomor terakhir', () async {
    expect(await db.takeNumber('next_invoice_no', 'INV'), 'INV/00247');
    expect(await db.takeNumber('next_invoice_no', 'INV'), 'INV/00248');
    expect(await db.takeNumber('next_so_no', 'SO'), 'SO/00013');
  });

  test('PIN disimpan sebagai hash dan bisa dicek', () async {
    expect(await db.hasPin(), false);
    expect(await db.checkPin('1234'), false);
    await db.setPin('1234');
    expect(await db.hasPin(), true);
    expect(await db.setting('pin_hash'), isNot(contains('1234')));
    expect(await db.checkPin('1234'), true);
    expect(await db.checkPin('4321'), false);
  });

  test('backup menghasilkan salinan database yang bisa dibuka', () async {
    final dir = await Directory.systemTemp.createTemp('backup_test');
    addTearDown(() => dir.delete(recursive: true));
    await db.setSetting('shop_name', 'Bengkel Uji');

    final f = await db.backupTo(dir.path);
    final copy = AppDb(NativeDatabase(f));
    addTearDown(copy.close);
    expect(await copy.setting('shop_name'), 'Bengkel Uji');
    expect(await db.setting('last_backup_at'), isNotEmpty);

    // autoBackup (jadwal default): tidak dua kali di hari yang sama, kecuali saat app ditutup.
    await db.setSetting('backup_dir', dir.path);
    expect(await db.backupDir(), dir.path);
    await db.autoBackup();
    expect(dir.listSync().length, 1);
    await db.autoBackup(closing: true);
    expect(dir.listSync().length, 2);
    await db.setSetting('backup_schedule', 'off');
    await db.autoBackup(closing: true);
    expect(dir.listSync().length, 2);
  });

  test('jadwal backup otomatis', () {
    final now = DateTime(2026, 10, 20, 9);
    final today = DateTime(2026, 10, 20, 7),
        yesterday = DateTime(2026, 10, 19, 23),
        weekAgo = DateTime(2026, 10, 13, 9);
    expect(backupDue('close', today, now), false);
    expect(backupDue('close', today, now, closing: true), true);
    expect(backupDue('daily', today, now, closing: true), false);
    expect(backupDue('daily', yesterday, now), true);
    expect(backupDue('weekly', yesterday, now, closing: true), false);
    expect(backupDue('weekly', weekAgo, now), true);
    expect(backupDue('off', null, now, closing: true), false);
    expect(backupDue('daily', null, now), true);
  });

  test('DB lama (versi 1 tanpa tabel modul baru) mendapat tabel baru saat dibuka', () async {
    final dir = await Directory.systemTemp.createTemp('old_db');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/old.sqlite');
    final old = AppDb(NativeDatabase(file));
    await old.setSetting('shop_name', 'Bengkel Lama');
    await old.customStatement('DROP TABLE products'); // tiru DB dari Modul 0
    await old.close();

    final now = AppDb(NativeDatabase(file));
    addTearDown(now.close);
    expect(await now.select(now.products).get(), isEmpty); // tidak "no such table"
    expect(await now.setting('shop_name'), 'Bengkel Lama'); // data lama utuh
  });
}
