// Cek importer dengan file asli (lokal, tidak masuk CI):
//   IMPORT_FILE="docs/GUDANG BARANG new.xlsx" flutter test tool/check_import_test.dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_erp_flutter/db/database.dart';
import 'package:workshop_erp_flutter/modules/gudang/gudang_repo.dart';

void main() {
  test('import file asli', () async {
    final res = parseProductsXlsx(File(Platform.environment['IMPORT_FILE']!).readAsBytesSync());
    // ignore: avoid_print
    print('baris valid: ${res.rows.length}\nerror:\n  ${res.errors.join('\n  ')}');
    final db = AppDb(NativeDatabase.memory());
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
}
