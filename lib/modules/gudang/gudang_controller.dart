import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';

import '../../db/database.dart';
import 'gudang_repo.dart';

enum GudangTab { barang, jasa, ready }

class GudangController extends GetxController {
  GudangController(this.db);
  final AppDb db;

  final products = <StockedProduct>[].obs;
  final tab = GudangTab.barang.obs;

  /// Panel kanan: null = tertutup, 0 = produk baru, >0 = id produk yang dibuka.
  final panelId = RxnInt();
  StreamSubscription<List<StockedProduct>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = db.watchProducts().listen(products.assignAll);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  List<StockedProduct> get visible => switch (tab.value) {
    GudangTab.barang => products.where((s) => !s.isService).toList(),
    GudangTab.jasa => products.where((s) => s.isService).toList(),
    GudangTab.ready => products.where((s) => !s.isService && s.stock > 0 && s.product.active).toList(),
  };

  StockedProduct? get opened => products.firstWhereOrNull((s) => s.product.id == panelId.value);

  List<String> get categories =>
      products.map((s) => s.product.category).where((c) => c.isNotEmpty).toSet().toList()..sort();

  static const _xlsx = XTypeGroup(label: 'Excel', extensions: ['xlsx']);

  Future<bool> _save(List<int> bytes, String name) async {
    final loc = await getSaveLocation(suggestedName: name, acceptedTypeGroups: [_xlsx]);
    if (loc == null) return false;
    await File(loc.path).writeAsBytes(bytes);
    return true;
  }

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
    } on ArgumentError catch (e) {
      return (summary: 'Import dibatalkan, tidak ada data yang berubah', errors: [...res.errors, '${e.message}']);
    }
  }
}
