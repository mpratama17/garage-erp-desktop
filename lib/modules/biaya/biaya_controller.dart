import 'dart:async';

import 'package:get/get.dart';

import '../../db/database.dart';
import 'biaya_repo.dart';

enum BiayaFilter { semua, operasional, pribadi }

class BiayaController extends GetxController {
  BiayaController(this.db);
  final AppDb db;

  final month = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final filter = BiayaFilter.semua.obs;
  final expenses = <ExpenseRow>[].obs; // semua biaya bulan ini (filter diterapkan di [shown])
  final categories = <ExpenseCategory>[].obs;

  StreamSubscription<List<ExpenseCategory>>? _categorySub;
  StreamSubscription<List<ExpenseRow>>? _expenseSub;

  @override
  void onInit() {
    super.onInit();
    _categorySub = db.watchCategories().listen(categories.assignAll);
    ever(month, (_) => _listen());
    _listen();
  }

  @override
  void onClose() {
    _expenseSub?.cancel();
    _categorySub?.cancel();
    super.onClose();
  }

  void _listen() {
    _expenseSub?.cancel();
    final m = month.value;
    _expenseSub = db.watchExpenses(from: m, to: DateTime(m.year, m.month + 1)).listen(expenses.assignAll);
  }

  void shiftMonth(int delta) => month.value = DateTime(month.value.year, month.value.month + delta);

  List<ExpenseRow> get shown => switch (filter.value) {
    BiayaFilter.semua => expenses.toList(),
    BiayaFilter.operasional => expenses.where((e) => !e.personal).toList(),
    BiayaFilter.pribadi => expenses.where((e) => e.personal).toList(),
  };

  /// Total biaya bulan ini; [personal] null = semua.
  int total({bool? personal}) =>
      expenses.where((e) => personal == null || e.personal == personal).fold(0, (t, e) => t + e.amount);
}
