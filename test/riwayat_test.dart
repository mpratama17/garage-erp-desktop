// Import catatan lama (spreadsheet client) — semua data di sini fiktif.
import 'dart:convert';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/core/xlsx_values.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gaji/gaji_repo.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';
import 'package:garage_erp_desktop/modules/laporan/akuntansi_repo.dart';
import 'package:garage_erp_desktop/modules/laporan/laporan_repo.dart';
import 'package:garage_erp_desktop/modules/riwayat/riwayat_parser.dart';
import 'package:garage_erp_desktop/modules/riwayat/riwayat_repo.dart';

/// Sel rumus dengan hasil tersimpan (seperti file dari Google Sheets/Excel).
class F {
  const F(this.cached);
  final num cached;
}

/// Teks rich text: beberapa potongan `<r><t>` dalam satu `<si>`.
class Rich {
  const Rich(this.parts);
  final List<String> parts;
}

String _col(int c) => c < 26 ? String.fromCharCode(65 + c) : _col(c ~/ 26 - 1) + String.fromCharCode(65 + c % 26);
double _serial(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1899, 12, 30)).inDays.toDouble();

/// .xlsx minimal buatan tangan. Urutan file sheet sengaja dibalik dari urutan sheet (relasi harus dibaca).
List<int> xlsx(Map<String, List<List<Object?>>> sheets) {
  final shared = <String>[];
  final zip = Archive();
  void put(String path, String xml) {
    final bytes = utf8.encode(xml);
    zip.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  final names = sheets.keys.toList();
  for (final (i, name) in names.indexed) {
    final file = names.length - i; // dibalik
    final rows = StringBuffer();
    for (final (r, row) in sheets[name]!.indexed) {
      rows.write('<row r="${r + 1}">');
      for (final (c, v) in row.indexed) {
        final ref = '${_col(c)}${r + 1}';
        switch (v) {
          case null:
            break; // sel kosong tidak ditulis
          case F(:final cached):
            rows.write('<c r="$ref"><f>SUM(A1)</f><v>$cached</v></c>');
          case num():
            rows.write('<c r="$ref"><v>$v</v></c>');
          case DateTime():
            rows.write('<c r="$ref" s="1"><v>${_serial(v)}</v></c>');
          case Rich(:final parts):
            shared.add('<si>${parts.map((p) => '<r><t>$p</t></r>').join()}</si>');
            rows.write('<c r="$ref" t="s"><v>${shared.length - 1}</v></c>');
          case final String s when s.startsWith('inline:'):
            rows.write('<c r="$ref" t="inlineStr"><is><t>${s.substring(7)}</t></is></c>');
          default:
            shared.add('<si><t>$v</t></si>');
            rows.write('<c r="$ref" t="s"><v>${shared.length - 1}</v></c>');
        }
      }
      rows.write('</row>');
    }
    put('xl/worksheets/sheet$file.xml', '<worksheet><sheetData>$rows</sheetData></worksheet>');
  }
  const ns =
      'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
  put(
    'xl/workbook.xml',
    '<workbook $ns><sheets>'
        '${[for (final (i, n) in names.indexed) '<sheet name="$n" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join()}'
        '</sheets></workbook>',
  );
  put(
    'xl/_rels/workbook.xml.rels',
    '<Relationships>'
        '${[for (final (i, _) in names.indexed) '<Relationship Id="rId${i + 1}" Target="worksheets/sheet${names.length - i}.xml"/>'].join()}'
        '</Relationships>',
  );
  put('xl/sharedStrings.xml', '<sst>${shared.join()}</sst>');
  return ZipEncoder().encode(zip)!;
}

/// Satu baris sheet bulanan dari {kolom: nilai}.
List<Object?> row(Map<int, Object?> cells) => [for (var c = 0; c < 30; c++) cells[c]];

final header = row({
  0: 'TANGGAL',
  1: 'PLAT NOMOR',
  2: 'MOBIL',
  3: 'Pemilik',
  5: 'BARANG',
  14: 'TOTAL PENJUALAN',
  15: 'PEMBAYARAN',
  21: 'TANGGAL',
  22: 'PENGELUARAN',
  24: 'HARGA',
  25: 'KETERANGAN',
  26: 'DATA',
});
DateTime jan(int d) => DateTime(2025, 1, d);

/// Sheet bulanan fiktif: 4 invoice Januari (+1 Februari, setelah tanggal batas) & 6 pengeluaran.
final monthly = [
  header,
  // 1. customer lama (cocok plat), produk lama (cocok nama), jasa tanpa modal, diskon 70rb.
  row({
    0: jan(5),
    1: 'N 1234 AB',
    2: 'AVANZA',
    3: 'Budi',
    4: 'FL',
    5: 'LAMPU LED  H4',
    6: 2,
    7: 300000,
    9: 70000,
    10: 150000,
    14: const F(630000),
    15: 'BCA',
    17: 'TOTAL',
    18: const F(1780000),
    21: jan(6),
    22: 'Bensin',
    24: 20000,
    25: 'SHOPEEPAY',
    26: 'TRANSPORT',
    27: 'TOTAL PENGELUARAN',
    28: const F(1071000),
  }),
  row({
    4: 'JASA PASANG',
    5: 'Pasang lampu',
    6: 1,
    7: 100000,
    14: const F(0),
    21: jan(7),
    22: 'Stok lampu',
    23: 10,
    24: 1000000,
    25: 'BCA',
    26: 'PROJECTOR',
  }),
  // 2. customer baru, dibayar dua cara (yang kedua tertulis nama orang, bukan rekening).
  row({
    0: jan(10),
    2: 'JAZZ',
    3: const Rich(['Sa', 'ri']),
    4: 'SOKET',
    5: 'SOKET X',
    6: 1,
    7: 500000,
    10: 200000,
    14: const F(300000),
    15: 'BCA',
    21: jan(8),
    22: 'Sumbangan',
    24: 50000,
    25: 'TUNAI',
    26: 'SUMBANGAN',
  }),
  row({
    4: 'KABEL',
    5: 'inline:RELAY',
    6: 1,
    7: 100000,
    10: 50000,
    14: 300000,
    15: 'MAS ANU',
    21: jan(9),
    22: 'Aneh',
    24: 1000,
    25: 'TUNAI',
    26: 'XYZ',
  }),
  // 3. uang masuk tanpa rincian barang, rekening baru (tanda baca di namanya).
  row({
    0: jan(15),
    1: 'L 1 XY',
    14: const F(200000),
    15: 'BANK JAGO,',
    21: jan(9),
    22: 'Salah ketik',
    24: 'abc',
    25: 'TUNAI',
    26: 'LISTRIK',
  }),
  // 4. sheet menerima lebih dari jumlah barang → baris selisih.
  row({
    0: jan(20),
    1: 'n-1234-ab',
    3: 'Budi',
    4: 'FL',
    5: 'Lampu LED H4',
    6: 1,
    7: 300000,
    10: 150000,
    14: const F(350000),
    15: 'TUNAI',
    21: DateTime(2025, 2, 2),
    22: 'Setelah batas',
    24: 5000,
    25: 'TUNAI',
    26: 'TRANSPORT',
  }),
  // 5. setelah tanggal batas.
  row({
    0: DateTime(2025, 2, 1),
    3: 'Budi',
    4: 'FL',
    5: 'Lampu LED H4',
    6: 1,
    7: 300000,
    14: const F(300000),
    15: 'TUNAI',
  }),
  row({0: jan(31)}), // baris tanggal kosong (tidak ada barang/total) — bukan invoice
];

void main() {
  test('pembaca xlsx: hasil rumus, rich text, inline, sel kosong, urutan sheet lewat relasi', () {
    final x = XlsxValues.decode(
      xlsx({
        'JAN25': monthly,
        'UANG 2025': [
          row({0: 'NAMA AKUN'}),
        ],
      }),
    );
    expect(x.sheets.keys, ['JAN25', 'UANG 2025']);
    final r1 = x.sheets['JAN25']![1];
    expect(x.date(r1[0]), jan(5));
    expect(r1[14], 630000.0); // hasil rumus, bukan teks rumus
    expect(r1[8], isNull); // sel kosong di tengah
    expect(x.sheets['JAN25']![3][3], 'Sari');
    expect(x.sheets['JAN25']![4][5], 'RELAY');
    expect(() => XlsxValues.decode([1, 2, 3]), throwsFormatException);
  });

  test('parser: invoice, pembayaran kedua, uang tanpa rincian, pengeluaran, total sheet', () async {
    final bytes = xlsx({
      'JAN25': monthly,
      'UANG 2025': [row({})],
    });
    // Dijalankan di isolate seperti di app (hasilnya harus bisa dikirim balik ke isolate utama).
    final d = await Isolate.run(() => parseOldWorkbook(XlsxValues.decode(bytes)));
    expect(d.invoices.map((v) => v.total), [630000, 600000, 200000, 350000, 300000]);
    expect(d.invoices[1].payments.map((p) => p.account), ['BCA', 'MAS ANU']);
    expect(d.invoices[2].lines, isEmpty);
    expect(d.invoices[0].lines.first.name, 'LAMPU LED H4');
    expect(d.expenses.length, 5); // "abc" dilewati
    expect(d.problems.single, contains('bukan angka'));
    final c = d.checks.single;
    expect((c.sales, c.salesLabel), (2080000, 1780000)); // label sheet ini sengaja tanpa invoice Februari
    expect((c.expenses, c.expenseLabel), (1076000, 1071000));
  });

  test('parser: harga beli satuan yang ternyata total (= kolom total beli, qty > 1) dibagi qty', () {
    final d = parseOldWorkbook(
      XlsxValues.decode(
        xlsx({
          'FEB25': [
            header,
            row({
              0: DateTime(2025, 2, 3),
              5: 'Bohlam',
              6: 4,
              7: 150000,
              10: 400000,
              11: const F(400000),
              14: const F(600000),
              15: 'BCA',
            }),
            row({5: 'Fitting', 6: 2, 7: 50000, 10: 20000, 11: const F(40000)}),
          ],
        }),
      ),
    );
    expect(d.invoices.single.lines.map((l) => l.cost), [100000, 20000]);
    expect(d.problems.single, contains('berisi total'));
  });

  test('parser: barang tanpa tanggal sesudah uang tanpa rincian ikut uang itu; total di baris kedua tetap terbaca', () {
    final d = parseOldWorkbook(
      XlsxValues.decode(
        xlsx({
          'APR25': [
            header,
            row({0: DateTime(2025, 4, 1), 3: 'Ani', 5: 'Bohlam', 6: 1, 7: 100000, 14: const F(100000), 15: 'BCA'}),
            row({0: DateTime(2025, 4, 2), 1: 'B 1 C', 14: const F(500000), 15: 'BCA'}), // uang tanpa rincian
            row({5: 'Kabel', 6: 1, 7: 500000}), // barang tanpa tanggal → milik uang di atas
            row({0: DateTime(2025, 4, 3), 3: 'Dodi', 5: 'Relay', 6: 1, 7: 50000}), // total kosong di baris pertama
            row({5: 'Fuse', 6: 1, 7: 25000, 14: const F(75000), 15: 'TUNAI'}),
          ],
        }),
      ),
    );
    expect(d.invoices.map((v) => (v.lines.length, v.total)), [(1, 100000), (1, 500000), (2, 75000)]);
    expect(d.problems, isEmpty);
  });

  group('import', () {
    late AppDb db;
    late OldData data;
    late int budi, led;

    setUp(() async {
      db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
      budi = await db
          .into(db.customers)
          .insert(
            CustomersCompanion.insert(
              name: 'Budi',
              car: const Value('AVANZA'),
              plate: const Value('N 1234 AB'),
              phone: const Value('0811'),
            ),
          );
      led = await db
          .into(db.products)
          .insert(ProductsCompanion.insert(name: 'Lampu LED H4', buyPrice: const Value(99)));
      await db.into(db.products).insert(ProductsCompanion.insert(name: 'Soket H11', category: const Value('Soket')));
      data = parseOldWorkbook(XlsxValues.decode(xlsx({'JAN25': monthly})));
    });
    tearDown(() => db.close());

    test('invoice lama lunas, tanpa stok, customer & produk lama tidak berubah', () async {
      final res = await db.importOld(data, before: DateTime(2025, 2, 1));
      expect((res.invoices, res.skipped), (4, 2));
      final docs = await (db.select(db.invoices)..orderBy([(i) => OrderingTerm(expression: i.at)])).get();
      expect(docs.map((d) => d.no), ['L/2501/001', 'L/2501/002', 'L/2501/003', 'L/2501/004']);
      for (final d in docs) {
        expect((d.legacy, d.imported, d.dueAt), (true, true, d.at));
        final paid = (await (db.select(
          db.cashEntries,
        )..where((c) => c.refId.equals(d.id) & c.kind.equals('payment'))).get()).fold(0, (s, c) => s + c.amount);
        final lines = await (db.select(db.invoiceLines)..where((l) => l.invoiceId.equals(d.id))).get();
        expect(lines.fold(0, (s, l) => s + l.qty * l.price) - d.discount, paid, reason: d.no); // lunas
      }
      expect(docs[0].discount, 70000);
      expect(await db.select(db.stockMoves).get(), isEmpty);

      // Customer: plat (beda penulisan) → Budi lama, tanpa diubah; Sari baru; invoice 3 tanpa pemilik = UMUM.
      expect(docs.map((d) => d.customerId), [budi, isNot(budi), null, budi]);
      final b = await (db.select(db.customers)..where((c) => c.id.equals(budi))).getSingle();
      expect((b.name, b.car, b.plate, b.phone, b.imported), ('Budi', 'AVANZA', 'N 1234 AB', '0811', false));

      // Produk: nama sama (beda spasi/huruf) → produk lama; lainnya penampung nonaktif; modal dari sheet.
      final l1 = await (db.select(db.invoiceLines)..where((l) => l.invoiceId.equals(docs[0].id))).get();
      expect(l1.map((l) => (l.name, l.cost)), [('LAMPU LED H4', 150000), ('Pasang lampu', null)]);
      expect(l1.first.productId, led);
      final jasa = await (db.select(db.products)..where((p) => p.id.equals(l1[1].productId))).getSingle();
      expect((jasa.name, jasa.isService, jasa.active, jasa.imported), ('JASA PASANG', true, false, true));
      // Penampung: kategori hanya bila sama dengan kategori produk yang sudah ada ("SOKET" → "Soket").
      final cats = {for (final p in await (db.select(db.products)..where((p) => p.imported)).get()) p.name: p.category};
      expect((cats['SOKET'], cats['KABEL'], cats['JASA PASANG']), ('Soket', '', ''));
      final l4 = await (db.select(db.invoiceLines)..where((l) => l.invoiceId.equals(docs[3].id))).get();
      expect(l4.last.name, 'Penjualan');
      expect(l4.last.price, 50000);

      // Pembayaran kedua dengan "rekening" tak dikenal → rekening utama invoice, teks asli di catatan.
      final acc = {for (final a in await db.select(db.accounts).get()) a.id: a.name};
      final pay2 = await (db.select(db.cashEntries)..where((c) => c.refId.equals(docs[1].id))).get();
      expect(pay2.map((c) => (acc[c.accountId], c.amount, c.note)), [
        ('BCA', 300000, ''),
        ('BCA', 300000, 'Tertulis: MAS ANU'),
      ]);
      expect(res.accountsCreated, ['Bank Jago']);
    });

    test('pengeluaran: kategori dipetakan, pembelian stok bukan biaya, laba rugi & arus kas & jurnal', () async {
      await db.importOld(data, before: DateTime(2025, 2, 1));
      final from = DateTime(2025, 1), to = DateTime(2025, 2);
      final pl = (await db.report(from, to, Period.monthly)).pl.total;
      expect(pl.revenue, 630000 + 600000 + 200000 + 350000);
      expect(pl.cogs, 2 * 150000 + 200000 + 50000 + 150000);
      expect((pl.expense, pl.personal), (20000 + 1000, 50000)); // Transportasi + Lain-lain; Sumbangan = pribadi
      final flow = (await db.cashFlow(from, to, Period.monthly)).single;
      expect((flow.income, flow.expense), (1780000, 20000 + 1000000 + 50000 + 1000));
      final stock = await (db.select(db.cashEntries)..where((c) => c.kind.equals(CashKind.oldStock))).getSingle();
      expect((stock.amount, stock.refId, stock.note), (-1000000, null, 'Jumlah: 10'));
      final net = (await db.journal()).net();
      expect(net[Ac.pendapatanLain] ?? 0, 0); // pembelian stok lama tidak terbaca sebagai pendapatan
    });

    test('tidak bisa import dua kali; batalkan = kembali seperti semula, lalu bisa import lagi', () async {
      await db.importOld(data, before: DateTime(2025, 2, 1));
      await expectLater(db.importOld(data), throwsArgumentError);
      await db.undoOldImport();
      expect(await db.select(db.invoices).get(), isEmpty);
      expect(await db.select(db.invoiceLines).get(), isEmpty);
      expect(await db.select(db.cashEntries).get(), isEmpty);
      expect((await db.select(db.customers).get()).map((c) => c.id), [budi]);
      expect((await db.select(db.products).get()).length, 2); // Lampu LED H4 + Soket H11
      expect((await db.importOld(data)).invoices, 5); // tanpa tanggal batas: invoice Februari ikut
    });

    test('GAJI → gaji (tanpa slip); kategori Biaya client tidak bertambah', () async {
      final cats = (await db.select(db.expenseCategories).get()).length;
      final d = parseOldWorkbook(
        XlsxValues.decode(
          xlsx({
            'MAR25': [
              header,
              row({21: DateTime(2025, 3, 26), 22: 'Gaji teknisi', 24: 2500000, 25: 'BCA', 26: 'GAJI'}),
              row({21: DateTime(2025, 3, 27), 22: 'Kopi', 24: 15000, 25: 'TUNAI', 26: 'KATEGORI BARU'}),
            ],
          }),
        ),
      );
      final res = await db.importOld(d);
      expect((res.salaries, res.expenses), (1, 1));
      expect((await db.select(db.expenseCategories).get()).length, cats);
      final pl = (await db.report(DateTime(2025, 3), DateTime(2025, 4), Period.monthly)).pl.total;
      expect((pl.salary, pl.expense), (2500000, 15000));
      final kopi = await (db.select(db.cashEntries)..where((c) => c.description.equals('Kopi'))).getSingle();
      final lain = await (db.select(db.expenseCategories)..where((c) => c.id.equals(kopi.refId!))).getSingle();
      expect(lain.name, 'Lain-lain');
    });

    test('kosongkan transaksi: master data & stok awal tetap', () async {
      await db
          .into(db.stockMoves)
          .insert(StockMovesCompanion.insert(at: jan(1), productId: led, qty: 5, kind: 'opening'));
      await db.importOld(data);
      expect((await db.transactionCounts()).values.reduce((a, b) => a + b), greaterThan(0));
      await db.wipeTransactions();
      expect((await db.transactionCounts()).values.toSet(), {0});
      expect((await db.select(db.stockMoves).getSingle()).kind, 'opening');
      expect((await db.select(db.customers).get()).map((c) => c.id), [
        budi,
      ]); // customer asli tetap, hasil import bersih
      expect((await db.select(db.products).get()).any((p) => p.id == led), isTrue);
    });

    test('samakan saldo dengan saldo nyata: saldo awal dihitung mundur', () async {
      await db.importOld(data);
      final bca = (await db.accountBalances()).keys.firstWhere((a) => a.name == 'BCA');
      await db.setActualBalances({bca.id: 2500000});
      final after = await db.accountBalances();
      expect(after.entries.firstWhere((e) => e.key.id == bca.id).value, 2500000);
      expect(
        after.keys.firstWhere((a) => a.id == bca.id).openingBalance,
        2500000 - (630000 + 300000 + 300000 - 1000000),
      );
    });

    test('batalkan import mengembalikan saldo awal yang diubah "Samakan saldo"', () async {
      final bca = (await db.select(db.accounts).get()).firstWhere((a) => a.name == 'BCA');
      await (db.update(
        db.accounts,
      )..where((a) => a.id.equals(bca.id))).write(const AccountsCompanion(openingBalance: Value(777)));
      await db.importOld(data);
      await db.setActualBalances({bca.id: 5000000});
      await db.into(db.accounts).insert(AccountsCompanion.insert(name: 'OVO', openingBalance: const Value(2000)));
      await db.undoOldImport();
      final after = {for (final a in await db.select(db.accounts).get()) a.name: a.openingBalance};
      expect((after['BCA'], after['Bank Jago'], after['OVO']), (777, 0, 2000)); // OVO dibuat sesudah import: utuh
      expect((await db.accountBalances()).entries.firstWhere((e) => e.key.name == 'BCA').value, 777);
    });

    test('invoice hasil import tidak ikut omzet gaji (tunjangan sales slip yang belum dibayar)', () async {
      await db.importOld(data);
      expect(await db.omzet(DateTime(2025, 1), DateTime(2025, 3)), 0);
    });

    test('import produk Excel tidak menimpa produk penampung; tanggal transaksi app pertama', () async {
      await db.importOld(data);
      expect(await db.firstAppTransaction(), isNull); // hanya hasil import
      final r = await db.applyImport([ProductRow(rowNo: 2, name: 'SOKET', sellPrice: 1000)]);
      expect(r.created, 1);
      await db
          .into(db.cashEntries)
          .insert(
            CashEntriesCompanion.insert(
              at: DateTime(2026, 3, 4, 10),
              accountId: 1,
              amount: 5,
              kind: 'income',
              description: 'x',
            ),
          );
      expect(await db.firstAppTransaction(), DateTime(2026, 3, 4, 10));
    });

    test('kosongkan sesudah import → sisa import bersih, import ulang tidak dobel', () async {
      await db.importOld(data);
      final placeholders = (await (db.select(db.products)..where((p) => p.imported)).get()).length;
      await db.wipeTransactions();
      expect(await (db.select(db.products)..where((p) => p.imported)).get(), isEmpty);
      expect(await (db.select(db.customers)..where((c) => c.imported)).get(), isEmpty);
      await db.importOld(data);
      expect((await (db.select(db.products)..where((p) => p.imported)).get()).length, placeholders);
    });

    test('Kas: gaji & pembelian stok hasil import bisa dihapus; pembayaran invoice tidak', () async {
      await db.importOld(data);
      final stock = await (db.select(db.cashEntries)..where((c) => c.kind.equals(CashKind.oldStock))).getSingle();
      await db.deleteManualEntry(stock.id);
      final pay =
          await (db.select(db.cashEntries)
                ..where((c) => c.kind.equals('payment'))
                ..limit(1))
              .getSingle();
      await expectLater(db.deleteManualEntry(pay.id), throwsArgumentError);
    });

    test('Samakan saldo memuat rekening nonaktif', () async {
      await (db.update(
        db.accounts,
      )..where((a) => a.name.equals('Mandiri'))).write(const AccountsCompanion(active: Value(false)));
      expect((await db.accountBalances()).keys.map((a) => a.name), contains('Mandiri'));
    });

    test('hanya owner', () async {
      db.ownerUnlocked = false;
      await expectLater(db.importOld(data), throwsArgumentError);
      await expectLater(db.undoOldImport(), throwsArgumentError);
      await expectLater(db.wipeTransactions(), throwsArgumentError);
      await expectLater(db.setActualBalances({1: 0}), throwsArgumentError);
    });
  });
}
