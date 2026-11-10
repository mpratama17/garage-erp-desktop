import 'dart:async';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/range_picker.dart';
import '../../core/xlsx.dart';
import '../../db/database.dart';
import '../../shell.dart' show Nav;
import '../gudang/gudang_repo.dart';

/// Riwayat & tagihan pembelian stok (khusus owner: berisi harga beli).
class PembelianController extends GetxController {
  PembelianController(this.db);
  final AppDb db;

  final purchases = <PurchaseRow>[].obs;
  final purchaseId = RxnInt();
  final range = Rxn<DateTimeRange>(); // filter tanggal beli (inklusif); null = semua
  final paid = RxnBool(); // saringan kartu info Lunas/Belum bayar (R7 #4); null = semua
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

  /// Pembelian dalam rentang (dasar kartu info).
  List<PurchaseRow> inRange() {
    final r = range.value;
    return purchases.where((p) => r == null || r.covers(p.purchase.at)).toList();
  }

  /// Yang tampil di tabel dari [all] (= [inRange]); [tagihan] = hanya yang belum dibayar (menu Tagihan Pembelian).
  List<PurchaseRow> visible(List<PurchaseRow> all, {required bool tagihan}) {
    final want = tagihan ? false : paid.value;
    return all.where((p) => want == null || p.paid == want).toList();
  }

  /// Klik kartu Sudah/Belum dibayar; klik lagi = semua. Dari Tagihan Pembelian pindah ke halaman Pembelian.
  void togglePaid(bool v) {
    final nav = Get.find<Nav>();
    if (nav.pembelianTagihan.value) {
      nav.pembelianTagihan.value = false;
      paid.value = v;
    } else {
      paid.value = paid.value == v ? null : v;
    }
    purchaseId.value = null;
  }

  /// Export daftar yang sedang tampil ke .xlsx, satu baris per pembelian (R4 #3).
  Future<String?> export({required bool tagihan}) => exportXlsx(
    db,
    sheet: tagihan ? 'Tagihan Pembelian' : 'Pembelian',
    file: tagihan ? 'tagihan-pembelian' : 'pembelian',
    range: range.value,
    noun: 'pembelian',
    headers: ['No.', 'Tgl beli', 'Supplier', 'Nota supplier', 'Rekening', 'Total', 'Status', 'Tgl lunas', 'Keterangan'],
    rows: [
      for (final p in visible(inRange(), tagihan: tagihan))
        [
          p.purchase.no,
          tgl(p.purchase.at),
          p.purchase.supplier,
          p.purchase.billNo,
          p.account,
          p.purchase.total,
          p.paid ? 'Lunas' : 'Belum bayar',
          p.paidAt == null ? '' : tgl(p.paidAt!),
          p.purchase.note,
        ],
    ],
  );

  @override
  void onClose() {
    _sub?.cancel();
    _ownerWorker?.dispose();
    super.onClose();
  }
}
