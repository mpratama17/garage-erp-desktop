import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:get/get.dart';

import '../../core/owner.dart';
import '../../db/database.dart';
import '../gudang/gudang_repo.dart';
import '../kas/kas_repo.dart';
import '../laporan/laporan_repo.dart';
import '../penjualan/penjualan_repo.dart';
import 'dashboard_repo.dart';

class DashboardController extends GetxController {
  DashboardController(this.db);
  final AppDb db;

  final days = <SalesPoint>[].obs; // per hari bulan ini
  final months = <SalesPoint>[].obs; // per bulan, 12 bulan terakhir (termasuk bulan ini)
  final top = <TopItem>[].obs;
  final unpaid = <DocSummary>[].obs; // invoice belum lunas, lewat tempo dulu
  final lowStock = <StockedProduct>[].obs;
  final balance = RxnInt(); // owner saja
  final profit = RxnInt(); // laba bersih usaha bulan ini, owner saja

  final _subs = <StreamSubscription<Object?>>[];
  var _seq = 0;

  OwnerController get _owner => Get.find<OwnerController>();

  @override
  void onInit() {
    super.onInit();
    final today = DateTime.now();
    _subs
      ..add(
        db.watchDocs(DocKind.invoice).listen((docs) {
          final open = docs.where((d) => d.status == PayStatus.unpaid || d.status == PayStatus.partial).toList()
            ..sort((a, b) {
              final o = (b.overdue(today) ? 1 : 0) - (a.overdue(today) ? 1 : 0);
              return o != 0 ? o : a.doc.at.compareTo(b.doc.at);
            });
          unpaid.assignAll(open);
        }),
      )
      ..add(
        db.watchProducts().listen(
          (ps) => lowStock.assignAll(
            ps.where((s) => s.isLow && s.product.active).toList()..sort((a, b) => a.stock - b.stock),
          ),
        ),
      )
      ..add(db.watchBalances().listen((b) => balance.value = b.fold<int>(0, (t, x) => t + x.balance)))
      ..add(
        db
            .tableUpdates(TableUpdateQuery.onAllTables([db.invoices, db.invoiceLines, db.cashEntries]))
            .listen((_) => _load()),
      );
    ever(_owner.isOwner, (_) => _load());
    _load();
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    final now = DateTime.now();
    final month = DateTime(now.year, now.month), next = DateTime(now.year, now.month + 1);
    final d = await db.salesSeries(month, next);
    final m = await db.salesSeries(DateTime(now.year, now.month - 11), next, monthly: true);
    final t = await db.topItems(month, next);
    // Laba hanya dihitung saat owner terbuka — report() menolak tanpa PIN (aturan di repo).
    int? p;
    if (_owner.isOwner.value) {
      try {
        p = (await db.report(month, next, Period.monthly)).pl.total.net;
      } on ArgumentError {
        p = null; // owner terkunci saat sedang memuat
      }
    }
    if (seq != _seq) return;
    days.assignAll(d);
    months.assignAll(m);
    top.assignAll(t);
    profit.value = p;
  }

  SalesPoint? get today {
    final n = DateTime.now();
    return days.firstWhereOrNull((p) => p.start.day == n.day);
  }

  int get monthOmzet => days.fold(0, (t, p) => t + p.omzet);
  int get monthInvoices => days.fold(0, (t, p) => t + p.invoices);
  int? get lastMonthOmzet => months.length < 2 ? null : months[months.length - 2].omzet;
  int get unpaidTotal => unpaid.fold(0, (t, d) => t + d.remaining);
  int get overdueCount => unpaid.where((d) => d.overdue(DateTime.now())).length;
}
