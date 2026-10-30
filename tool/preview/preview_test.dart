// Render layar ke PNG untuk review visual (bukan test CI):
//   flutter test tool/preview --update-goldens
// Semua data contoh fiktif (jangan pakai file/logo client: hasilnya masuk docs/screenshots).
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Value;
import 'package:intl/date_symbol_data_local.dart';
import 'package:garage_erp_desktop/core/owner.dart';
import 'package:garage_erp_desktop/core/ui.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/main.dart';
import 'package:garage_erp_desktop/modules/biaya/biaya_repo.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';
import 'package:garage_erp_desktop/modules/kontak/kontak_repo.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';

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
  await db.setSetting('backup_dir', '/Users/kasir/Documents/Garage ERP Backup'); // path_provider tidak ada di test
  await db.setSetting('export_dir', Directory.systemTemp.createTempSync('export').path);
  // Katalog fiktif: screenshot masuk README/repo, jadi tidak boleh memakai file/logo/harga asli client.
  for (final (sku, name, cat, buy, sell, stock, min) in [
    ('LED/001', 'LAMPU LED H4 PUTIH', 'LED', 90000, 180000, 1, 3),
    ('LED/002', 'LAMPU LED H11 KUNING', 'LED', 85000, 170000, 6, 3),
    ('LED/003', 'LAMPU LED T10 SEN', 'LED', 15000, 35000, 12, 5),
    ('PRJ/001', 'PROJECTOR BI-LED 2.5"', 'PROJECTOR', 1400000, 2750000, 2, 2),
    ('PRJ/002', 'PROJECTOR LASER 3 WARNA', 'PROJECTOR', 1900000, 3750000, 3, 2),
    ('PRJ/003', 'PROJECTOR LASER DOUBLE', 'PROJECTOR', 2700000, 5500000, 2, 2),
    ('FOG/001', 'FOGLAMP 3 COLORS', 'FOGLAMP', 450000, 900000, 4, 2),
    ('FOG/002', 'FOGLAMP HALOGEN', 'FOGLAMP', 120000, 250000, 8, 3),
    ('AKS/001', 'KABEL RELAY 40A', 'AKSESORIS', 25000, 60000, 15, 5),
    ('AKS/002', 'SOKET H4 KERAMIK', 'AKSESORIS', 12000, 30000, 20, 5),
    ('AKS/003', 'LENSA PELINDUNG KACA', 'AKSESORIS', 40000, 90000, 1, 3),
  ]) {
    await db.saveProduct(
      ProductsCompanion.insert(
        sku: Value(sku),
        name: name,
        category: Value(cat),
        buyPrice: Value(buy),
        sellPrice: Value(sell),
        minStock: Value(min),
      ),
      openingStock: stock,
    );
  }
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
  Future<int> emp(String name, String role, int base) => db
      .into(db.employees)
      .insert(
        EmployeesCompanion.insert(name: name, role: role, baseSalary: Value(base), mealAllowance: const Value(300000)),
      );
  final t1 = await emp('Teknisi A', 'teknisi', 2000000);
  final t2 = await emp('Teknisi B', 'teknisi', 2000000);
  await emp('Sales A', 'sales', 1500000);
  final all = await db.watchProducts().first;
  final barang = all.firstWhere((s) => !s.isService && s.stock > 0).product;
  final jasa = all.firstWhere((s) => s.isService).product;
  final custs = await db.watchCustomers().first;
  final budi = custs.firstWhere((c) => c.name == 'BUDI SANTOSO');
  final siti = custs.firstWhere((c) => c.name == 'SITI AMINAH');
  final bca = (await db.select(db.accounts).get()).first.id;
  final now = DateTime.now();
  final canbus = all.firstWhere((s) => s.product.name == 'CANBUS LED 15').product;
  await db.recordPurchase(
    at: now.subtract(const Duration(days: 3)),
    accountId: bca,
    supplier: 'Toko Lampu Jaya',
    billNo: 'NOTA-0912',
    note: 'Nota 0912',
    lines: [
      PurchaseLine(productId: canbus.id, qty: 4, unitCost: 95000),
      PurchaseLine(productId: barang.id, qty: 2, unitCost: barang.buyPrice),
    ],
  );
  await db.recordPurchase(
    at: now.subtract(const Duration(days: 1)),
    accountId: bca,
    supplier: 'CV Aksesoris',
    billNo: 'NOTA-0988',
    paidNow: false,
    lines: [PurchaseLine(productId: canbus.id, qty: 2, unitCost: 95000)],
  );
  LineInput b() => LineInput(
    productId: barang.id,
    name: barang.name,
    qty: 1,
    price: barang.sellPrice,
    incentive: 50000,
    tech1Id: t1,
    tech2Id: t2,
  );
  LineInput j() =>
      LineInput(productId: jasa.id, name: jasa.name, qty: 1, price: jasa.sellPrice, incentive: 100000, tech1Id: t1);
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
    discountPct: 5,
    taxPct: 11,
    payNow: PaymentInput(accountId: bca, amount: barang.sellPrice + jasa.sellPrice, at: now),
  );
  // BUDI pernah bawa mobil lain: riwayat mobil/plat tampil di Kontak.
  await db.saveDoc(
    kind: DocKind.invoice,
    at: now.subtract(const Duration(days: 10)),
    customerId: budi.id,
    car: 'HONDA JAZZ',
    plate: 'N 5678 CD',
    lines: [j()],
    payNow: PaymentInput(accountId: bca, amount: jasa.sellPrice, at: now),
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

  // Kas contoh
  final acc = {for (final a in await db.select(db.accounts).get()) a.name: a.id};
  await (db.update(db.accounts)..where((a) => a.id.equals(acc['BCA']!))).write(
    const AccountsCompanion(openingBalance: Value(15000000), note: Value('a.n. contoh')),
  );
  await (db.update(
    db.accounts,
  )..where((a) => a.id.equals(acc['Tunai']!))).write(const AccountsCompanion(openingBalance: Value(800000)));
  await db.addIncome(
    accountId: acc['Tunai']!,
    amount: 2000000,
    at: now.subtract(const Duration(days: 3)),
    kind: CashKind.capital,
    description: 'Modal dari owner',
  );
  await db.transfer(
    fromId: acc['BCA']!,
    toId: acc['ShopeePay']!,
    amount: 500000,
    at: now.subtract(const Duration(days: 1)),
    note: 'top up belanja part',
    // Punya bukti sekaligus bisa dihapus (owner): kolom aksi menampilkan 2 ikon — cek tidak meluber.
    proofPath: '/tmp/contoh-bukti.jpg',
  );

  // Biaya contoh
  final cat = {for (final k in await db.watchCategories().first) k.name: k.id};
  for (final (c, name, amount, days, account) in [
    ('Listrik', 'Token listrik bengkel', 500000, 2, 'Tunai'),
    ('Makan & Minum', 'Makan siang teknisi', 75000, 1, 'Tunai'),
    ('Ongkir', 'Kirim part ke Malang', 45000, 1, 'ShopeePay'),
    ('Rumah (Listrik/Air/Wifi)', 'Wifi rumah', 350000, 4, 'BCA'),
  ]) {
    await db.saveExpense(
      at: now.subtract(Duration(days: days)),
      accountId: acc[account]!,
      categoryId: cat[c]!,
      description: name,
      amount: amount,
    );
  }
}

void main() {
  testWidgets('layar', (tester) async {
    // flutter_test menggambar bayangan sebagai garis hitam; tampilkan bayangan asli seperti di app.
    debugDisableShadows = false;
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
    await shot('dashboard');
    // Panel menu diciutkan → rail ikon saja.
    await tester.tap(find.byKey(const Key('sidebar_toggle_button')));
    await settle();
    await shot('sidebar-rail');
    await tester.tap(find.byKey(const Key('sidebar_toggle_button')));
    await settle();
    owner.isOwner.value = true;
    await settle();
    await shot('dashboard-owner');
    await tester.tap(find.text('Harian'));
    await settle();
    await shot('dashboard-owner-harian');
    await tester.tap(find.text('Bulanan'));
    await settle();
    await tester.tap(find.byIcon(Icons.date_range_outlined));
    await settle();
    await shot('dashboard-rentang-dialog');
    await tester.tap(find.text('Batal'));
    await settle();
    owner.isOwner.value = false;
    await settle();
    // Ukuran jendela minimum (design.md §4).
    tester.view.physicalSize = const Size(1280, 720);
    await settle();
    await shot('dashboard-1280');
    tester.view.physicalSize = const Size(1440, 900);
    await settle();

    // Cari global: ketik → hasil berkelompok → pilih customer = buka di Kontak.
    await tester.tap(find.byType(SearchBar));
    await settle();
    await tester.enterText(find.byType(TextField).last, 'budi');
    await settle();
    await shot('cari');
    await tester.tap(find.text('BUDI SANTOSO').last);
    await settle();
    await shot('cari-buka');
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await settle();
    await shot('kontak-riwayat-mobil');

    await tester.tap(find.text('Gudang'));
    await settle();
    await shot('gudang');

    owner.isOwner.value = true;
    await tester.tap(find.text('CANBUS LED 15'));
    await settle();
    await shot('gudang-panel');
    await tester.drag(find.byType(ListView).last, const Offset(0, -800));
    await settle();
    await shot('gudang-riwayat');

    await tester.tap(find.text('Jasa').first);
    await settle();
    await shot('gudang-jasa');

    // Pembelian (halaman sendiri): riwayat, rincian, tagihan.
    await tester.tap(find.text('Pembelian').first);
    await settle();
    await shot('pembelian');
    await tester.tap(find.text('Toko Lampu Jaya'));
    await settle();
    await shot('pembelian-lunas');
    await tester.tap(find.text('CV Aksesoris'));
    await settle();
    await shot('pembelian-belum-bayar');
    await tester.tap(find.widgetWithText(FilledButton, 'Pembelian stok'));
    await settle();
    await shot('pembelian-dialog');
    // R4 #5: barang baru dari dialog pembelian (form Gudang, tanpa stok awal), langsung jadi baris pembelian.
    await tester.tap(find.text('Barang baru'));
    await settle();
    final buyDialog = find.byType(AlertDialog).last;
    await tester.enterText(find.descendant(of: buyDialog, matching: find.byType(TextField)).first, 'CANBUS LED 20');
    await tester.enterText(find.descendant(of: buyDialog, matching: find.byType(TextField)).at(5), '90000');
    await settle();
    await shot('pembelian-barang-baru');
    await tester.tap(find.descendant(of: buyDialog, matching: find.text('Simpan')));
    await settle();
    await shot('pembelian-barang-baru-tersimpan');
    // Stok barang baru = qty pembelian saja (tidak ada stok awal yang ikut terhitung).
    await tester.enterText(
      find.descendant(of: find.widgetWithText(Labeled, 'Qty'), matching: find.byType(TextField)),
      '3',
    );
    await tester.tap(find.text('Simpan pembelian'));
    await settle();
    final stock = await tester.runAsync(() async {
      final p = await (db.select(db.products)..where((x) => x.name.equals('CANBUS LED 20'))).getSingle();
      return db.stockOf(p.id);
    });
    expect(stock, 3);
    await settle();
    await tester.tap(find.text('Tagihan Pembelian'));
    await settle();
    await shot('pembelian-tagihan');

    await tester.tap(find.text('Penjualan').first);
    await settle();
    await shot('tagihan');
    await tester.tap(find.text('INV/00248'));
    await settle();
    await shot('tagihan-panel');
    await tester.tap(find.text('+ Tagihan'));
    await settle();
    await shot('tagihan-kasir');
    // Pilihan produk invoice: barang stok 0 tidak ditawarkan.
    await tester.enterText(find.widgetWithText(TextField, 'Cari barang / jasa…'), 'h');
    await settle();
    await shot('tagihan-pilih-produk');
    FocusManager.instance.primaryFocus?.unfocus(); // tutup daftar pilihan
    await settle();
    final wasOwner = owner.isOwner.value;
    owner.isOwner.value = true; // tanpa PIN di preview
    await tester.tap(find.text('Barang/jasa baru'));
    await settle();
    await shot('tagihan-produk-baru');
    final dialog = find.byType(AlertDialog);
    // R4 #1–2: form lengkap; SKU ditebak dari produk yang mirip (CANBUS → CB/003).
    await tester.enterText(find.descendant(of: dialog, matching: find.byType(TextField)).first, 'CANBUS LED BARU');
    await tester.enterText(find.descendant(of: dialog, matching: find.byType(TextField)).at(4), '150000');
    await settle();
    await shot('tagihan-produk-baru-isi');
    await tester.tap(find.descendant(of: dialog, matching: find.text('Simpan')));
    await settle();
    await shot('tagihan-produk-baru-tersimpan'); // baris kosong diganti produk baru (harga terisi)
    owner.isOwner.value = wasOwner;
    await tester.tap(find.text('Batal').last);
    await settle();
    await tester.tap(find.text('Pemesanan').first);
    await settle();
    await shot('pemesanan');

    await tester.tap(find.text('Kas & Bank'));
    await settle();
    await shot('kas');
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await settle();
    await shot('kas-scroll');
    await tester.drag(find.byType(ListView).last, const Offset(0, 400));
    await settle();
    await tester.tap(find.text('BCA').first);
    await settle();
    await shot('kas-bca');
    // Urut per kolom + tombol Reset.
    await tester.tap(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await settle();
    await shot('kas-urut');
    await tester.tap(find.text('Reset'));
    await settle();
    await tester.tap(find.text('Arus kas'));
    await settle();
    await shot('kas-arus');

    await tester.tap(find.text('Biaya').first);
    await settle();
    await shot('biaya');
    await tester.tap(find.text('Token listrik bengkel'));
    await settle();
    await shot('biaya-ubah');
    // Ubah biaya: menu kategori tetap menampilkan semua kategori (filter baru jalan saat mengetik).
    await tester.tap(find.byType(DropdownMenu<int>));
    await settle();
    await shot('biaya-ubah-kategori');
    await tester.tap(find.byIcon(Icons.arrow_drop_up));
    await settle();
    // Hapus = konfirmasi dengan tombol merah berlabel jelas.
    await tester.tap(find.widgetWithText(DangerButton, 'Hapus'));
    await settle();
    await shot('konfirmasi-hapus');
    await tester.tap(find.text('Batal').last);
    await settle();
    // Simpan = notifikasi sukses.
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan').last);
    await settle();
    await shot('notif-sukses');
    await tester.pump(const Duration(seconds: 9)); // biarkan notifikasi hilang sendiri
    // Isian kurang = notifikasi "periksa lagi" (bukan error sistem).
    await tester.tap(find.widgetWithText(FilledButton, 'Biaya'));
    await settle();
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan').last);
    await settle();
    await shot('notif-peringatan');
    await tester.pump(const Duration(seconds: 9)); // biarkan notifikasi hilang sendiri
    // Kategori dicari dengan mengetik.
    await tester.tap(find.byType(DropdownMenu<int>));
    await settle();
    await tester.enterText(
      find.descendant(of: find.byType(DropdownMenu<int>), matching: find.byType(TextField)),
      'list',
    );
    await settle();
    await shot('biaya-cari-kategori');
    await tester.tap(find.text('Batal').last);
    await settle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Kategori'));
    await settle();
    await shot('biaya-kategori');
    await tester.tap(find.text('Selesai'));
    await settle();

    await tester.tap(find.text('Gaji').first);
    await settle();
    await shot('gaji');
    await tester.tap(find.text('Teknisi A').last);
    await settle();
    await shot('gaji-slip');
    await tester.tap(find.widgetWithText(FilledButton, 'Bayar'));
    // Tombol Bayar luar sengaja tetap berputar selama dialog bayar (nested) ini terbuka — pumpAndSettle
    // tidak akan pernah diam karena animasi spinner-nya, jadi pump durasi tetap di sini saja.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await shot('gaji-bayar-dialog');
    await tester.tap(find.text('Batal').last);
    await settle();
    await tester.tap(find.text('Batal').last);
    await settle();
    await tester.tap(find.text('Sales A').last);
    await settle();
    await shot('gaji-slip-sales');
    await tester.tap(find.text('Batal').last);
    await settle();

    await tester.tap(find.text('Laporan').first);
    await settle();
    await shot('laporan');
    await tester.tap(find.text('Penjualan').last);
    await settle();
    await shot('laporan-penjualan');
    await tester.tap(find.text('Terlaris'));
    await settle();
    await shot('laporan-terlaris');

    await tester.tap(find.text('Kontak'));
    await settle();
    await tester.tap(find.text('BUDI SANTOSO').last);
    await settle();
    await shot('kontak');

    await tester.tap(find.text('Pengaturan'));
    // Tanpa pumpAndSettle: preview nota (paket printing) butuh plugin native yang tidak ada di test → spinner.
    // Hasil PDF-nya dicek lewat pdf_preview_test.dart.
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 300));
    await shot('pengaturan');

    // Terakhir: Kas saat owner terkunci (saldo ••••). Tanpa pumpAndSettle — halaman owner lain
    // dibangun ulang & memuat data di zona test (spinner tak berujung).
    await tester.tap(find.text('Kas & Bank'));
    owner.lock(); // hentikan timer auto-lock
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await shot('kas-terkunci');
    debugDisableShadows = true; // wajib dikembalikan sebelum test selesai
    await tester.runAsync(db.close);
  });
}
