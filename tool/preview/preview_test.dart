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
import 'package:workshop_erp_flutter/modules/kontak/kontak_repo.dart';
import 'package:workshop_erp_flutter/modules/penjualan/penjualan_repo.dart';

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
  for (final (name, phone, car, plate) in [
    ('BUDI SANTOSO', '081100002222', 'TOYOTA INNOVA', 'N 1234 AB'),
    ('SITI AMINAH', '081100003333', 'HONDA BRIO', ''),
    ('WALK-IN TANPA HP', null, '', ''),
  ]) {
    await db.saveCustomer(
      CustomersCompanion.insert(name: name, phone: Value(phone), car: Value(car), plate: Value(plate)),
    );
  }
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

  // Penjualan contoh
  final t1 = await db.into(db.employees).insert(EmployeesCompanion.insert(name: 'Teknisi A', role: 'teknisi'));
  final t2 = await db.into(db.employees).insert(EmployeesCompanion.insert(name: 'Teknisi B', role: 'teknisi'));
  final all = await db.watchProducts().first;
  final barang = all.firstWhere((s) => !s.isService && s.stock > 0).product;
  final jasa = all.firstWhere((s) => s.isService).product;
  final custs = await db.watchCustomers().first;
  final budi = custs.firstWhere((c) => c.name == 'BUDI SANTOSO');
  final siti = custs.firstWhere((c) => c.name == 'SITI AMINAH');
  final bca = (await db.select(db.accounts).get()).first.id;
  final now = DateTime.now();
  LineInput b() =>
      LineInput(productId: barang.id, name: barang.name, qty: 1, price: barang.sellPrice, tech1Id: t1, tech2Id: t2);
  LineInput j() => LineInput(productId: jasa.id, name: jasa.name, qty: 1, price: jasa.sellPrice, tech1Id: t1);
  await db.saveDoc(
    kind: DocKind.invoice,
    at: now.subtract(const Duration(days: 40)),
    customerId: budi.id,
    lines: [j()],
    payNow: PaymentInput(accountId: bca, amount: jasa.sellPrice, at: now),
  );
  await db.saveDoc(
    kind: DocKind.invoice,
    at: now,
    dueAt: now.add(const Duration(days: 30)),
    customerId: budi.id,
    car: budi.car,
    plate: budi.plate,
    lines: [b(), j()],
    payNow: PaymentInput(accountId: bca, amount: barang.sellPrice + jasa.sellPrice, at: now),
  );
  await db.saveDoc(
    kind: DocKind.invoice,
    at: now,
    dueAt: now.add(const Duration(days: 30)),
    customerId: siti.id,
    car: siti.car,
    lines: [b()],
    payNow: PaymentInput(accountId: bca, amount: barang.sellPrice ~/ 2, at: now),
  );
  await db.saveDoc(
    kind: DocKind.invoice,
    at: now.subtract(const Duration(days: 45)),
    dueAt: now.subtract(const Duration(days: 15)),
    lines: [j()],
  );
  await db.saveDoc(
    kind: DocKind.order,
    at: now,
    customerId: siti.id,
    lines: [b(), j()],
    payNow: PaymentInput(accountId: bca, amount: jasa.sellPrice, at: now),
  );
}

void main() {
  testWidgets('layar', (tester) async {
    final db = Get.put((AppDb(NativeDatabase.memory())..ownerUnlocked = true));
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

    await tester.tap(find.text('Penjualan').first);
    await settle();
    await shot('penjualan');
    await tester.tap(find.text('INV/00248'));
    await settle();
    await shot('penjualan-panel');
    await tester.tap(find.text('Kasir / Invoice'));
    await settle();
    await shot('penjualan-kasir');
    await tester.tap(find.text('Batal').last);
    await settle();

    await tester.tap(find.text('Kontak'));
    await settle();
    await tester.tap(find.text('BUDI SANTOSO').last);
    await settle();
    await shot('kontak');

    await tester.tap(find.text('Pengaturan'));
    await settle();
    await shot('pengaturan');

    owner.lock(); // hentikan timer auto-lock
    await tester.runAsync(db.close);
  });
}
