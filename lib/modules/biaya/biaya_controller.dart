import 'dart:async';

import '../../core/range_picker.dart';

import 'package:get/get.dart';

import '../../core/format.dart';
import '../../core/xlsx.dart';
import '../../db/database.dart';
import '../gaji/gaji_repo.dart' show GajiRepo;
import 'biaya_repo.dart';

enum BiayaFilter { semua, operasional, pribadi }

class BiayaController extends GetxController {
  BiayaController(this.db);
  final AppDb db;

  /// Rentang tanggal biaya (inklusif); awalnya bulan ini.
  final range = thisMonth().obs;
  final filter = BiayaFilter.semua.obs;
  final expenses = <ExpenseRow>[].obs; // semua biaya dalam rentang (filter diterapkan di [shown])
  final categories = <ExpenseCategory>[].obs;
  final recurring = <RecurringExpense>[].obs;
  final employees = <Employee>[].obs;

  StreamSubscription<List<ExpenseCategory>>? _categorySub;
  final _extraSubs = <StreamSubscription<Object?>>[];
  StreamSubscription<List<ExpenseRow>>? _expenseSub;

  @override
  void onInit() {
    super.onInit();
    _categorySub = db.watchCategories().listen(categories.assignAll);
    _extraSubs
      ..add(db.watchRecurring().listen(recurring.assignAll))
      ..add(db.watchEmployees().listen(employees.assignAll));
    ever(range, (_) => _listen());
    _listen();
  }

  @override
  void onClose() {
    _expenseSub?.cancel();
    _categorySub?.cancel();
    for (final s in _extraSubs) {
      s.cancel();
    }
    super.onClose();
  }

  void _listen() {
    _expenseSub?.cancel();
    final r = range.value;
    _expenseSub = db.watchExpenses(from: r.start, to: r.endExclusive).listen(expenses.assignAll);
  }

  List<ExpenseRow> get shown => switch (filter.value) {
    BiayaFilter.semua => expenses.toList(),
    BiayaFilter.operasional => expenses.where((e) => !e.personal).toList(),
    BiayaFilter.pribadi => expenses.where((e) => e.personal).toList(),
  };

  /// Export biaya yang sedang tampil (rentang + filter operasional/pribadi) ke .xlsx (R4 #3).
  Future<String?> export() => exportXlsx(
    db,
    sheet: 'Biaya',
    file: 'biaya',
    range: range.value,
    noun: 'biaya',
    headers: ['Tanggal', 'Kategori', 'Jenis', 'Nama', 'Keterangan', 'Rekening', 'Nominal'],
    rows: [
      for (final e in shown)
        [
          tgl(e.entry.at),
          e.category?.name ?? '',
          e.personal ? 'Pribadi' : 'Operasional',
          e.entry.description,
          e.entry.note,
          e.accountName,
          e.amount,
        ],
    ],
  );

  /// Total biaya dalam rentang; [personal] null = semua.
  int total({bool? personal}) =>
      expenses.where((e) => personal == null || e.personal == personal).fold(0, (t, e) => t + e.amount);
}
