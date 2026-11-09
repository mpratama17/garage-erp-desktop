import 'dart:convert';

import 'package:drift/drift.dart';

import '../../db/database.dart';
import '../biaya/biaya_repo.dart' show expenseKind;
import '../gaji/gaji_repo.dart' show salaryKind;
import '../kas/kas_repo.dart' show CashKind;
import '../kontak/kontak_repo.dart' show normalizePlate;
import '../penjualan/penjualan_repo.dart' show DocKind;
import 'riwayat_parser.dart';

/// Kategori pengeluaran di sheet → kategori Biaya client yang sudah ada (tidak pernah membuat kategori baru).
/// [oldSalary] = dicatat sebagai Gaji (jenis kas gaji, tanpa slip). [oldStockBuy] = Pembelian stok: uang keluar
/// ([CashKind.oldStock]) tapi bukan biaya di laba rugi, karena modal barang sudah ikut di tiap baris invoice lama.
/// Kategori sheet yang tidak terdaftar, atau kategori app yang tidak ditemukan → "Lain-lain".
const oldSalary = '#gaji', oldStockBuy = '#stok';
const oldExpenseCategories = <String, String>{
  'TRANSPORT': 'Transportasi',
  'ALAT BAHAN': 'Alat & Bahan Bengkel',
  'ALAT DAN BAHAN': 'Alat & Bahan Bengkel',
  'GAJI': oldSalary,
  'LEMBUR': oldSalary,
  'BPJS': 'BPJS',
  'MAKANAN MINUMAN': 'Makan & Minum',
  'ONGKIR': 'Ongkir',
  'LISTRIK': 'Listrik',
  'WIFI': 'Wifi',
  'WFI': 'Wifi',
  'AIR': 'Air',
  'ADMIN': 'Admin Bank',
  'IURAN': 'Iuran/Langganan',
  'LANGGANAN': 'Iuran/Langganan',
  'MBAK': 'ART',
  'SUMBANGAN': 'Sumbangan',
  'PINJAM': 'Lain-lain',
  '-': 'Lain-lain',
  'PROJECTOR': oldStockBuy,
  'KABEL': oldStockBuy,
  'LED': oldStockBuy,
  'SFL': oldStockBuy,
  'STICKER': oldStockBuy,
};

/// Tujuan kategori sheet untuk pratinjau.
String oldCategoryLabel(String sheetCategory) => switch (oldExpenseCategories[sheetCategory]) {
  oldSalary => 'Gaji',
  oldStockBuy => 'Pembelian stok (bukan biaya)',
  null => 'Lain-lain (tidak dikenal)',
  final c => c,
};

/// Nama rekening di sheet (huruf saja, kapital) → nama rekening di app. Yang belum ada dibuat saat import.
const _oldAccounts = {
  'TUNAI': 'Tunai',
  'MANDIRI': 'Mandiri',
  'BCA': 'BCA',
  'SHOPEEPAY': 'ShopeePay',
  'BANKJAGO': 'Bank Jago',
  'GOPAY': 'GoPay',
  'DANA': 'DANA',
};

final _nonLetters = RegExp('[^A-Z]'), _spaces = RegExp(r'\s+'), _nonAlnum = RegExp('[^A-Z0-9]');
String _letters(String s) => s.toUpperCase().replaceAll(_nonLetters, '');
String _key(String s) => s.toUpperCase().replaceAll(_spaces, ' ').trim();

/// Ringkasan hasil import (juga dipakai pratinjau/dry-run).
class OldImportResult {
  int invoices = 0, lines = 0, payments = 0, expenses = 0, salaries = 0, stockBuys = 0, skipped = 0;
  int customersCreated = 0, customersMatched = 0, productsMatched = 0;
  final accountsCreated = <String>[], placeholderProducts = <String>[];
  final problems = <String>[];
}

extension RiwayatRepo on AppDb {
  Future<bool> hasImportedData() async => (await customSelect(
    'SELECT EXISTS(SELECT 1 FROM invoices WHERE imported = 1) '
    'OR EXISTS(SELECT 1 FROM cash_entries WHERE imported = 1) AS x',
  ).getSingle()).read<bool>('x');

  /// Jumlah semua transaksi kas sebuah rekening (saldo = saldo awal + ini).
  Future<int> _cashSum(int accountId) async => (await customSelect(
    'SELECT COALESCE(SUM(amount), 0) AS n FROM cash_entries WHERE account_id = ?',
    variables: [Variable.withInt(accountId)],
  ).getSingle()).read<int>('n');

  /// Masukkan catatan lama ke app dalam satu transaksi (gagal = tidak ada yang tersimpan). Hanya baris bertanggal
  /// sebelum [before] (null = semua) — sejak tanggal itu sumbernya app, supaya tidak tercatat dua kali.
  /// Tidak mengubah customer/produk yang sudah ada dan tidak menggerakkan stok. Semua baris baru ditandai
  /// `imported` → bisa dibatalkan utuh dengan [undoOldImport].
  Future<OldImportResult> importOld(OldData data, {DateTime? before}) => transaction(() async {
    requireOwner();
    if (await hasImportedData()) throw ArgumentError('Sudah ada data hasil import — batalkan import itu dulu');
    // Saldo awal sebelum import disimpan: "Samakan saldo" sesudah import mengubahnya, batalkan import mengembalikan.
    final opening = {for (final a in await select(accounts).get()) '${a.id}': a.openingBalance};
    final res = OldImportResult()..problems.addAll(data.problems);
    bool keep(DateTime at) {
      final ok = before == null || at.isBefore(before);
      if (!ok) res.skipped++;
      return ok;
    }

    // --- rekening
    final accountIds = {for (final a in await select(accounts).get()) _letters(a.name): a.id};
    Future<int?> account(String raw) async {
      final name = _oldAccounts[_letters(raw)];
      if (name == null) return null;
      final k = _letters(name);
      if (accountIds[k] case final id?) return id;
      res.accountsCreated.add(name);
      final id = accountIds[k] = await into(accounts).insert(AccountsCompanion.insert(name: name));
      opening['$id'] = 0;
      return id;
    }

    // --- kategori biaya: hanya kategori yang sudah ada (milik client).
    final catIds = {for (final c in await select(expenseCategories).get()) _key(c.name): c.id};
    final other = catIds[_key('Lain-lain')] ?? (throw ArgumentError('Kategori Biaya "Lain-lain" tidak ditemukan'));

    // --- produk: nama sama persis (tanpa beda huruf/spasi) → produk itu; selain itu produk penampung bernama
    // kelompok barang dari sheet (mis. "FL"), nonaktif, tidak tampil di Gudang/kasir/cari. Kategorinya hanya diisi
    // bila kelompok itu sama persis dengan kategori produk yang sudah ada (tidak menambah kategori baru); selain
    // itu kosong ("Tanpa kategori" di Laporan). Nama barang asli tetap tersimpan di baris invoice.
    final existingProducts = await select(products).get();
    final productIds = {for (final p in existingProducts) _key(p.name): p.id};
    final productCats = {
      for (final p in existingProducts)
        if (p.category.isNotEmpty) _key(p.category): p.category,
    };
    // Penampung dicari terpisah dari produk asli: produk asli yang kebetulan bernama "LED" tidak ikut menampung.
    final placeholders = <String, int>{};
    Future<int> placeholder(String name, {required bool service}) async {
      if (placeholders[_key(name)] case final id?) return id;
      res.placeholderProducts.add(name);
      return placeholders[_key(name)] = await into(products).insert(
        ProductsCompanion.insert(
          name: name,
          category: Value(productCats[_key(name)] ?? ''),
          isService: Value(service),
          active: const Value(false),
          imported: const Value(true),
        ),
      );
    }

    Future<int> noDetail() => placeholder('Penjualan', service: true);

    Future<int> product(OldLine l) async {
      if (productIds[_key(l.name)] case final id?) {
        res.productsMatched++;
        return id;
      }
      final group = l.group.isEmpty ? 'Lain-lain' : l.group;
      return placeholder(group, service: _key(group).contains('JASA'));
    }

    // --- customer: plat sama → customer itu; nama + mobil sama → customer itu; selain itu customer baru.
    // Lebih aman dobel daripada salah gabung. Customer lama tidak diubah (import bisa dibatalkan utuh).
    final existing = await select(customers).get();
    final byPlate = {
      for (final c in existing)
        if (c.plate.trim().isNotEmpty) _plate(c.plate): c.id,
    };
    final byNameCar = {for (final c in existing) '${_key(c.name)}|${_key(c.car)}': c.id};
    Future<int?> customer(OldInvoice v) async {
      if (v.customer.isEmpty) return null; // UMUM
      final plate = _plate(v.plate);
      final nameCar = '${_key(v.customer)}|${_key(v.car)}';
      final found = (plate.isEmpty ? null : byPlate[plate]) ?? byNameCar[nameCar];
      if (found != null) {
        res.customersMatched++;
        return found;
      }
      res.customersCreated++;
      final id = await into(customers).insert(
        CustomersCompanion.insert(
          name: v.customer,
          car: Value(v.car),
          plate: Value(normalizePlate(v.plate)),
          imported: const Value(true),
        ),
      );
      if (plate.isNotEmpty) byPlate[plate] = id;
      return byNameCar[nameCar] = id;
    }

    // --- invoice: total = uang yang diterima menurut sheet. Selisih dengan jumlah barang jadi diskon invoice,
    // atau (bila sheet menerima lebih) satu baris "Penjualan" senilai selisihnya. Lunas (Σbayar = total), jatuh tempo =
    // tanggal invoice, tanpa gerak stok (transaksi lama). Nomor L/yyMM/nnn, tidak memakai urutan INV.
    final seq = <String, int>{};
    for (final v in data.invoices..sort((a, b) => a.at.compareTo(b.at))) {
      if (!keep(v.at)) continue;
      final ym = '${v.at.year % 100}'.padLeft(2, '0') + '${v.at.month}'.padLeft(2, '0');
      final no = 'L/$ym/${'${seq[ym] = (seq[ym] ?? 0) + 1}'.padLeft(3, '0')}';
      final where = '${v.sheet} baris ${v.row}';
      final lines = <(int, String, int, int, int?)>[
        for (final l in v.lines) (await product(l), l.name, l.qty, l.price, l.cost),
      ];
      final total = v.payments.isEmpty ? v.subtotal - v.sheetDiscount : v.total;
      if (lines.isEmpty) {
        lines.add((await noDetail(), 'Penjualan', 1, total, null));
        res.problems.add('$where: uang masuk tanpa rincian barang — dicatat 1 baris "Penjualan"');
      }
      final subtotal = lines.fold(0, (s, l) => s + l.$3 * l.$4);
      var discount = subtotal - total;
      if (discount < 0) {
        lines.add((await noDetail(), 'Penjualan', 1, -discount, 0));
        res.problems.add('$where: total sheet lebih besar dari jumlah barang — selisihnya dicatat 1 baris "Penjualan"');
        discount = 0;
      } else if (v.lines.isNotEmpty && discount != v.sheetDiscount) {
        res.problems.add('$where: diskon disesuaikan supaya total sama dengan sheet');
      }
      final id = await into(invoices).insert(
        InvoicesCompanion.insert(
          kind: DocKind.invoice,
          no: no,
          at: v.at,
          dueAt: Value(v.at),
          customerId: Value(await customer(v)),
          car: Value(v.car),
          plate: Value(v.plate),
          legacy: const Value(true),
          note: Value('Import catatan lama ($where)'),
          discount: Value(discount),
          imported: const Value(true),
        ),
      );
      res.invoices++;
      for (final (productId, name, qty, price, cost) in lines) {
        await into(invoiceLines).insert(
          InvoiceLinesCompanion.insert(
            invoiceId: id,
            productId: productId,
            name: name,
            qty: qty,
            price: price,
            cost: Value(cost),
          ),
        );
        res.lines++;
      }
      // Rekening pembayaran tak dikenal (bukan nama rekening) → rekening pembayaran utama invoice ini,
      // teks aslinya disimpan di catatan.
      int? main;
      for (final p in v.payments) {
        main ??= await account(p.account);
      }
      for (final p in v.payments) {
        final acc = await account(p.account);
        if (acc == null) res.problems.add('$where: rekening "${p.account}" tidak dikenal — dicatat ke rekening utama');
        final accountId = acc ?? main ?? await account('Tunai');
        await into(cashEntries).insert(
          CashEntriesCompanion.insert(
            at: v.at,
            accountId: accountId!,
            amount: p.amount,
            kind: 'payment',
            refId: Value(id),
            description: 'Pembayaran $no${v.customer.isEmpty ? '' : ' — ${v.customer}'}',
            note: Value(acc == null ? 'Tertulis: ${p.account}' : ''),
            imported: const Value(true),
          ),
        );
        res.payments++;
      }
    }

    // --- pengeluaran
    for (final e in data.expenses..sort((a, b) => a.at.compareTo(b.at))) {
      if (!keep(e.at)) continue;
      final where = '${e.sheet} baris ${e.row}';
      var acc = await account(e.account);
      if (acc == null) {
        res.problems.add('$where: rekening "${e.account}" tidak dikenal — dicatat ke Tunai');
        acc = await account('Tunai');
      }
      final target = oldExpenseCategories[e.category];
      int? catId;
      if (target != oldSalary && target != oldStockBuy) {
        catId = target == null ? null : catIds[_key(target)];
        if (catId == null) {
          res.problems.add('$where: kategori "${e.category}" tidak dikenal — dicatat ke Lain-lain');
          catId = other;
        }
      }
      final kind = switch (target) {
        oldSalary => salaryKind,
        oldStockBuy => CashKind.oldStock,
        _ => expenseKind,
      };
      await into(cashEntries).insert(
        CashEntriesCompanion.insert(
          at: e.at,
          accountId: acc!,
          amount: -e.amount,
          kind: kind,
          refId: Value(catId),
          description: e.name.isEmpty ? '(tanpa nama)' : e.name,
          note: Value(e.qty.isEmpty ? '' : 'Jumlah: ${e.qty}'),
          imported: const Value(true),
        ),
      );
      switch (kind) {
        case CashKind.oldStock:
          res.stockBuys++;
        case salaryKind:
          res.salaries++;
        default:
          res.expenses++;
      }
    }
    await setSetting(_openingKey, jsonEncode(opening));
    return res;
  });

  /// Tanggal transaksi app (bukan hasil import) paling awal; null = belum ada.
  Future<DateTime?> firstAppTransaction() async {
    final r = await customSelect(
      'SELECT MIN(at) AS at FROM (SELECT at FROM invoices WHERE imported = 0 '
      'UNION ALL SELECT at FROM cash_entries WHERE imported = 0)',
      readsFrom: {invoices, cashEntries},
    ).getSingle();
    final v = r.data['at'];
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch((v as int) * 1000);
  }

  /// Jumlah data transaksi yang akan terhapus oleh [wipeTransactions] (untuk konfirmasi).
  Future<Map<String, int>> transactionCounts() async {
    Future<int> n(String sql) async => (await customSelect(sql).getSingle()).read<int>('n');
    return {
      'Invoice & pemesanan': await n('SELECT COUNT(*) AS n FROM invoices'),
      'Catatan kas (pembayaran, biaya, transfer, modal, gaji)': await n('SELECT COUNT(*) AS n FROM cash_entries'),
      'Pembelian stok': await n('SELECT COUNT(*) AS n FROM purchases'),
      'Slip gaji': await n('SELECT COUNT(*) AS n FROM payslips'),
      'Gerak stok dari transaksi': await n(
        "SELECT COUNT(*) AS n FROM stock_moves WHERE kind NOT IN ('opening', 'adjust')",
      ),
    };
  }

  /// Kosongkan semua transaksi (owner) — mis. data percobaan sebelum dipakai sungguhan. Produk, stok awal &
  /// opname, customer, karyawan, rekening, kategori, dan pengaturan tetap. Nomor nota berikutnya tidak diubah.
  Future<void> wipeTransactions() => transaction(() async {
    requireOwner();
    for (final t in ['invoice_lines', 'cash_entries', 'invoices', 'purchases', 'payslips']) {
      await customStatement('DELETE FROM $t');
    }
    await customStatement("DELETE FROM stock_moves WHERE kind NOT IN ('opening', 'adjust')");
    // Sisa import catatan lama (customer & produk penampung) ikut bersih → import ulang tidak dobel.
    await customStatement('DELETE FROM customers WHERE imported = 1');
    await customStatement('DELETE FROM products WHERE imported = 1 AND id NOT IN (SELECT product_id FROM stock_moves)');
    await setSetting(_openingKey, '');
  });

  /// Saldo tiap rekening menurut app sekarang (saldo awal + semua transaksi).
  Future<Map<Account, int>> accountBalances() async => {
    for (final a in await select(accounts).get()) // juga nonaktif: catatan lama bisa masuk ke sana
      a: a.openingBalance + await _cashSum(a.id),
  };

  /// Samakan saldo dengan saldo nyata hari ini (owner): saldo awal = saldo nyata − semua transaksi rekening itu.
  /// Dipakai setelah import catatan lama (pindah dana antar rekening di catatan lama tidak tercatat, jadi saldo
  /// per rekening tidak bisa dihitung maju). Total kas per hari tetap benar; saldo per rekening di masa lalu perkiraan.
  Future<void> setActualBalances(Map<int, int> actual) => transaction(() async {
    requireOwner();
    for (final MapEntry(key: id, value: real) in actual.entries) {
      final sum = await _cashSum(id);
      await (update(
        accounts,
      )..where((a) => a.id.equals(id))).write(AccountsCompanion(openingBalance: Value(real - sum)));
    }
  });

  /// Hapus semua hasil import (owner): invoice + baris + pembayarannya, biaya, gaji & pembelian stok lama, lalu
  /// customer & produk penampung buatan import yang tidak dipakai transaksi lain. Rekening yang dibuat import
  /// (nama rekening dari catatan client) dibiarkan.
  Future<void> undoOldImport() => transaction(() async {
    requireOwner();
    // Saldo awal rekening yang ada saat import kembali seperti sebelum import (rekening buatan import → 0);
    // rekening yang dibuat sesudahnya tidak disentuh.
    final saved = await setting(_openingKey);
    if (saved.isNotEmpty) {
      for (final MapEntry(:key, :value) in (jsonDecode(saved) as Map<String, dynamic>).entries) {
        await (update(
          accounts,
        )..where((x) => x.id.equals(int.parse(key)))).write(AccountsCompanion(openingBalance: Value(value as int)));
      }
      await setSetting(_openingKey, '');
    }
    const importedDocs = 'SELECT id FROM invoices WHERE imported = 1';
    await customStatement(
      "DELETE FROM cash_entries WHERE imported = 1 OR (kind IN ('payment', 'refund') AND ref_id IN ($importedDocs))",
    );
    await customStatement('DELETE FROM invoice_lines WHERE invoice_id IN ($importedDocs)');
    await (delete(invoices)..where((i) => i.imported)).go();
    await customStatement(
      'DELETE FROM customers WHERE imported = 1 AND id NOT IN (SELECT customer_id FROM invoices WHERE customer_id IS NOT NULL)',
    );
    await customStatement(
      'DELETE FROM products WHERE imported = 1 AND id NOT IN (SELECT product_id FROM invoice_lines) '
      'AND id NOT IN (SELECT product_id FROM stock_moves)',
    );
  });
}

const _openingKey = 'import_opening_balances';

String _plate(String s) => s.toUpperCase().replaceAll(_nonAlnum, '');
