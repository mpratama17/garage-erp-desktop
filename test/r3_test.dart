// Masukan client R3: vendor, tanggal lunas pembelian, biaya berulang, migrasi skema v2 → v3.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/biaya/biaya_repo.dart';
import 'package:garage_erp_desktop/modules/gaji/gaji_repo.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';
import 'package:garage_erp_desktop/modules/kontak/kontak_repo.dart';
import 'package:garage_erp_desktop/modules/laporan/akuntansi_repo.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as raw;

void main() {
  late AppDb db;
  late int tunai;
  final d = DateTime(2026, 10, 20);

  setUp(() async {
    db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    tunai = (await (db.select(db.accounts)..where((a) => a.name.equals('Tunai'))).getSingle()).id;
  });
  tearDown(() => db.close());

  Future<int> barang() => db.saveProduct(ProductsCompanion.insert(name: 'LED', sellPrice: const Value(100)));

  test('pembelian dengan nama vendor baru membuat vendor; nama sama (beda huruf) memakai vendor yang sama', () async {
    final p = await barang();
    Future<int> beli(String supplier) => db.recordPurchase(
      at: d,
      accountId: tunai,
      supplier: supplier,
      lines: [PurchaseLine(productId: p, qty: 1, unitCost: 10)],
    );
    await beli('Toko Jaya');
    await beli('  toko   jaya ');
    await beli('');
    final vendors = await db.watchVendors().first;
    expect(vendors.map((v) => v.name), ['Toko Jaya']);
    final rows = await db.select(db.purchases).get();
    expect(rows.map((x) => x.vendorId), [vendors.single.id, vendors.single.id, null]);
    expect(rows.map((x) => x.supplier), ['Toko Jaya', 'Toko Jaya', '']); // ejaan baku vendor
  });

  test(
    'vendor: nama unik (tanpa beda huruf), ganti nama ikut ke pembelian lama, hapus ditolak bila sudah dipakai',
    () async {
      final a = await db.saveVendor(VendorsCompanion.insert(name: 'Toko A'));
      await db.saveVendor(VendorsCompanion.insert(name: 'Toko B'));
      expect(() => db.saveVendor(VendorsCompanion.insert(name: 'toko a')), throwsArgumentError);
      expect(() => db.saveVendor(VendorsCompanion.insert(name: '  ')), throwsArgumentError);
      final p = await barang();
      await db.recordPurchase(
        at: d,
        accountId: tunai,
        supplier: 'Toko A',
        lines: [PurchaseLine(productId: p, qty: 1, unitCost: 10)],
      );
      await db.saveVendor(VendorsCompanion(id: Value(a), name: const Value('Toko A Baru')));
      expect((await db.select(db.purchases).getSingle()).supplier, 'Toko A Baru');
      expect(() => db.deleteVendor(a), throwsArgumentError);
      final b = (await db.watchVendors().first).firstWhere((v) => v.name == 'Toko B').id;
      await db.deleteVendor(b); // belum dipakai
      expect((await db.watchVendors().first).length, 1);
    },
  );

  test(
    'hak akses: kasir (terkunci) boleh catat biaya berulang; tambah/ubah/hapus vendor & kelola templat khusus owner',
    () async {
      final v = await db.saveVendor(VendorsCompanion.insert(name: 'Toko Z'));
      final cat = (await db.watchCategories().first).first.id;
      final t = await db.saveRecurring(
        RecurringExpensesCompanion.insert(
          name: 'Transport',
          categoryId: cat,
          accountId: tunai,
          amount: 20000,
          perEmployee: const Value(false),
        ),
      );
      db.ownerUnlocked = false;
      expect(() => db.saveVendor(VendorsCompanion(id: Value(v), name: const Value('Toko Z2'))), throwsArgumentError);
      expect(() => db.saveVendor(VendorsCompanion.insert(name: 'Toko Baru')), throwsArgumentError);
      expect(await db.recordRecurring(t, d), 1); // boleh: nominal sudah ditetapkan owner di templat
      expect(() => db.deleteVendor(v), throwsA(anything));
      expect(
        () => db.saveRecurring(
          RecurringExpensesCompanion.insert(name: 'X', categoryId: cat, accountId: tunai, amount: 1),
        ),
        throwsA(anything),
      );
      expect(() => db.journal(), throwsA(anything));
    },
  );

  test('riwayat pembelian mencatat tanggal lunas (beda hari dengan tanggal beli)', () async {
    final p = await barang();
    final id = await db.recordPurchase(
      at: d,
      accountId: tunai,
      paidNow: false,
      lines: [PurchaseLine(productId: p, qty: 1, unitCost: 10)],
    );
    expect((await db.watchPurchases().first).single.paidAt, isNull);
    await db.payPurchase(id, at: DateTime(2026, 10, 25));
    final row = (await db.watchPurchases().first).single;
    expect(row.paid, true);
    expect(row.paidAt, DateTime(2026, 10, 25));
  });

  group('biaya berulang', () {
    late int cat;
    late int budi, andi;
    setUp(() async {
      cat = (await db.watchCategories().first).firstWhere((c) => c.name == 'Transportasi').id;
      budi = await db.saveEmployee(EmployeesCompanion.insert(name: 'Budi', role: 'teknisi'));
      andi = await db.saveEmployee(EmployeesCompanion.insert(name: 'Andi', role: 'teknisi'));
    });

    Future<int> template({bool perEmployee = true}) => db.saveRecurring(
      RecurringExpensesCompanion.insert(
        name: 'Uang transport',
        categoryId: cat,
        accountId: tunai,
        amount: 20000,
        perEmployee: Value(perEmployee),
      ),
    );

    test('satu biaya per pegawai yang dicentang, masuk kas sebagai pengeluaran', () async {
      final t = await template();
      expect(await db.recordRecurring(t, d, employeeIds: [budi, andi]), 2);
      final rows = await db.watchExpenses(from: DateTime(2026, 10), to: DateTime(2026, 11)).first;
      expect(rows.map((r) => (r.entry.description, r.amount)).toSet(), {
        ('Uang transport — Budi', 20000),
        ('Uang transport — Andi', 20000),
      });
      expect((await db.watchBalances().first).firstWhere((b) => b.account.id == tunai).balance, -40000);
    });

    test('tanpa pegawai ditolak; templat bukan per-pegawai mencatat satu biaya', () async {
      final per = await template();
      expect(() => db.recordRecurring(per, d), throwsArgumentError);
      // Pegawai nonaktif / tidak dikenal ditolak di repo (bukan cuma disembunyikan di dialog); tidak ada yang tercatat.
      await (db.update(
        db.employees,
      )..where((e) => e.id.equals(andi))).write(const EmployeesCompanion(active: Value(false)));
      expect(() => db.recordRecurring(per, d, employeeIds: [budi, andi]), throwsArgumentError);
      expect(() => db.recordRecurring(per, d, employeeIds: [999]), throwsArgumentError);
      final single = await template(perEmployee: false);
      expect(await db.recordRecurring(single, d), 1);
      expect((await db.watchExpenses(from: DateTime(2026, 10), to: DateTime(2026, 11)).first).length, 1);
    });

    test('templat nonaktif tidak bisa dicatat; kelola templat khusus owner; nominal harus > 0', () async {
      final t = await template();
      await db.saveRecurring(
        RecurringExpensesCompanion(
          id: Value(t),
          name: const Value('Uang transport'),
          categoryId: Value(cat),
          accountId: Value(tunai),
          amount: const Value(20000),
          active: const Value(false),
        ),
      );
      expect(() => db.recordRecurring(t, d, employeeIds: [budi]), throwsArgumentError);
      expect(
        () => db.saveRecurring(
          RecurringExpensesCompanion.insert(name: 'X', categoryId: cat, accountId: tunai, amount: 0),
        ),
        throwsArgumentError,
      );
      db.ownerUnlocked = false;
      expect(() => template(), throwsA(anything));
    });
  });

  test('migrasi v2 → v3: vendor dibuat dari nama supplier lama dan pembelian lama ditautkan', () async {
    final sql = raw.sqlite3.openInMemory();
    // Bangun skema penuh lalu mundurkan ke bentuk v2 (tanpa vendors, recurring_expenses, kolom baru).
    final first = AppDb(NativeDatabase.opened(sql, closeUnderlyingOnClose: false));
    await first.customSelect('SELECT 1').get();
    await first.close();
    sql.execute('PRAGMA foreign_keys = OFF');
    sql.execute('DROP TABLE vendors');
    sql.execute('DROP TABLE recurring_expenses');
    sql.execute('ALTER TABLE employees DROP COLUMN phone');
    sql.execute('ALTER TABLE employees DROP COLUMN note');
    sql.execute('ALTER TABLE purchases RENAME TO purchases_new');
    sql.execute(
      'CREATE TABLE purchases (id INTEGER PRIMARY KEY AUTOINCREMENT, at INTEGER NOT NULL, '
      "supplier TEXT NOT NULL DEFAULT '', account_id INTEGER NOT NULL REFERENCES accounts (id), "
      "total INTEGER NOT NULL, note TEXT NOT NULL DEFAULT '', bill_no TEXT NOT NULL DEFAULT '', "
      "proof_path TEXT NOT NULL DEFAULT '')",
    );
    sql.execute('DROP TABLE purchases_new');
    for (final s in ['Toko Jaya', 'toko jaya ', '', 'CV Lampu']) {
      sql.execute("INSERT INTO purchases (at, supplier, account_id, total) VALUES (0, '$s', 1, 100)");
    }
    sql.execute('PRAGMA user_version = 2');

    final migrated = AppDb(NativeDatabase.opened(sql));
    addTearDown(migrated.close);
    final vendors = await migrated.watchVendors().first;
    expect(vendors.map((v) => v.name).toSet(), {'Toko Jaya', 'CV Lampu'});
    final byId = {for (final v in vendors) v.id: v.name};
    final linked = [for (final p in await migrated.select(migrated.purchases).get()) byId[p.vendorId]];
    expect(linked, ['Toko Jaya', 'Toko Jaya', null, 'CV Lampu']);
    expect(await migrated.select(migrated.recurringExpenses).get(), isEmpty); // tabel baru ada
  });
}
