import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_erp_flutter/core/format.dart';
import 'package:workshop_erp_flutter/db/database.dart';
import 'package:workshop_erp_flutter/modules/kontak/kontak_repo.dart';

List<int> _xlsx(List<List<CellValue?>> rows) {
  final excel = Excel.createExcel();
  final s = excel.getDefaultSheet()!;
  for (final r in rows) {
    excel.appendRow(s, r);
  }
  return excel.encode()!;
}

CellValue? _t(String? v) => v == null ? null : TextCellValue(v);

void main() {
  late AppDb db;
  setUp(() => db = AppDb(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('normalisasi: plat, no. HP valid', () {
    expect(normalizePlate(' n 1234   ab '), 'N 1234 AB');
    expect(normalizePhone('0062 811 0000 2222'), '081100002222');
    expect(normalizePhone('+62 811 0000 2222'), '081100002222');
    expect(validPhone('081234567890'), true);
    expect(validPhone('0811000009'), true); // 10 digit masih wajar
    expect(validPhone('0812'), false);
    expect(validPhone('81234567890'), false);
  });

  test('simpan customer: nama wajib, HP dinormalisasi & unik, plat kapital', () async {
    final id = await db.saveCustomer(
      CustomersCompanion.insert(
        name: '  Budi  Santoso ',
        phone: const Value('+62 811-0000-2222'),
        plate: const Value('n 1 ab'),
      ),
    );
    final c = await (db.select(db.customers)..where((x) => x.id.equals(id))).getSingle();
    expect((c.name, c.phone, c.plate), ('Budi Santoso', '081100002222', 'N 1 AB'));
    expect(
      () => db.saveCustomer(CustomersCompanion.insert(name: 'Lain', phone: const Value('0811 0000 2222'))),
      throwsArgumentError,
    );
    expect(() => db.saveCustomer(CustomersCompanion.insert(name: ' ')), throwsArgumentError);
    expect(() => db.saveCustomer(CustomersCompanion.insert(name: 'X', phone: const Value('123'))), throwsArgumentError);
    // Tanpa HP boleh, dan boleh lebih dari satu.
    await db.saveCustomer(CustomersCompanion.insert(name: 'Walk-in 1'));
    await db.saveCustomer(CustomersCompanion.insert(name: 'Walk-in 2'));
    // Edit dirinya sendiri dengan HP yang sama tidak dianggap duplikat.
    await db.saveCustomer(
      CustomersCompanion(id: Value(id), name: const Value('Budi S'), phone: const Value('081100002222')),
    );
  });

  test('import format Google Sheet client: gabung HP sama, lewati yang rusak, mobil = merek + model', () async {
    final res = parseCustomersXlsx(
      _xlsx([
        [_t('Nama'), _t('NO TELEPON'), _t('JENIS MOBIL '), _t('MOBIL'), _t('CUST'), _t('PLAT MOBIL '), _t('Catatan')],
        [_t('ABDUL '), _t('081100000001'), _t('TOYOTA'), null, _t('PELANGGAN'), null, null],
        [_t('ABI'), _t('\n081100000002'), null, null, _t('PELANGGAN'), null, null],
        [_t('IQBAL'), _t('081100000003'), null, null, _t('PELANGGAN'), null, null],
        [_t('INDRO'), _t('0811 0000 0003'), _t('HONDA'), _t('BRIO'), _t('PELANGGAN'), _t('n 9 x'), null],
        [_t('BAGUS'), _t('0812'), null, null, _t('PELANGGAN'), null, null],
        [null, _t('081100000009'), null, null, null, null, null],
      ]),
    );
    expect(res.rows.map((r) => (r.name, r.phone)), [
      ('ABDUL', '081100000001'),
      ('ABI', '081100000002'),
      ('IQBAL', '081100000003'),
    ]);
    expect(res.rows.first.car, 'TOYOTA');
    expect((res.rows.last.car, res.rows.last.plate), ('HONDA BRIO', 'N 9 X')); // diisi dari baris INDRO
    expect(res.merged.single, contains('Baris 5 ("INDRO") digabung ke baris 4 ("IQBAL")'));
    expect(res.errors, hasLength(2)); // HP tidak valid + nama kosong

    expect(await db.applyCustomerImport(res.rows), (created: 3, updated: 0));
    // Import ulang: cocok via HP, kolom kosong tidak menimpa data yang sudah ada.
    await db.saveCustomer(
      CustomersCompanion(
        id: Value((await db.watchCustomers().first).firstWhere((c) => c.name == 'ABI').id),
        name: const Value('ABI'),
        phone: const Value('081100000002'),
        plate: const Value('N 2 B'),
      ),
    );
    expect(await db.applyCustomerImport(res.rows), (created: 0, updated: 3));
    expect((await db.watchCustomers().first).firstWhere((c) => c.name == 'ABI').plate, 'N 2 B');
  });

  test('export lalu import kembali', () async {
    await db.saveCustomer(
      CustomersCompanion.insert(
        name: 'Budi',
        phone: const Value('081100002222'),
        car: const Value('Innova'),
        plate: const Value('N 1 AB'),
      ),
    );
    final res = parseCustomersXlsx(buildCustomersXlsx(await db.watchCustomers().first));
    expect(res.errors, isEmpty);
    final r = res.rows.single;
    expect((r.name, r.phone, r.car, r.plate), ('Budi', '081100002222', 'Innova', 'N 1 AB'));
  });

  test('import: nama sama tanpa HP tidak menimpa orang ber-HP; HP baru mengisi customer tanpa HP', () async {
    await db.saveCustomer(
      CustomersCompanion.insert(name: 'BUDI', phone: const Value('081100002222'), car: const Value('TOYOTA')),
    );
    await db.saveCustomer(CustomersCompanion.insert(name: 'Siti Aminah'));
    final rows = [
      CustomerRow(rowNo: 2, name: 'BUDI', car: 'HONDA'), // orang lain, tanpa HP
      CustomerRow(rowNo: 3, name: 'SITI AMINAH', phone: '081100003333'),
      CustomerRow(rowNo: 4, name: 'WALK-IN'),
      CustomerRow(rowNo: 5, name: 'WALK-IN'),
    ];
    expect(await db.applyCustomerImport(rows), (created: 2, updated: 2));
    final all = await db.watchCustomers().first;
    expect(all.firstWhere((c) => c.phone == '081100002222').car, 'TOYOTA'); // tidak tertimpa
    final siti = all.where((c) => c.name.toUpperCase() == 'SITI AMINAH');
    expect(siti.single.phone, '081100003333'); // tidak dobel; nama lama tidak ditimpa
    expect(siti.single.name, 'Siti Aminah');
    expect(all.where((c) => c.name == 'WALK-IN').length, 1); // baris kembar di file digabung
    // Import ulang file yang sama tidak menambah apa pun.
    expect((await db.applyCustomerImport(rows)).created, 0);
    expect(await db.watchCustomers().first, hasLength(all.length));
  });
}
