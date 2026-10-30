// Masukan client R4: no. pembelian otomatis, migrasi skema v3 → v4. (SKU otomatis: gudang_test.)
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as raw;

void main() {
  final d = DateTime(2026, 10, 28);

  Future<int> beli(AppDb db, int productId, {int qty = 1}) async {
    final tunai = (await (db.select(db.accounts)..where((a) => a.name.equals('Tunai'))).getSingle()).id;
    return db.recordPurchase(
      at: d,
      accountId: tunai,
      lines: [PurchaseLine(productId: productId, qty: qty, unitCost: 100)],
    );
  }

  Future<String> noOf(AppDb db, int id) async =>
      (await (db.select(db.purchases)..where((p) => p.id.equals(id))).getSingle()).no;

  test('no. pembelian otomatis 0000400 dst; nomor terpakai dilewati; pembelian ditolak tidak memakan nomor', () async {
    final db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    addTearDown(db.close);
    final led = await db.saveProduct(ProductsCompanion.insert(name: 'LED', sellPrice: const Value(100)));

    expect(await noOf(db, await beli(db, led)), '0000400');
    expect(await noOf(db, await beli(db, led)), '0000401');

    await expectLater(beli(db, led, qty: 0), throwsArgumentError); // ditolak sebelum mengambil nomor
    await db.setSetting('next_purchase_no', '401'); // nomor awal dimundurkan di Pengaturan
    expect(await noOf(db, await beli(db, led)), '0000402');
    expect(await db.setting('next_purchase_no'), '403');
  });

  test('migrasi v3 → v4: pembelian lama tanpa nomor, pembelian baru mulai 0000400', () async {
    final sql = raw.sqlite3.openInMemory();
    final first = AppDb(NativeDatabase.opened(sql, closeUnderlyingOnClose: false));
    await first.customSelect('SELECT 1').get();
    await first.close();
    sql.execute('ALTER TABLE purchases DROP COLUMN no');
    sql.execute("INSERT INTO products (name) VALUES ('LED')");
    sql.execute('INSERT INTO purchases (at, account_id, total) VALUES (0, 1, 100)');
    sql.execute('PRAGMA user_version = 3');

    final db = AppDb(NativeDatabase.opened(sql))..ownerUnlocked = true;
    addTearDown(db.close);
    final old = await db.select(db.purchases).getSingle();
    expect(old.no, '');
    final p = await db.select(db.products).getSingle();
    expect(await noOf(db, await beli(db, p.id)), '0000400');
  });
}
