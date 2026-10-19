import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:get/get.dart';

import '../../db/database.dart';
import 'kas_repo.dart';

enum KasTab { mutasi, arus }

class KasController extends GetxController {
  KasController(this.db);
  final AppDb db;

  final tab = KasTab.mutasi.obs;
  final balances = <AccountBalance>[].obs;
  final accountId = RxnInt(); // filter mutasi; null = semua rekening
  final month = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final entries = <EntryRow>[].obs;

  final period = Period.monthly.obs;
  final year = DateTime.now().year.obs;
  final flow = <FlowRow>[].obs;

  final _subs = <StreamSubscription<Object?>>[];
  StreamSubscription<List<EntryRow>>? _entrySub;

  @override
  void onInit() {
    super.onInit();
    _subs
      ..add(db.watchBalances().listen(balances.assignAll))
      ..add(db.tableUpdates(TableUpdateQuery.onTable(db.cashEntries)).listen((_) => _loadFlow()));
    everAll([accountId, month], (_) => _listenEntries());
    everAll([period, year], (_) => _loadFlow());
    _listenEntries();
    _loadFlow();
  }

  @override
  void onClose() {
    _entrySub?.cancel();
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
    for (final b in balances)
      if (b.account.active) b.account,
  ];

  int get totalBalance => balances.fold(0, (t, b) => t + b.balance);
}
