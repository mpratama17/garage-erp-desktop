import 'dart:async';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

import '../../core/owner.dart';
import '../../db/database.dart';
import '../gudang/gudang_repo.dart';

/// Riwayat & tagihan pembelian stok (khusus owner: berisi harga beli).
class PembelianController extends GetxController {
  PembelianController(this.db);
  final AppDb db;

  final purchases = <PurchaseRow>[].obs;
  final purchaseId = RxnInt();
  final range = Rxn<DateTimeRange>(); // filter tanggal beli (inklusif); null = semua
  StreamSubscription<Object?>? _sub;
  Worker? _ownerWorker;

  @override
  void onInit() {
    super.onInit();
    _ownerWorker = ever(Get.find<OwnerController>().isOwner, (_) => _ownerChanged());
    _ownerChanged();
  }

  void _ownerChanged() {
    _sub?.cancel();
    _sub = null;
    purchases.clear();
    purchaseId.value = null;
    if (Get.find<OwnerController>().isOwner.value) _sub = db.watchPurchases().listen(purchases.assignAll);
  }

  @override
  void onClose() {
    _sub?.cancel();
    _ownerWorker?.dispose();
    super.onClose();
  }
}
