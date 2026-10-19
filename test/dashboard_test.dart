import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/dashboard/dashboard_repo.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';

void main() {
  test('dashboard: omzet per hari/bulan (tanpa batal & pemesanan) dan terlaris — tanpa PIN owner', () async {
    final db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    addTearDown(db.close);
    final led = await db.saveProduct(ProductsCompanion.insert(name: 'LED'));
    final jasa = await db.saveProduct(ProductsCompanion.insert(name: 'Pasang', isService: const Value(true)));
    Future<int> inv(DateTime at, List<LineInput> lines, {String kind = DocKind.invoice}) =>
        db.saveDoc(kind: kind, at: at, lines: lines);
    await inv(DateTime(2026, 10, 2, 10), [
      LineInput(productId: led, name: 'LED', qty: 2, price: 100000, discount: 10000),
    ]);
    await inv(DateTime(2026, 10, 2, 15), [LineInput(productId: jasa, name: 'Pasang', qty: 1, price: 50000)]);
    await inv(DateTime(2026, 9, 30), [LineInput(productId: led, name: 'LED', qty: 1, price: 100000)]);
    await inv(DateTime(2026, 10, 3), [LineInput(productId: led, name: 'LED', qty: 9, price: 1)], kind: DocKind.order);
    final batal = await inv(DateTime(2026, 10, 3), [LineInput(productId: led, name: 'LED', qty: 9, price: 1)]);
    await db.voidDoc(batal, 'salah');
    db.ownerUnlocked = false; // angka operasional boleh dilihat kasir

    final days = await db.salesSeries(DateTime(2026, 10, 1), DateTime(2026, 10, 4));
    expect(days.map((p) => (p.start.day, p.omzet, p.invoices)), [(1, 0, 0), (2, 240000, 2), (3, 0, 0)]);
    final months = await db.salesSeries(DateTime(2026, 9), DateTime(2026, 11), monthly: true);
    expect(months.map((p) => (p.start.month, p.omzet)), [(9, 100000), (10, 240000)]);
    final top = await db.topItems(DateTime(2026, 10), DateTime(2026, 11));
    expect(top, [(name: 'LED', qty: 2, omzet: 190000), (name: 'Pasang', qty: 1, omzet: 50000)]);
  });
}
