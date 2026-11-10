import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';

import '../../core/owner.dart';
import '../../core/xlsx.dart';
import '../../db/database.dart';
import 'gudang_repo.dart';
import 'product_form.dart';

enum GudangTab { barang, jasa, ready }

/// Saringan dari kartu info Gudang (R7 #5) — sama dengan cara kartu menghitungnya (barang aktif).
enum StockFilter {
  ok,
  low,
  out;

  bool test(StockedProduct s) => switch (this) {
    ok => s.stock > 0 && !s.isLow,
    low => s.stock > 0 && s.isLow,
    out => s.stock <= 0,
  };
}

class GudangController extends GetxController {
  GudangController(this.db);
  final AppDb db;

  final products = <StockedProduct>[].obs;
  final tab = GudangTab.barang.obs;
  final filter = Rxn<StockFilter>();
  final showInactive = false.obs; // produk nonaktif (termasuk yang "dihapus" tapi punya riwayat) disembunyikan
  final flow = (sales: 0, purchases: 0).obs; // total penjualan barang & pembelian stok (strip info)

  /// Panel kanan: null = tertutup, 0 = produk baru, >0 = id produk yang dibuka.
  final panelId = RxnInt();

  /// Form produk di panel yang sedang terbuka (dipasang/dilepas oleh panelnya).
  ProductFields? editing;
  StreamSubscription<List<StockedProduct>>? _sub;
  Worker? _ownerWorker;

  @override
  void onInit() {
    super.onInit();
    _sub = db.watchProducts().listen((p) {
      products.assignAll(p.where((s) => !s.product.imported)); // penampung import catatan lama: bukan barang stok
      // Stok berubah karena penjualan/pembelian → ikut segarkan total.
      _loadFlow();
    });
    _ownerWorker = ever(Get.find<OwnerController>().isOwner, (_) => _loadFlow());
  }

  var _flowSeq = 0;
  Future<void> _loadFlow() async {
    final seq = ++_flowSeq;
    final t = await db.stockFlowTotals();
    if (seq == _flowSeq) flow.value = t; // abaikan hasil query lama yang selesai belakangan
  }

  @override
  void onClose() {
    _sub?.cancel();
    _ownerWorker?.dispose();
    super.onClose();
  }

  List<StockedProduct> get visible {
    final f = filter.value;
    return products.where((s) {
      if (!s.product.active && !(inactiveToggle && showInactive.value)) return false;
      return switch (tab.value) {
        GudangTab.barang => !s.isService && (f == null || f.test(s)),
        GudangTab.jasa => s.isService,
        GudangTab.ready => !s.isService && s.stock > 0,
      };
    }).toList();
  }

  /// Chip "Tampilkan nonaktif" berlaku di tab Barang/Jasa tanpa saringan kartu (Ready Stock & saringan = aktif saja).
  bool get inactiveToggle => tab.value != GudangTab.ready && filter.value == null;

  int get inactiveCount =>
      products.where((s) => !s.product.active && (tab.value == GudangTab.jasa) == s.isService).length;

  /// Klik kartu info: saring tab Barang; klik kartu yang sama lagi = semua. Tanpa [f] = tab Ready Stock
  /// (kartu Total stok: semua barang yang ada stoknya).
  void toggleFilter([StockFilter? f]) {
    final ready = f == null && tab.value != GudangTab.ready;
    filter.value = filter.value == f ? null : f;
    tab.value = ready ? GudangTab.ready : GudangTab.barang;
    panelId.value = null;
  }

  StockedProduct? get opened => products.firstWhereOrNull((s) => s.product.id == panelId.value);

  Future<bool> _save(List<int> bytes, String name) async => await saveXlsx(db, bytes, name) != null;

  Future<String?> downloadTemplate() async =>
      await _save(buildProductsXlsx([]), 'template-produk.xlsx') ? 'Template tersimpan' : null;

  Future<String?> export() async =>
      await _save(buildProductsXlsx(products), 'produk-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx')
      ? 'Export tersimpan (${products.length} produk)'
      : null;

  /// Kembalikan ringkasan hasil import, atau null bila dibatalkan.
  /// Import berjalan dalam satu transaksi: bila gagal, tidak ada data yang berubah.
  Future<({String summary, List<String> errors})?> import({bool syncStock = false}) async {
    final f = await openFile(acceptedTypeGroups: [xlsxFiles]);
    if (f == null) return null;
    final ImportResult res;
    try {
      res = parseProductsXlsx(await f.readAsBytes());
    } catch (e) {
      return (summary: 'Import gagal', errors: ['File tidak bisa dibaca sebagai .xlsx ($e)']);
    }
    try {
      final r = await db.applyImport(res.rows, syncStock: syncStock);
      final stok = r.stocked == 0 ? '' : ', stok ${r.stocked} produk disamakan';
      return (summary: '${r.created} produk baru, ${r.updated} diperbarui$stok', errors: res.errors);
    } catch (e) {
      final msg = e is ArgumentError ? '${e.message}' : '$e';
      return (summary: 'Import dibatalkan, tidak ada data yang berubah', errors: [...res.errors, msg]);
    }
  }
}
