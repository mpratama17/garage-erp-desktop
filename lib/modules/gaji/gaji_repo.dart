import 'package:drift/drift.dart';

import '../../core/format.dart';
import '../../db/database.dart';
import '../penjualan/penjualan_repo.dart';

const salaryKind = 'salary';
const employeeRoles = {'teknisi': 'Teknisi', 'sales': 'Sales'};

/// Periode gaji yang memuat [d]: [mulai, akhir) — mis. tgl 27 s/d 26 bulan berikutnya.
(DateTime, DateTime) payrollPeriodOf(DateTime d, int startDay) {
  final start = d.day >= startDay ? DateTime(d.year, d.month, startDay) : DateTime(d.year, d.month - 1, startDay);
  return (start, DateTime(start.year, start.month + 1, startDay));
}

/// "27/09/2026 – 26/10/2026"
String periodLabel(DateTime start, DateTime end) => '${tgl(start)} – ${tgl(end.subtract(const Duration(days: 1)))}';

/// Satu pekerjaan yang menghasilkan insentif bagi teknisi (rincian slip, pengganti sheet INSENTIF).
class IncentiveLine {
  IncentiveLine(this.invoice, this.line);
  final Invoice invoice;
  final InvoiceLine line;
  bool get shared => line.tech1Id != null && line.tech2Id != null;
  int get share => lineIncentiveShare(line);
}

class Slip {
  Slip({
    required this.employee,
    required this.start,
    required this.end,
    required this.saved,
    required this.payment,
    required this.lines,
    required this.omzet,
    required this.autoCommission,
    required this.commissionPct,
  });
  final Employee employee;
  final DateTime start, end;
  final Payslip? saved;
  final CashEntry? payment; // null = belum dibayar
  final List<IncentiveLine> lines;
  final int omzet, autoCommission, commissionPct;

  bool get paid => payment != null;
  // Belum dibayar: ikut data terbaru. Sudah dibayar: nilai yang dibekukan.
  int get baseSalary => saved?.baseSalary ?? employee.baseSalary;
  int get mealAllowance => saved?.mealAllowance ?? employee.mealAllowance;
  int get incentive => saved?.incentive ?? lines.fold(0, (t, l) => t + l.share);
  int get commission =>
      saved?.commission ?? (employee.role == 'sales' ? saved?.commissionOverride ?? autoCommission : 0);
  int get overtime => saved?.overtime ?? 0;
  int get bonus => saved?.bonus ?? 0;
  int get deduction => saved?.deduction ?? 0;
  int get total => totalWith();

  /// Total dengan isian yang sedang diubah (belum disimpan) — dipakai form slip agar rumusnya satu.
  int totalWith({int? commission, int? overtime, int? bonus, int? deduction}) =>
      baseSalary +
      mealAllowance +
      incentive +
      (commission ?? this.commission) +
      (overtime ?? this.overtime) +
      (bonus ?? this.bonus) -
      (deduction ?? this.deduction);
}

extension GajiRepo on AppDb {
  Stream<List<Employee>> watchEmployees() =>
      (select(employees)..orderBy([
            (e) => OrderingTerm.desc(e.active),
            (e) => OrderingTerm.asc(e.role),
            (e) => OrderingTerm.asc(e.name),
          ]))
          .watch();

  /// Tambah/ubah karyawan (owner). Tidak ada hapus — baris invoice lama menunjuk teknisinya; cukup nonaktifkan.
  Future<int> saveEmployee(EmployeesCompanion e) async {
    requireOwner();
    final name = e.name.value.trim();
    if (name.isEmpty) throw ArgumentError('Nama karyawan wajib diisi');
    if (!employeeRoles.containsKey(e.role.value)) throw ArgumentError('Peran tidak dikenal');
    if ((e.baseSalary.present && e.baseSalary.value < 0) || (e.mealAllowance.present && e.mealAllowance.value < 0)) {
      throw ArgumentError('Gaji tidak boleh minus');
    }
    final data = e.copyWith(name: Value(name));
    if (e.id.present) {
      await (update(employees)..where((x) => x.id.equals(e.id.value))).write(data);
      return e.id.value;
    }
    return into(employees).insert(data);
  }

  /// Invoice yang dihitung untuk gaji: invoice (bukan pemesanan — barisnya tersalin ke invoice), tidak batal,
  /// termasuk transaksi lama, lunas atau belum (insentif = per pekerjaan).
  Expression<bool> _payrollInvoice(DateTime from, DateTime to) =>
      invoices.kind.equals(DocKind.invoice) &
      invoices.isVoid.equals(false) &
      invoices.at.isBiggerOrEqualValue(from) &
      invoices.at.isSmallerThanValue(to);

  Future<List<IncentiveLine>> incentiveLines(int employeeId, DateTime from, DateTime to) async {
    final q = select(invoiceLines).join([innerJoin(invoices, invoices.id.equalsExp(invoiceLines.invoiceId))])
      ..where(
        _payrollInvoice(from, to) & (invoiceLines.tech1Id.equals(employeeId) | invoiceLines.tech2Id.equals(employeeId)),
      )
      ..orderBy([OrderingTerm.asc(invoices.at), OrderingTerm.asc(invoiceLines.id)]);
    return [for (final r in await q.get()) IncentiveLine(r.readTable(invoices), r.readTable(invoiceLines))];
  }

  /// Omzet = total invoice setelah diskon (barang + jasa), tanpa yang batal.
  Future<int> omzet(DateTime from, DateTime to) async {
    final sum = (invoiceLines.qty * invoiceLines.price - invoiceLines.discount).sum();
    final q = selectOnly(invoiceLines).join([innerJoin(invoices, invoices.id.equalsExp(invoiceLines.invoiceId))])
      ..addColumns([sum])
      ..where(_payrollInvoice(from, to));
    return (await q.getSingle()).read(sum) ?? 0;
  }

  Future<int> _commissionPct() async => num.tryParse(await setting('sales_commission_pct'))?.toInt() ?? 0;

  Future<Slip> _slip(Employee e, DateTime start, DateTime end, {required int omzet, required int pct}) async {
    final saved = await (select(
      payslips,
    )..where((p) => p.employeeId.equals(e.id) & p.periodStart.equals(start))).getSingleOrNull();
    final payment = saved == null
        ? null
        : await (select(
            cashEntries,
          )..where((c) => c.kind.equals(salaryKind) & c.refId.equals(saved.id))).getSingleOrNull();
    return Slip(
      employee: e,
      start: start,
      end: end,
      saved: saved,
      payment: payment,
      lines: await incentiveLines(e.id, start, end),
      omzet: omzet,
      // ponytail: tiap sales dapat pct × omzet toko (client punya 1 sales); bagi per sales bila nanti >1.
      autoCommission: e.role == 'sales' ? (omzet * pct / 100).round() : 0,
      commissionPct: pct,
    );
  }

  /// Periode gaji yang diawali [start]. Akhir diturunkan dari pengaturan — tidak diterima dari pemanggil,
  /// supaya tidak ada rentang buatan yang tumpang tindih dengan periode resmi.
  Future<DateTime> _periodEnd(DateTime start) async {
    final (s, end) = payrollPeriodOf(start, int.tryParse(await setting('payroll_start_day')) ?? 27);
    if (s != start) throw ArgumentError('Periode gaji tidak valid');
    return end;
  }

  /// Slip semua karyawan untuk periode yang diawali [start]: karyawan aktif, plus yang nonaktif bila punya
  /// slip atau insentif di periode itu.
  Future<List<Slip>> payroll(DateTime start) async {
    requireOwner(); // berisi gaji karyawan
    final end = await _periodEnd(start);
    final o = await omzet(start, end), pct = await _commissionPct();
    final out = <Slip>[];
    for (final e in await watchEmployees().first) {
      final s = await _slip(e, start, end, omzet: o, pct: pct);
      if (e.active || s.saved != null || s.lines.isNotEmpty) out.add(s);
    }
    return out;
  }

  Future<Employee> _employee(int id) async {
    final e = await (select(employees)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (e == null) throw ArgumentError('Karyawan tidak ditemukan');
    return e;
  }

  /// Simpan isian manual slip yang belum dibayar (owner). [commission] null = otomatis.
  Future<void> saveSlip({
    required int employeeId,
    required DateTime start,
    int? commission,
    int overtime = 0,
    int bonus = 0,
    int deduction = 0,
    String note = '',
  }) => transaction(() async {
    requireOwner();
    if ([overtime, bonus, deduction, commission ?? 0].any((v) => v < 0)) throw ArgumentError('Nilai tidak boleh minus');
    final end = await _periodEnd(start);
    final s = await _slip(await _employee(employeeId), start, end, omzet: 0, pct: 0);
    if (s.paid) throw ArgumentError('Slip sudah dibayar — batalkan pembayaran dulu untuk mengubah');
    final data = PayslipsCompanion(
      employeeId: Value(employeeId),
      periodStart: Value(start),
      periodEnd: Value(end),
      commissionOverride: Value(commission),
      overtime: Value(overtime),
      bonus: Value(bonus),
      deduction: Value(deduction),
      note: Value(note.trim()),
    );
    if (s.saved == null) {
      await into(payslips).insert(data);
    } else {
      await (update(payslips)..where((p) => p.id.equals(s.saved!.id))).write(data);
    }
  });

  /// Bayar slip (owner): bekukan semua komponen lalu catat uang keluar kind=salary dari [accountId].
  Future<void> paySlip({
    required int employeeId,
    required DateTime start,
    required int accountId,
    required DateTime at,
    String proofPath = '',
  }) => transaction(() async {
    requireOwner();
    final e = await _employee(employeeId);
    final end = await _periodEnd(start);
    final s = await _slip(e, start, end, omzet: await omzet(start, end), pct: await _commissionPct());
    if (s.paid) throw ArgumentError('Slip ${e.name} sudah dibayar');
    // Tanggal mulai periode bisa diubah di Pengaturan → cegah pekerjaan yang sama terbayar dua kali.
    final overlap = await customSelect(
      'SELECT p.period_start, p.period_end FROM payslips p '
      'WHERE p.employee_id = ? AND p.period_start < ? AND p.period_end > ? AND p.period_start <> ? '
      "AND EXISTS (SELECT 1 FROM cash_entries c WHERE c.kind = 'salary' AND c.ref_id = p.id) LIMIT 1",
      variables: [Variable(employeeId), Variable(end), Variable(start), Variable(start)],
      readsFrom: {payslips, cashEntries},
    ).getSingleOrNull();
    if (overlap != null) {
      throw ArgumentError(
        'Periode ini bertumpuk dengan slip ${e.name} yang sudah dibayar '
        '(${periodLabel(overlap.read<DateTime>('period_start'), overlap.read<DateTime>('period_end'))})',
      );
    }
    if (s.total <= 0) throw ArgumentError('Total gaji harus lebih dari 0');
    await requireActiveAccount(accountId);
    final frozen = PayslipsCompanion(
      employeeId: Value(employeeId),
      periodStart: Value(start),
      periodEnd: Value(end),
      baseSalary: Value(s.baseSalary),
      mealAllowance: Value(s.mealAllowance),
      incentive: Value(s.incentive),
      commission: Value(s.commission),
    );
    final id = s.saved?.id ?? await into(payslips).insert(frozen);
    if (s.saved != null) await (update(payslips)..where((p) => p.id.equals(id))).write(frozen);
    await into(cashEntries).insert(
      CashEntriesCompanion.insert(
        at: at,
        accountId: accountId,
        amount: -s.total,
        kind: salaryKind,
        refId: Value(id),
        description: 'Gaji ${e.name} ${periodLabel(start, end)}',
        proofPath: Value(proofPath),
      ),
    );
  });

  /// Batalkan pembayaran (owner): uang kembali ke rekening, slip kembali mengikuti data terbaru.
  /// Isian manual (lembur, bonus, potongan, catatan, koreksi komisi) tetap.
  Future<void> cancelSlipPayment(int payslipId) => transaction(() async {
    requireOwner();
    final n = await (delete(cashEntries)..where((c) => c.kind.equals(salaryKind) & c.refId.equals(payslipId))).go();
    if (n == 0) throw ArgumentError('Slip belum dibayar');
    await (update(payslips)..where((p) => p.id.equals(payslipId))).write(
      const PayslipsCompanion(
        baseSalary: Value(null),
        mealAllowance: Value(null),
        incentive: Value(null),
        commission: Value(null),
      ),
    );
  });
}
