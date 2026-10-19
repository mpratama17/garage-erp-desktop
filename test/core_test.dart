import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_erp_flutter/db.dart';
import 'package:workshop_erp_flutter/money.dart';

void main() {
  test('terbilang & money', () {
    expect(terbilang(2250000), 'Dua Juta Dua Ratus Lima Puluh Ribu Rupiah');
    expect(terbilang(1115000), 'Satu Juta Seratus Lima Belas Ribu Rupiah');
    expect(terbilang(11000), 'Sebelas Ribu Rupiah');
    expect(lineTotal(2, 1000000, 10), 1800000);
    expect(ppnOf(2250000), 247500);
    expect(normalizePhone('\n0812 3456-7890'), '081234567890');
    expect(normalizePhone('+62 812 345'), '0812345');
  });

  late AppDb db;
  setUp(() => db = AppDb(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Product> add(String name, ProductType t, int price) async {
    final id = await db.into(db.products).insert(
        ProductsCompanion.insert(name: name, type: t, sellPrice: price));
    return (db.select(db.products)..where((p) => p.id.equals(id))).getSingle();
  }

  test('paket mengurangi stok komponen, HPP, void mengembalikan stok', () async {
    final lens = await add('Hyperion Prime', ProductType.barang, 2250000);
    final bulb = await add('LED H4', ProductType.barang, 300000);
    final pasang = await add('Jasa pasang', ProductType.jasa, 150000);
    final paket = await add('Paket Prime', ProductType.paket, 2600000);
    await db.setBundle(paket.id, {lens.id: 2, bulb.id: 1});

    await db.recordPurchase('Supp A', [
      (productId: lens.id, qty: 4, unitCost: 1500000),
      (productId: bulb.id, qty: 10, unitCost: 100000),
    ]);
    await db.recordPurchase('Supp B', [(productId: lens.id, qty: 4, unitCost: 1700000)]);
    expect(await db.avgCost(lens.id), 1600000);
    expect(await db.unitCost(paket), 2 * 1600000 + 100000);

    await db.setSetting('last_invoice_no', '246');
    final cust = await db.upsertCustomer('BUDI', '081100002222');
    expect(await db.upsertCustomer('Budi', '0811-0000-2222'), cust);

    final inv = await db.createInvoice(
      lines: [CartLine(paket), CartLine(pasang), CartLine(lens, discountPct: 10)],
      payMethod: 'Transfer', customerId: cust, plate: 'n 1234 ab', ppn: true,
    );
    expect(inv.no, 'INV/00247');
    expect(inv.plate, 'N 1234 AB');
    expect(inv.subtotal, 2600000 + 150000 + 2025000);
    expect(inv.total, inv.subtotal + ppnOf(inv.subtotal));
    expect(await db.stockOf(lens.id), 8 - 3);
    expect(await db.stockOf(bulb.id), 9);
    expect(await db.stockOf(pasang.id), 0);

    await db.voidInvoice(inv.id, 'salah input');
    await db.voidInvoice(inv.id, 'dobel klik'); // idempotent
    expect(await db.stockOf(lens.id), 8);
    expect(await db.stockOf(bulb.id), 10);

    final next = await db.createInvoice(lines: [CartLine(pasang)], payMethod: 'Cash');
    expect(next.no, 'INV/00248');
    expect(() => db.createInvoice(lines: [], payMethod: 'Cash'), throwsArgumentError);
  });
}
