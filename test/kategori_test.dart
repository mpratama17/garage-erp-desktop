// Kategori produk (v5): tambah dari form / Kelola kategori, ganti nama ikut ke produk, hapus ditolak bila dipakai.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/gudang/product_form.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as raw;

void main() {
  Future<List<({String name, int count})>> cats(AppDb db) => db.productCategoriesQuery().get();

  Future<int> produk(AppDb db, String name, String category) =>
      db.saveProduct(ProductsCompanion.insert(name: name, category: Value(category)));

  Future<String> categoryOf(AppDb db, int id) async =>
      (await (db.select(db.products)..where((p) => p.id.equals(id))).getSingle()).category;

  test('daftar = kategori produk ∪ kategori kosong; kembar beda huruf ditolak / dipakai ejaan lama', () async {
    final db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    addTearDown(db.close);
    await produk(db, 'Canbus', 'LED');
    await produk(db, 'Canbus 15', 'LED');
    await db.addProductCategory('  Strobo ');

    expect(await cats(db), [(name: 'LED', count: 2), (name: 'Strobo', count: 0)]);
    await expectLater(db.addProductCategory('led'), throwsArgumentError);
    await expectLater(db.addProductCategory('STROBO'), throwsArgumentError);
    await expectLater(db.addProductCategory('  '), throwsArgumentError);

    // Ketik "led" di form produk → tersimpan "LED" (huruf apa adanya hanya untuk kategori baru).
    expect(await categoryOf(db, await produk(db, 'Bohlam', 'led ')), 'LED');
    expect(await categoryOf(db, await produk(db, 'Sirine', 'sirine')), 'sirine');
  });

  test('ganti nama: produk ikut pindah; nama lain yang sudah ada ditolak', () async {
    final db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    addTearDown(db.close);
    final a = await produk(db, 'Canbus', 'LED');
    final b = await produk(db, 'Bohlam', 'led'); // tersimpan "LED"
    await db.addProductCategory('Strobo');

    await expectLater(db.renameProductCategory('LED', 'strobo'), throwsArgumentError);
    await db.renameProductCategory('LED', 'Lampu LED');
    expect(await categoryOf(db, a), 'Lampu LED');
    expect(await categoryOf(db, b), 'Lampu LED');

    await db.renameProductCategory('Strobo', 'STROBO'); // ganti huruf saja boleh
    expect(await cats(db), [(name: 'Lampu LED', count: 2), (name: 'STROBO', count: 0)]);
  });

  test('pilihan kategori: sama persis → diawali → mengandung; nama baru di akhir (Enter memilih teratas)', () {
    const cats = ['FOGLAMP LED', 'Lampu LED', 'LED', 'LED Strip'];
    expect(categoryOptions(cats, 'led'), ['LED', 'LED Strip', 'FOGLAMP LED', 'Lampu LED']);
    expect(categoryOptions(cats, 'lamp'), ['Lampu LED', 'FOGLAMP LED', 'lamp']);
    expect(categoryOptions(cats, ' Strobo '), ['Strobo']);
    expect(categoryOptions(cats, ''), cats);
  });

  test('form produk tahu ada perubahan yang belum disimpan (konfirmasi sebelum panel ditutup paksa)', () async {
    final db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    addTearDown(db.close);
    final id = await produk(db, 'Canbus', 'LED');
    final f = ProductFields(await (db.select(db.products)..where((p) => p.id.equals(id))).getSingle());
    addTearDown(f.dispose);
    expect(f.dirty, isFalse);
    f.sell.text = '180.000';
    expect(f.dirty, isTrue);
    f.sell.text = '0'; // kembali ke isi semula
    expect(f.dirty, isFalse);
    f.active = false;
    expect(f.dirty, isTrue);
  });

  test('import Excel memakai ejaan kategori yang sudah ada (produk baru & produk lama)', () async {
    final db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    addTearDown(db.close);
    final a = await produk(db, 'Canbus', 'LED');
    await db.applyImport([
      ProductRow(rowNo: 2, name: 'Canbus', category: ' led'),
      ProductRow(rowNo: 3, name: 'Bohlam', category: 'Led'),
    ]);
    expect(await categoryOf(db, a), 'LED');
    expect(await cats(db), [(name: 'LED', count: 2)]);
  });

  test('hapus ditolak bila masih dipakai; tanpa PIN owner semua ditolak', () async {
    final db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    addTearDown(db.close);
    await produk(db, 'Canbus', 'LED');
    await db.addProductCategory('Strobo');

    await expectLater(db.deleteProductCategory('LED'), throwsArgumentError);
    await db.deleteProductCategory('Strobo');
    expect(await cats(db), [(name: 'LED', count: 1)]);

    db.ownerUnlocked = false;
    await expectLater(db.addProductCategory('Sirine'), throwsArgumentError);
    await expectLater(db.renameProductCategory('LED', 'X'), throwsArgumentError);
    await expectLater(db.deleteProductCategory('LED'), throwsArgumentError);
  });

  test('migrasi v4 → v5: tabel kategori dibuat; kategori lama dirapikan (spasi, varian huruf digabung)', () async {
    final sql = raw.sqlite3.openInMemory();
    final first = AppDb(NativeDatabase.opened(sql, closeUnderlyingOnClose: false));
    await first.customSelect('SELECT 1').get();
    await first.close();
    sql.execute('DROP TABLE product_categories');
    for (final t in ['invoices', 'cash_entries', 'customers', 'products']) {
      sql.execute('ALTER TABLE $t DROP COLUMN imported'); // kolom v6
    }
    sql.execute("INSERT INTO products (name, category) VALUES ('Canbus', 'LED'), ('Lama', 'Led'), ('Spasi', ' LED ')");
    sql.execute('PRAGMA user_version = 4');

    final db = AppDb(NativeDatabase.opened(sql))..ownerUnlocked = true;
    addTearDown(db.close);
    await db.addProductCategory('Strobo');
    expect(await cats(db), [(name: 'LED', count: 3), (name: 'Strobo', count: 0)]);
  });
}
