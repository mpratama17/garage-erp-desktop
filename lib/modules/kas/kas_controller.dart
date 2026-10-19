import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:get/get.dart';

import '../../core/owner.dart';
import '../../db/database.dart';
import 'kas_repo.dart';

enum KasTab { mutasi, arus }

class KasController extends GetxController {
  KasController(this.db);
  final AppDb db;

  final tab = KasTab.mutasi.obs;
  final accounts = <Account>[].obs; // semua rekening (siapa saja)
  final balances = <int, int>{}.obs; // accountId -> saldo; kosong saat owner terkunci
  final accountId = RxnInt(); // filter mutasi; null = semua rekening
  final month = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final entries = <EntryRow>[].obs;

  final period = Period.monthly.obs;
  final year = DateTime.now().year.obs;
  final flow = <FlowRow>[].obs;

  final _subs = <StreamSubscription<Object?>>[];
  StreamSubscription<List<EntryRow>>? _entrySub;
  StreamSubscription<Object?>? _balanceSub;
  Worker? _ownerWorker;

  @override
  void onInit() {
    super.onInit();
    _subs
      ..add(db.watchAccounts().listen(accounts.assignAll))
      ..add(db.tableUpdates(TableUpdateQuery.onTable(db.cashEntries)).listen((_) => _loadFlow()));
    everAll([accountId, month], (_) => _listenEntries());
    everAll([period, year], (_) => _loadFlow());
    _ownerWorker = ever(Get.find<OwnerController>().isOwner, (_) => _ownerChanged());
    _ownerChanged();
    _loadFlow();
  }

  /// Saldo hanya dimuat saat owner terbuka (repo menolak tanpa PIN); mutasi dimuat ulang untuk saldo berjalan.
  void _ownerChanged() {
    _balanceSub?.cancel();
    _balanceSub = null;
    balances.clear();
    if (Get.find<OwnerController>().isOwner.value) {
      _balanceSub = db.watchBalances().listen((b) => balances.assignAll({for (final x in b) x.account.id: x.balance}));
    }
    _listenEntries();
  }

  @override
  void onClose() {
    _entrySub?.cancel();
    _balanceSub?.cancel();
    _ownerWorker?.dispose();
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }

  void _listenEntries() {
    _entrySub?.cancel();
    final m = month.value;
    _entrySub = db
        .watchEntries(accountId: accountId.value, from: m, to: DateTime(m.year, m.month + 1))
        .listen(entries.assignAll);
  }

  var _flowSeq = 0;
  Future<void> _loadFlow() async {
    final seq = ++_flowSeq;
    // "Tahunan" menampilkan semua tahun; selain itu satu tahun yang dipilih.
    final (from, to) = period.value == Period.yearly
        ? (DateTime(2000), DateTime(DateTime.now().year + 1))
        : (DateTime(year.value), DateTime(year.value + 1));
    final rows = await db.cashFlow(from, to, period.value);
    if (seq == _flowSeq) flow.assignAll(rows); // abaikan hasil query lama yang selesai belakangan
  }

  void shiftMonth(int delta) => month.value = DateTime(month.value.year, month.value.month + delta);

  List<Account> get activeAccounts => [
    for (final a in accounts)
      if (a.active) a,
  ];

  /// null = owner terkunci (saldo tidak dimuat).
  int? get totalBalance => balances.isEmpty ? null : balances.values.fold<int>(0, (t, b) => t + b);
}
