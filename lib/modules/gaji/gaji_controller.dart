import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:get/get.dart';

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
      if (seq == _seq) slips.assignAll(rows); // abaikan hasil lama yang selesai belakangan
    } on ArgumentError {
      await _initPeriod(); // tanggal mulai periode diubah di Pengaturan → pindah ke periode baru
    }
  }

  int get total => slips.fold(0, (t, s) => t + s.total);
}
