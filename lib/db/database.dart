import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Pengaturan key-value: info bengkel, nomor nota berikutnya, PIN, folder backup.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

/// Rekening kas/bank. Saldo = openingBalance + SUM(transaksi kas) — tidak disimpan.
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

const defaultAccounts = ['BCA', 'Mandiri', 'ShopeePay', 'Tunai'];

/// Buku kas: setiap uang masuk (+) / keluar (−) di satu rekening.
/// Diisi oleh modul lain (pembelian stok, pembayaran invoice, biaya, gaji, transfer).
class CashEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get amount => integer()();
  // purchase | payment (bayar/DP invoice, refId=invoices.id) | refund (balikan saat invoice batal)
  // | expense (refId=expense_categories.id) | salary | transfer | capital | income
  TextColumn get kind => text()();
  IntColumn get refId => integer().nullable()();
  TextColumn get description => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get proofPath => text().withDefault(const Constant(''))();
}

/// Barang & jasa. Stok tidak disimpan di sini: stok = SUM(stock_moves.qty).
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().nullable().unique()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get unit => text().withDefault(const Constant('PCS'))();
  BoolColumn get isService => boolean().withDefault(const Constant(false))();
  IntColumn get buyPrice => integer().withDefault(const Constant(0))(); // hanya owner
  IntColumn get sellPrice => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(0))();
  IntColumn get incentive => integer().withDefault(const Constant(0))(); // tarif insentif teknisi
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// Buku stok (hanya barang). kind: opening | purchase | sale | void | adjust.
class StockMoves extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get qty => integer()();
  TextColumn get kind => text()();
  IntColumn get refId => integer().nullable()();
  IntColumn get unitCost => integer().nullable()(); // harga beli saat pembelian
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Customer. No. HP dinormalisasi (08…) dan unik bila diisi — kunci dedupe.
/// Mobil & plat di sini = mobil utama; invoice menyimpan salinan mobil/plat per transaksi.
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable().unique()();
  TextColumn get car => text().withDefault(const Constant(''))();
  TextColumn get plate => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Karyawan (dikelola di modul Gaji). role: teknisi | sales.
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  IntColumn get baseSalary => integer().withDefault(const Constant(0))();
  IntColumn get mealAllowance => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// Invoice & pemesanan (kind: invoice | order) — satu tabel karena isi & barisnya sama.
/// Total, terbayar, dan status TIDAK disimpan: dihitung dari invoice_lines & cash_entries.
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get no => text().unique()(); // INV/00247 atau SO/00013
  DateTimeColumn get at => dateTime()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  TextColumn get car => text().withDefault(const Constant(''))(); // salinan saat transaksi
  TextColumn get plate => text().withDefault(const Constant(''))();
  IntColumn get orderId => integer().nullable()(); // pada invoice: pemesanan asalnya
  BoolColumn get legacy => boolean().withDefault(const Constant(false))(); // transaksi lama: tanpa gerak stok
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get isVoid => boolean().withDefault(const Constant(false))();
  TextColumn get voidReason => text().withDefault(const Constant(''))();
}

class InvoiceLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get name => text()(); // salinan nama saat transaksi
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get qty => integer()();
  IntColumn get price => integer()();
  IntColumn get discount => integer().withDefault(const Constant(0))(); // Rp, untuk seluruh baris
  IntColumn get cost => integer().nullable()(); // modal per unit, diisi owner (null = belum diisi)
  IntColumn get incentive => integer().withDefault(const Constant(0))(); // tarif per unit
  IntColumn get tech1Id => integer().nullable().references(Employees, #id)();
  IntColumn get tech2Id => integer().nullable().references(Employees, #id)();
}

/// Pembelian stok (owner). Baris & harga beli ada di stock_moves (kind=purchase, refId=id).
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get supplier => text().withDefault(const Constant(''))();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get total => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Kategori biaya. [personal] = pengeluaran rumah/pribadi: dicatat, tapi di laba rugi
/// tampil di bawah laba bersih usaha (bukan biaya operasional).
class ExpenseCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  BoolColumn get personal => boolean().withDefault(const Constant(false))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// Kategori awal dari sheet pengeluaran client (PRD BIA-2/BIA-3); `true` = pribadi.
const defaultExpenseCategories = {
  'Alat & Bahan Bengkel': false,
  'Listrik': false,
  'Air': false,
  'Wifi': false,
  'Transportasi': false,
  'Ongkir': false,
  'Makan & Minum': false,
  'Tukang/Servis': false,
  'Iuran/Langganan': false,
  'Admin Bank': false,
  'BPJS': false,
  'Bonus/THR': false,
  'Lain-lain': false,
  'Rumah (Listrik/Air/Wifi)': true,
  'PDAM Langgar': true,
  'Sumbangan': true,
  'ART': true,
  'Pribadi Lain-lain': true,
};

/// Nilai awal pengaturan (dipakai bila key belum pernah disimpan).
const settingDefaults = {
  'shop_name': 'Nama Bengkel',
  'shop_address': '',
  'shop_phone': '',
  'shop_email': '',
  'logo_path': '',
  'invoice_note': '',
  'gmaps_review_url': '',
  'next_invoice_no': '247',
  'next_so_no': '13',
  'payroll_start_day': '27',
  'sales_commission_pct': '3',
  'backup_dir': '',
  'last_backup_at': '',
  'pin_hash': '',
};

Future<File> dbFile() async => File(p.join((await getApplicationSupportDirectory()).path, 'garage_erp.sqlite'));

@DriftDatabase(
  tables: [
    Settings,
    Accounts,
    CashEntries,
    Products,
    StockMoves,
    Purchases,
    Customers,
    Employees,
    Invoices,
    InvoiceLines,
    ExpenseCategories,
  ],
)
class AppDb extends _$AppDb {
  AppDb([QueryExecutor? e])
    : super(
        e ??
            driftDatabase(
              name: 'garage_erp',
              native: DriftNativeOptions(databasePath: () async => (await dbFile()).path),
            ),
      );

  /// Mode owner aktif (PIN sudah dimasukkan). Diset oleh OwnerController; dicek oleh repo,
  /// sehingga aturan khusus owner tidak hanya hidup di UI.
  bool ownerUnlocked = false;

  void requireOwner() {
    if (!ownerUnlocked) throw ArgumentError('Butuh PIN owner');
  }

  /// Rekening untuk transaksi baru harus ada dan aktif.
  Future<Account> requireActiveAccount(int id) async {
    final a = await (select(accounts)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (a == null || !a.active) throw ArgumentError('Rekening tidak ditemukan atau nonaktif');
    return a;
  }

  // ponytail: tetap v1 sampai app terpasang di client; setelah itu tiap perubahan skema = migrasi.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final name in defaultAccounts) {
        await into(accounts).insert(AccountsCompanion.insert(name: name));
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // Selama pengembangan (schemaVersion tetap 1): tabel modul baru dibuat di DB yang sudah ada.
      // Aman diulang — drift memakai CREATE TABLE IF NOT EXISTS. Perubahan kolom tetap butuh migrasi.
      if (!details.wasCreated) await Migrator(this).createAll();
      if (await (select(expenseCategories)..limit(1)).getSingleOrNull() == null) {
        await batch(
          (b) => b.insertAll(expenseCategories, [
            for (final e in defaultExpenseCategories.entries)
              ExpenseCategoriesCompanion.insert(name: e.key, personal: Value(e.value)),
          ]),
        ); // satu transaksi: tidak tersisa separuh bila app mati di tengah
      }
    },
  );

  // ---- settings ----
  Future<String> setting(String key) async =>
      (await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value ??
      settingDefaults[key] ??
      '';

  Future<Map<String, String>> allSettings() async => {
    ...settingDefaults,
    for (final r in await select(settings).get()) r.key: r.value,
  };

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  /// Ambil nomor berikutnya (mis. 'next_invoice_no' -> "INV/00247") lalu naikkan.
  Future<String> takeNumber(String key, String prefix) => transaction(() async {
    final n = int.parse(await setting(key));
    await setSetting(key, '${n + 1}');
    return '$prefix/${n.toString().padLeft(5, '0')}';
  });

  // ---- PIN owner ----
  static String _hash(String salt, String pin) => sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<bool> hasPin() async => (await setting('pin_hash')).isNotEmpty;

  Future<void> setPin(String pin) {
    final salt = base64Url.encode(List.generate(16, (_) => Random.secure().nextInt(256)));
    return setSetting('pin_hash', '$salt\$${_hash(salt, pin)}');
  }

  Future<bool> checkPin(String pin) async {
    final stored = await setting('pin_hash');
    final i = stored.indexOf('\$');
    return i > 0 && _hash(stored.substring(0, i), pin) == stored.substring(i + 1);
  }

  // ---- backup ----
  /// Salin database (snapshot konsisten) ke [dir]; simpan 60 file terbaru.
  // ponytail: retensi per jumlah file, bukan per hari; cukup untuk ±1 bulan pemakaian normal.
  Future<File> backupTo(String dir, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    final stamp = t.toIso8601String().substring(0, 23).replaceAll(RegExp('[:.]'), '-');
    final out = File(p.join(dir, 'garage_erp-$stamp.sqlite'));
    await Directory(dir).create(recursive: true);
    await customStatement('VACUUM INTO ?', [out.path]);
    final old =
        Directory(dir).listSync().whereType<File>().where((f) => p.basename(f.path).startsWith('garage_erp-')).toList()
          ..sort((a, b) => b.path.compareTo(a.path));
    for (final f in old.skip(60)) {
      f.deleteSync();
    }
    await setSetting('last_backup_at', t.toIso8601String());
    return out;
  }

  /// Folder backup: pilihan owner, atau default lokal ~/Documents/Garage ERP Backup.
  // ponytail: backup lokal saja (keputusan client); salin ke Google Drive/flashdisk menyusul.
  Future<String> backupDir() async {
    final dir = await setting('backup_dir');
    if (dir.isNotEmpty) return dir;
    return p.join((await getApplicationDocumentsDirectory()).path, 'Garage ERP Backup');
  }

  /// Backup otomatis: sekali sehari, dan setiap app ditutup ([force]).
  Future<void> autoBackup({bool force = false}) async {
    final dir = await backupDir();
    final last = DateTime.tryParse(await setting('last_backup_at'));
    final today = DateTime.now();
    final sameDay = last != null && last.year == today.year && last.month == today.month && last.day == today.day;
    if (!force && sameDay) return;
    await backupTo(dir);
  }
}
