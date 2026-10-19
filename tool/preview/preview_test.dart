// Render layar ke PNG untuk review visual (bukan test CI):
//   flutter test tool/preview --update-goldens
// Bila docs/GUDANG BARANG new.xlsx ada (lokal), produknya dipakai sebagai data contoh.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Value;
import 'package:intl/date_symbol_data_local.dart';
import 'package:workshop_erp_flutter/core/owner.dart';
import 'package:workshop_erp_flutter/db/database.dart';
import 'package:workshop_erp_flutter/main.dart';
import 'package:workshop_erp_flutter/modules/gudang/gudang_repo.dart';

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
  }
  await inter.load();
  final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _seed(AppDb db) async {
  await db.setSetting('shop_name', 'Star Garage');
  await db.setSetting('backup_dir', '/Users/kasir/Documents/Workshop ERP Backup'); // path_provider tidak ada di test
  final file = File('docs/GUDANG BARANG new.xlsx');
  if (file.existsSync()) await db.applyImport(parseProductsXlsx(file.readAsBytesSync()).rows);
  final items = await db.watchProducts().first;
  final cb =
      items.where((s) => s.product.sku == 'CB/002').firstOrNull?.product.id ??
      await db.saveProduct(
        ProductsCompanion.insert(name: 'CANBUS LED 15', sku: const Value('CB/002'), sellPrice: const Value(200000)),
        openingStock: 1,
      );
  await db.adjustStock(cb, 0, 'stok opname: rusak');
  for (final (name, price, inc) in [('Cleaning Coating', 350000, 100000), ('Setting Sinar', 1000000, 50000)]) {
    await db.saveProduct(
      ProductsCompanion.insert(
        name: name,
        isService: const Value(true),
        sellPrice: Value(price),
        incentive: Value(inc),
        category: const Value('JASA'),
      ),
    );
  }
}

void main() {
  testWidgets('layar', (tester) async {
    final db = Get.put(AppDb(NativeDatabase.memory()));
    final owner = Get.put(OwnerController(db));
    await tester.runAsync(() async {
      await initializeDateFormatting('id');
      await _loadFonts();
      await _seed(db);
    });
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;

    Future<void> settle() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
    }

    Future<void> shot(String name) => expectLater(find.byType(App), matchesGoldenFile('$name.png'));

    await tester.pumpWidget(const App());
    await settle();
    await shot('shell');

    await tester.tap(find.text('Gudang'));
    await settle();
    await shot('gudang');

    owner.isOwner.value = true;
    await tester.tap(find.text('CANBUS LED 15'));
    await settle();
    await shot('gudang-panel');

    await tester.tap(find.text('Jasa').first);
    await settle();
    await shot('gudang-jasa');

    await tester.tap(find.text('Pengaturan'));
    await settle();
    await shot('pengaturan');

    owner.lock(); // hentikan timer auto-lock
    await tester.runAsync(db.close);
  });
}
