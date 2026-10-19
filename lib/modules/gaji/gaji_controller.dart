import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:get/get.dart';

import '../../core/format.dart';
import '../../core/xlsx.dart';
import '../../db/database.dart';
import 'gaji_repo.dart';

enum GajiTab { slip, karyawan }

class GajiController extends GetxController {
  GajiController(this.db);
  final AppDb db;

  final tab = GajiTab.slip.obs;
  final period = Rxn<(DateTime, DateTime)>(); // [mulai, akhir); null = memuat tanggal mulai dari pengaturan
  final slips = <Slip>[].obs;
  final employees = <Employee>[].obs;
  (DateTime, DateTime)? _loadedPeriod; // periode milik [slips]

  final _subs = <StreamSubscription<Object?>>[];
  var _seq = 0;

  @override
  void onInit() {
    super.onInit();
    _subs
      ..add(db.watchEmployees().listen(employees.assignAll))
      ..add(
        db
            .tableUpdates(
              TableUpdateQuery.onAllTables([
                db.invoices,
                db.invoiceLines,
                db.payslips,
                db.cashEntries,
                db.employees,
                db.settings,
              ]),
            )
            .listen((_) => _load()),
      );
    ever(period, (_) => _load());
    _initPeriod();
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }

  Future<int> _startDay() async => int.tryParse(await db.setting('payroll_start_day')) ?? 27;

  Future<void> _initPeriod() async => period.value = payrollPeriodOf(DateTime.now(), await _startDay());

  Future<void> shift(int delta) async {
    final p = period.value;
    if (p == null) return;
    period.value = payrollPeriodOf(DateTime(p.$1.year, p.$1.month + delta, p.$1.day), await _startDay());
  }

  Future<void> _load() async {
    final p = period.value;
    if (p == null) return;
    final seq = ++_seq;
    try {
      final rows = await db.payroll(p.$1);
      if (seq != _seq) return; // abaikan hasil lama yang selesai belakangan
      slips.assignAll(rows);
      _loadedPeriod = p;
    } on ArgumentError {
      await _initPeriod(); // tanggal mulai periode diubah di Pengaturan → pindah ke periode baru
    }
  }

  int get total => slips.fold(0, (t, s) => t + s.total);

  /// Export slip periode ini + rincian insentif ke Excel. Pesan untuk user, atau null bila dibatalkan.
  Future<String?> export() async {
    final p = _loadedPeriod;
    if (p == null) return null;
    final bytes = buildXlsxSheets([
      (
        'Slip gaji',
        [
          'Nama',
          'Peran',
          'Gaji pokok',
          'Tunjangan makan',
          'Insentif',
          'Tunjangan kerja',
          'Lembur',
          'Bonus/THR',
          'Potongan',
          'Total',
          'Status',
          'Catatan',
        ],
        [
          for (final s in slips)
            [
              s.employee.name,
              employeeRoles[s.employee.role] ?? s.employee.role,
              s.baseSalary,
              s.mealAllowance,
              s.incentive,
              s.commission,
              s.overtime,
              s.bonus,
              s.deduction,
              s.total,
              s.paid ? 'Dibayar ${tgl(s.payment!.at)}' : 'Belum dibayar',
              s.saved?.note ?? '',
            ],
        ],
      ),
      (
        'Rincian insentif',
        ['Teknisi', 'Tanggal', 'Invoice', 'Mobil', 'Plat', 'Pekerjaan', 'Qty', 'Tarif', 'Dikerjakan berdua', 'Bagian'],
        [
          for (final s in slips)
            for (final l in s.lines)
              [
                s.employee.name,
                tgl(l.invoice.at),
                l.invoice.no,
                l.invoice.car,
                l.invoice.plate,
                l.line.name,
                l.line.qty,
                l.line.incentive,
                l.shared ? 'Ya' : '',
                l.share,
              ],
        ],
      ),
    ]);
    final path = await saveXlsx(db, bytes, 'gaji-${tgl(p.$1).replaceAll('/', '-')}.xlsx');
    return path == null ? null : 'Export tersimpan';
  }
}
