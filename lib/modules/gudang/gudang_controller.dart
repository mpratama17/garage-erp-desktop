import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';

import '../../core/owner.dart';
import '../../core/xlsx.dart';
import '../../db/database.dart';
import 'gudang_repo.dart';

enum GudangTab { barang, jasa, ready, pembelian }

class GudangController extends GetxController {
  GudangController(this.db);
  final AppDb db;

  final products = <StockedProduct>[].obs;
  final tab = GudangTab.barang.obs;

  /// Panel kanan: null = tertutup, 0 = produk baru, >0 = id produk yang dibuka.
  final panelId = RxnInt();
  StreamSubscription<List<StockedProduct>>? _sub;

  /// Tab Pembelian (khusus owner): daftar kosong saat terkunci; [purchaseId] = pembelian yang dibuka.
  final purchases = <({Purchase purchase, String account})>[].obs;
  final purchaseId = RxnInt();
  StreamSubscription<Object?>? _purchaseSub;
  Worker? _ownerWorker;

  @override
  void onInit() {
    super.onInit();
    _sub = db.watchProducts().listen(products.assignAll);
    _ownerWorker = ever(Get.find<OwnerController>().isOwner, (_) => _ownerChanged());
    _ownerChanged();
  }

  void _ownerChanged() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
    purchases.clear();
    purchaseId.value = null;
    if (Get.find<OwnerController>().isOwner.value) _purchaseSub = db.watchPurchases().listen(purchases.assignAll);
  }

  @override
  void onClose() {
    _sub?.cancel();
    _purchaseSub?.cancel();
    _ownerWorker?.dispose();
    super.onClose();
  }

  List<StockedProduct> get visible => switch (tab.value) {
    GudangTab.barang => products.where((s) => !s.isService).toList(),
    GudangTab.jasa => products.where((s) => s.isService).toList(),
    GudangTab.ready => products.where((s) => !s.isService && s.stock > 0 && s.product.active).toList(),
    GudangTab.pembelian => const [],
  };

  StockedProduct? get opened => products.firstWhereOrNull((s) => s.product.id == panelId.value);

  List<String> get categories =>
      products.map((s) => s.product.category).where((c) => c.isNotEmpty).toSet().toList()..sort();

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
