import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/kontak/kontak_repo.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';
import 'package:garage_erp_desktop/modules/search_repo.dart';

void main() {
  test('cari global: invoice (no/plat/customer/HP), customer, produk', () async {
    final db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    addTearDown(db.close);
    final budi = await db.saveCustomer(
      CustomersCompanion.insert(
        name: 'BUDI SANTOSO',
        phone: const Value('081234567890'),
        plate: const Value('N 1234 AB'),
      ),
    );
    final led = await db.saveProduct(ProductsCompanion.insert(name: 'CANBUS LED', sku: const Value('CB/001')));
    await db.saveDoc(
      kind: DocKind.invoice,
      at: DateTime(2026, 10, 1),
      customerId: budi,
      plate: 'N 1234 AB',
      lines: [LineInput(productId: led, name: 'CANBUS LED', qty: 1, price: 1)],
    );

    final byPlate = await db.search('n 1234');
    expect((byPlate.docs.single.customer, byPlate.customers.single.name), ('BUDI SANTOSO', 'BUDI SANTOSO'));
    expect((await db.search('0812-3456')).customers.length, 1);
    expect((await db.search('4567890')).customers.length, 1); // potongan tengah/akhir no. HP
    expect((await db.search('B_DI')).isEmpty, true); // _ bukan wildcard
    expect((await db.search('%%')).isEmpty, true);
    expect((await db.search('+62 812 3456')).docs.length, 1);
    expect((await db.search('INV/00')).docs.single.doc.no, startsWith('INV/'));
    expect((await db.search('cb/0')).products.single.name, 'CANBUS LED');
    expect((await db.search('x')).isEmpty, true); // minimal 2 huruf
    expect((await db.search('tidak ada')).isEmpty, true);
  });
}
