import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';

import '../../core/owner.dart';
import '../../core/xlsx.dart';
import '../../db/database.dart';
import 'gudang_repo.dart';

enum GudangTab { barang, jasa, ready }

class GudangController extends GetxController {
  GudangController(this.db);
  final AppDb db;

  final products = <StockedProduct>[].obs;
  final tab = GudangTab.barang.obs;
  final flow = (sales: 0, purchases: 0).obs; // total penjualan barang & pembelian stok (strip info)

  /// Panel kanan: null = tertutup, 0 = produk baru, >0 = id produk yang dibuka.
  final panelId = RxnInt();
  StreamSubscription<List<StockedProduct>>? _sub;
  Worker? _ownerWorker;

  @override
  void onInit() {
    super.onInit();
    _sub = db.watchProducts().listen((p) {
      products.assignAll(p);
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

  List<StockedProduct> get visible => switch (tab.value) {
    GudangTab.barang => products.where((s) => !s.isService).toList(),
    GudangTab.jasa => products.where((s) => s.isService).toList(),
    GudangTab.ready => products.where((s) => !s.isService && s.stock > 0 && s.product.active).toList(),
  };

  StockedProduct? get opened => products.firstWhereOrNull((s) => s.product.id == panelId.value);

  static const _xlsx = XTypeGroup(label: 'Excel', extensions: ['xlsx']);

  Future<bool> _save(List<int> bytes, String name) async => await saveXlsx(db, bytes, name) != null;

  Future<String?> downloadTemplate() async =>
      await _save(buildProductsXlsx([]), 'template-produk.xlsx') ? 'Template tersimpan' : null;

  Future<String?> export() async =>
      await _save(buildProductsXlsx(products), 'produk-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx')
      ? 'Export tersimpan (${products.length} produk)'
      : null;

  /// Kembalikan ringkasan hasil import, atau null bila dibatalkan.
  /// Import berjalan dalam satu transaksi: bila gagal, tidak ada data yang berubah.
  Future<({String summary, List<String> errors})?> import() async {
    final f = await openFile(acceptedTypeGroups: [_xlsx]);
    if (f == null) return null;
    final ImportResult res;
    try {
      res = parseProductsXlsx(await f.readAsBytes());
    } catch (e) {
      return (summary: 'Import gagal', errors: ['File tidak bisa dibaca sebagai .xlsx ($e)']);
    }
    try {
      final r = await db.applyImport(res.rows);
      return (summary: '${r.created} produk baru, ${r.updated} diperbarui', errors: res.errors);
    } catch (e) {
      final msg = e is ArgumentError ? '${e.message}' : '$e';
      return (summary: 'Import dibatalkan, tidak ada data yang berubah', errors: [...res.errors, msg]);
    }
  }
}
