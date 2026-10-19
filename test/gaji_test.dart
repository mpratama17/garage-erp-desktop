import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gaji/gaji_repo.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';

void main() {
  late AppDb db;
  late int tekA, tekB, sales, jasa, bca;
  // Periode 27 Sep – 26 Okt 2026.
  final (start, _) = payrollPeriodOf(DateTime(2026, 10, 19), 27);
  final d = DateTime(2026, 10, 5);

  setUp(() async {
    db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    Future<int> emp(String n, String role, int base) =>
        db.saveEmployee(EmployeesCompanion.insert(name: n, role: role, baseSalary: Value(base)));
    tekA = await emp('Teknisi A', 'teknisi', 2000000);
    tekB = await emp('Teknisi B', 'teknisi', 2000000);
    sales = await emp('Sales A', 'sales', 1500000);
    jasa = await db.saveProduct(ProductsCompanion.insert(name: 'Pasang projector', isService: const Value(true)));
    bca = (await (db.select(db.accounts)..where((a) => a.name.equals('BCA'))).getSingle()).id;
  });
  tearDown(() => db.close());

  Future<int> invoice({
    String kind = DocKind.invoice,
    DateTime? at,
    int price = 1000000,
    int discount = 0,
    int incentive = 100000,
    int qty = 1,
    int? t1,
    int? t2,
  }) => db.saveDoc(
    kind: kind,
    at: at ?? d,
    lines: [
      LineInput(
        productId: jasa,
        name: 'Pasang projector',
        qty: qty,
        price: price,
        discount: discount,
        incentive: incentive,
        tech1Id: t1,
        tech2Id: t2,
      ),
    ],
  );

  Future<Slip> slipOf(int id) async => (await db.payroll(start)).singleWhere((s) => s.employee.id == id);

  test('periode gaji mengikuti tanggal mulai (batas 26 23:59 / 27 00:00)', () {
    expect(payrollPeriodOf(DateTime(2026, 10, 26, 23, 59), 27), (DateTime(2026, 9, 27), DateTime(2026, 10, 27)));
    expect(payrollPeriodOf(DateTime(2026, 10, 27), 27), (DateTime(2026, 10, 27), DateTime(2026, 11, 27)));
    expect(payrollPeriodOf(DateTime(2027, 1, 3), 27), (DateTime(2026, 12, 27), DateTime(2027, 1, 27)));
    expect(payrollPeriodOf(DateTime(2026, 10, 1), 1), (DateTime(2026, 10, 1), DateTime(2026, 11, 1)));
  });

  test(
    'insentif per teknisi: dikerjakan berdua dibagi dua; batal, pemesanan, dan luar periode tidak dihitung',
    () async {
      await invoice(t1: tekA, qty: 2); // 200.000 untuk A
      await invoice(t1: tekA, t2: tekB, incentive: 50000); // 25.000 masing-masing
      await invoice(t1: tekB, at: DateTime(2026, 9, 26)); // periode sebelumnya
      await invoice(kind: DocKind.order, t1: tekA); // pemesanan
      final batal = await invoice(t1: tekA);
      await db.voidDoc(batal, 'salah input');
      final a = await slipOf(tekA), b = await slipOf(tekB);
      expect((a.incentive, b.incentive), (225000, 25000));
      expect(a.lines.map((l) => (l.share, l.shared)), [(200000, false), (25000, true)]);
      expect(a.total, 2000000 + 225000);
    },
  );

  test('komisi sales = 3% omzet setelah diskon (dibulatkan), bisa dikoreksi owner', () async {
    await invoice(price: 1000000, discount: 50000); // 950.000
    await invoice(price: 333333); // omzet 1.283.333 → 3% = 38.499,99 → 38.500
    final s = await slipOf(sales);
    expect((s.omzet, s.commission, s.incentive), (1283333, 38500, 0));
    expect((await slipOf(tekA)).commission, 0);
    await db.saveSlip(employeeId: sales, start: start, commission: 40000, bonus: 100000, deduction: 25000);
    final k = await slipOf(sales);
    expect((k.commission, k.total), (40000, 1500000 + 40000 + 100000 - 25000));
  });

  test('bayar: saldo berkurang, masuk arus kas, slip beku; tidak bisa dibayar/diubah dua kali; batal bayar', () async {
    await invoice(t1: tekA);
    await db.saveSlip(employeeId: tekA, start: start, overtime: 50000);
    await db.paySlip(employeeId: tekA, start: start, accountId: bca, at: DateTime(2026, 10, 27));
    var a = await slipOf(tekA);
    expect((a.paid, a.total, a.payment!.amount), (true, 2150000, -2150000));
    final saldo = {for (final b in await db.watchBalances().first) b.account.name: b.balance};
    expect(saldo['BCA'], -2150000);
    expect((await db.cashFlow(DateTime(2026), DateTime(2027), Period.monthly)).single.expense, 2150000);

    // Data berubah setelah dibayar → slip tetap.
    await invoice(t1: tekA);
    await (db.update(
      db.employees,
    )..where((e) => e.id.equals(tekA))).write(const EmployeesCompanion(baseSalary: Value(9)));
    a = await slipOf(tekA);
    expect((a.incentive, a.baseSalary, a.total), (100000, 2000000, 2150000));

    await expectLater(db.paySlip(employeeId: tekA, start: start, accountId: bca, at: d), throwsArgumentError);
    await expectLater(db.saveSlip(employeeId: tekA, start: start, bonus: 1), throwsArgumentError);
    await expectLater(db.deleteManualEntry(a.payment!.id), throwsArgumentError); // gaji diurus di modul Gaji

    await db.cancelSlipPayment(a.saved!.id);
    a = await slipOf(tekA);
    expect((a.paid, a.incentive, a.baseSalary, a.overtime), (false, 200000, 9, 50000));
  });

  test('aturan owner & validasi; karyawan nonaktif tetap muncul bila punya insentif', () async {
    await expectLater(db.paySlip(employeeId: sales, start: start, accountId: bca, at: d), completes);
    await db.saveEmployee(
      EmployeesCompanion(
        id: Value(tekB),
        name: const Value('Teknisi B'),
        role: const Value('teknisi'),
        active: const Value(false),
      ),
    );
    expect((await db.payroll(start)).any((s) => s.employee.id == tekB), false);
    await invoice(t1: tekB);
    expect((await db.payroll(start)).any((s) => s.employee.id == tekB), true);
    await expectLater(db.saveEmployee(EmployeesCompanion.insert(name: 'X', role: 'kasir')), throwsArgumentError);
    db.ownerUnlocked = false;
    await expectLater(db.saveEmployee(EmployeesCompanion.insert(name: 'Y', role: 'sales')), throwsArgumentError);
    await expectLater(db.saveSlip(employeeId: tekA, start: start), throwsArgumentError);
    await expectLater(
      db.paySlip(employeeId: tekA, start: start, accountId: bca, at: d),
      throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('PIN'))),
    );
  });

  test('periode diturunkan dari pengaturan; ubah tanggal mulai tidak membuat pekerjaan terbayar dua kali', () async {
    await expectLater(db.payroll(DateTime(2026, 10, 1)), throwsArgumentError); // bukan awal periode
    await expectLater(db.saveSlip(employeeId: tekA, start: DateTime(2026, 10, 1)), throwsArgumentError);
    await invoice(t1: tekA);
    await db.paySlip(employeeId: tekA, start: start, accountId: bca, at: d);
    await db.setSetting('payroll_start_day', '1');
    await expectLater(
      db.paySlip(employeeId: tekA, start: DateTime(2026, 10), accountId: bca, at: d),
      throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('bertumpuk'))),
    );
    await db.paySlip(employeeId: tekA, start: DateTime(2026, 11), accountId: bca, at: d); // tidak bertumpuk
  });

  test('koreksi komisi tetap setelah batal bayar; hanya berlaku untuk sales', () async {
    await invoice(price: 1000000);
    await db.saveSlip(employeeId: sales, start: start, commission: 40000);
    await db.paySlip(employeeId: sales, start: start, accountId: bca, at: d);
    await db.cancelSlipPayment((await slipOf(sales)).saved!.id);
    expect((await slipOf(sales)).commission, 40000);
    await db.saveEmployee(
      EmployeesCompanion(id: Value(sales), name: const Value('Sales A'), role: const Value('teknisi')),
    );
    expect((await slipOf(sales)).commission, 0);
  });
}
