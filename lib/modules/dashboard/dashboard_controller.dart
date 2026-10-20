import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/material.dart' show DateUtils;
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

  final days = <SalesPoint>[].obs; // per hari bulan ini (KPI hari ini/bulan ini)
  final top = <TopItem>[].obs;

  // Grafik omzet & pemasukan/pengeluaran (C14-16): period + rentang tanggal, untuk semua pengguna.
  final chartPeriod = Period.monthly.obs;
  final chartFrom = Rx<DateTime>(DateTime(DateTime.now().year, DateTime.now().month - 11));
  final chartTo = Rx<DateTime>(DateTime(DateTime.now().year, DateTime.now().month + 1));
  final chartPoints = <SalesPoint>[].obs; // omzet per titik
  final flowPoints = <FlowRow>[].obs; // pemasukan/pengeluaran per titik (bagan)
  var _chartSeq = 0;
  final unpaid = <DocSummary>[].obs; // invoice belum lunas, lewat tempo dulu
  final lowStock = <StockedProduct>[].obs;
  final balance = RxnInt(); // owner saja
  final profit = RxnInt(); // laba bersih usaha bulan ini, owner saja

  final lastMonthToDate = RxnInt(); // omzet bulan lalu s/d tanggal yang sama (pembanding adil)

  final _subs = <StreamSubscription<Object?>>[];
  StreamSubscription<Object?>? _balanceSub;
  Worker? _ownerWorker;
  Timer? _clock;
  var _day = DateUtils.dateOnly(DateTime.now());
  var _seq = 0;

  OwnerController get _owner => Get.find<OwnerController>();

  @override
  void onInit() {
    super.onInit();
    _subs
      ..add(
        db.watchDocs(DocKind.invoice).listen((docs) {
          final open = docs.where((d) => d.status == PayStatus.unpaid || d.status == PayStatus.partial).toList()
            ..sort((a, b) {
              final now = DateTime.now();
              final o = (b.overdue(now) ? 1 : 0) - (a.overdue(now) ? 1 : 0);
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
      ..add(
        db.tableUpdates(TableUpdateQuery.onAllTables([db.invoices, db.invoiceLines, db.cashEntries])).listen((_) {
          _load();
          _loadChart();
        }),
      );
    _ownerWorker = ever(_owner.isOwner, (_) => _ownerChanged());
    // App bisa terbuka semalaman: muat ulang saat tanggal berganti.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      final d = DateUtils.dateOnly(DateTime.now());
      if (d != _day) {
        _day = d;
        _load();
      }
    });
    _ownerChanged();
    _loadChart();
  }

  /// Saldo hanya dimuat saat owner terbuka (bukan sekadar disembunyikan di layar).
  void _ownerChanged() {
    _balanceSub?.cancel();
    _balanceSub = null;
    balance.value = null;
    if (_owner.isOwner.value) {
      _balanceSub = db.watchBalances().listen((b) => balance.value = b.fold<int>(0, (t, x) => t + x.balance));
    }
    _load();
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    _balanceSub?.cancel();
    _ownerWorker?.dispose();
    _clock?.cancel();
    super.onClose();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    final now = DateTime.now();
    final month = DateTime(now.year, now.month), next = DateTime(now.year, now.month + 1);
    // Pembanding: bulan lalu tgl 1 s/d tanggal yang sama (dibatasi akhir bulan lalu).
    final prevEnd = DateTime(now.year, now.month - 1, now.day + 1);
    final prevTo = prevEnd.isAfter(month) ? month : prevEnd;
    // Laba hanya dihitung saat owner terbuka — report() menolak tanpa PIN (aturan di repo).
    Future<int?> profitOf() async {
      if (!_owner.isOwner.value) return null;
      try {
        return (await db.report(month, next, Period.monthly)).pl.total.net;
      } on ArgumentError {
        return null; // owner terkunci saat sedang memuat
      }
    }

    final (d, prev, t, p) = await (
      db.salesSeries(month, next),
      db.salesSeries(DateTime(now.year, now.month - 1), prevTo),
      db.topItems(month, next),
      profitOf(),
    ).wait;
    if (seq != _seq) return;
    days.assignAll(d);
    lastMonthToDate.value = prev.fold<int>(0, (s, x) => s + x.omzet);
    top.assignAll(t);
    profit.value = p;
  }

  /// Ganti periode grafik: rentang direset ke bentang wajar untuk periode itu (bisa diganti lewat
  /// [setChartRange]). Harian = bulan ini, bulanan = 12 bulan, tahunan = 5 tahun terakhir.
  void setChartPeriod(Period p) {
    chartPeriod.value = p;
    final now = DateTime.now();
    final (from, to) = switch (p) {
      Period.daily => (DateTime(now.year, now.month), DateTime(now.year, now.month + 1)),
      Period.monthly => (DateTime(now.year, now.month - 11), DateTime(now.year, now.month + 1)),
      Period.quarterly => (DateTime(now.year - 1, now.month), DateTime(now.year, now.month + 1)),
      Period.yearly => (DateTime(now.year - 4), DateTime(now.year + 1)),
    };
    chartFrom.value = from;
    chartTo.value = to;
    _loadChart();
  }

  void setChartRange(DateTime from, DateTime to) {
    chartFrom.value = from;
    chartTo.value = DateTime(to.year, to.month, to.day + 1); // to = inklusif tanggal terakhir
    _loadChart();
  }

  Future<void> _loadChart() async {
    final seq = ++_chartSeq;
    final (points, flow) = await (
      db.salesSeries(chartFrom.value, chartTo.value, period: chartPeriod.value),
      db.cashFlow(chartFrom.value, chartTo.value, chartPeriod.value),
    ).wait;
    if (seq != _chartSeq) return;
    chartPoints.assignAll(points);
    flowPoints.assignAll(flow);
  }

  SalesPoint? get today => days.firstWhereOrNull((p) => p.start == DateUtils.dateOnly(DateTime.now()));

  int get monthOmzet => days.fold(0, (t, p) => t + p.omzet);
  int get monthInvoices => days.fold(0, (t, p) => t + p.invoices);
  int get unpaidTotal => unpaid.fold(0, (t, d) => t + d.remaining);
  int get overdueCount => unpaid.where((d) => d.overdue(DateTime.now())).length;
}
