import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;

import '../../core/range_picker.dart';

import 'package:get/get.dart';

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/xlsx.dart';
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
  /// Rentang tanggal mutasi (inklusif); awalnya bulan ini.
  final range = thisMonth().obs;
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
    everAll([accountId, range], (_) => _listenEntries());
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
    final r = range.value;
    _entrySub = db
        .watchEntries(accountId: accountId.value, from: r.start, to: r.endExclusive)
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

  /// Export mutasi yang sedang tampil (rentang + rekening terpilih) ke .xlsx. Pesan hasil, atau null bila batal.
  Future<String?> export() => exportXlsx(
    db,
    sheet: 'Mutasi',
    file: 'mutasi-kas',
    range: range.value,
    noun: 'transaksi',
    headers: ['Tanggal', 'Rekening', 'Jenis', 'Keterangan', 'Masuk', 'Keluar', if (_withBalance) 'Saldo'],
    rows: [
      for (final e in entries)
        [
          tgl(e.entry.at),
          e.accountName,
          cashKindLabel[e.entry.kind] ?? e.entry.kind,
          [e.entry.description, if (e.entry.note.isNotEmpty) e.entry.note].join(' · '),
          e.entry.amount > 0 ? e.entry.amount : null,
          e.entry.amount < 0 ? -e.entry.amount : null,
          if (_withBalance) e.balanceAfter,
        ],
    ],
  );

  bool get _withBalance => accountId.value != null && balances.isNotEmpty; // saldo berjalan hanya untuk satu rekening

  List<Account> get activeAccounts => [
    for (final a in accounts)
      if (a.active) a,
  ];

  /// null = owner terkunci (saldo tidak dimuat).
  int? get totalBalance => balances.isEmpty ? null : balances.values.fold<int>(0, (t, b) => t + b);
}
