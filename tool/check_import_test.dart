// Cek importer dengan file asli client (lokal, tidak masuk CI):
//   IMPORT_FILE="docs/GUDANG BARANG new.xlsx" flutter test tool/check_import_test.dart --name produk
//   IMPORT_FILE=customer.xlsx flutter test tool/check_import_test.dart --name customer
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/kontak/kontak_repo.dart';

void main() {
  test('produk', () async {
    final res = parseProductsXlsx(File(Platform.environment['IMPORT_FILE']!).readAsBytesSync());
    // ignore: avoid_print
    print('baris valid: ${res.rows.length}\nerror:\n  ${res.errors.join('\n  ')}');
    final db = (AppDb(NativeDatabase.memory())..ownerUnlocked = true);
    // ignore: avoid_print
    print('hasil: ${await db.applyImport(res.rows)}');
    final list = await db.watchProducts().first;
    for (final s in list.take(3)) {
      // ignore: avoid_print
      print(
        '${s.product.sku} | ${s.product.name} | ${s.product.category} | beli ${s.product.buyPrice} | jual ${s.product.sellPrice} | min ${s.product.minStock} | stok ${s.stock}',
      );
    }
    await db.close();
  });

  test('customer', () async {
    final res = parseCustomersXlsx(File(Platform.environment['IMPORT_FILE']!).readAsBytesSync());
    final db = (AppDb(NativeDatabase.memory())..ownerUnlocked = true);
    final r = await db.applyCustomerImport(res.rows);
    // ignore: avoid_print
    print(
      'valid ${res.rows.length}, hasil $r\nerror:\n  ${res.errors.join('\n  ')}\ndigabung:\n  ${res.merged.join('\n  ')}',
    );
    await db.close();
  });
}
