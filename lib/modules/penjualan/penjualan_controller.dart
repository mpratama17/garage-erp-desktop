import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' show DateTimeRange;

import '../../core/range_picker.dart';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/xlsx.dart';
import '../../db/database.dart';
import '../gudang/gudang_repo.dart';
import '../kontak/kontak_repo.dart';
import 'invoice_pdf.dart';
import 'penjualan_repo.dart';

class PenjualanController extends GetxController {
  PenjualanController(this.db);
  final AppDb db;

  final kind = DocKind.invoice.obs;
  final status = Rxn<PayStatus>(); // filter; null = semua
  final range = Rxn<DateTimeRange>(); // filter tanggal dokumen (inklusif); null = semua tanggal
  final docs = <DocSummary>[].obs;
  final panelId = RxnInt();

  // Data pendukung form invoice.
  final products = <StockedProduct>[].obs;
  final customers = <Customer>[].obs;
  final technicians = <Employee>[].obs; // teknisi aktif (untuk dipilih)
  final employees = <Employee>[].obs; // semua karyawan (untuk menampilkan nama, termasuk yang nonaktif)
  final accounts = <Account>[].obs; // rekening aktif (untuk dipilih)
  final allAccounts = <Account>[].obs; // semua rekening (untuk menampilkan nama)

  final _subs = <StreamSubscription<Object?>>[];
  StreamSubscription<List<DocSummary>>? _docSub;

  @override
  void onInit() {
    super.onInit();
    _subs
      ..add(db.watchProducts().listen(products.assignAll))
      ..add(db.watchCustomers().listen(customers.assignAll))
      ..add(db.watchTechnicians().listen(technicians.assignAll))
      ..add(db.select(db.employees).watch().listen(employees.assignAll))
      ..add(db.select(db.accounts).watch().listen(allAccounts.assignAll))
      ..add(db.watchActiveAccounts().listen(accounts.assignAll));
    ever(kind, (_) => _listen());
    _listen();
  }

  void _listen() {
    _docSub?.cancel();
    panelId.value = null;
    status.value = null;
    _docSub = db.watchDocs(kind.value).listen(docs.assignAll);
  }

  @override
  void onClose() {
    _docSub?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }

  /// Pemesanan yang sudah dibuatkan invoice pindah ke Tagihan: tidak tampil di daftar Pemesanan
  /// kecuali dipilih lewat filter "Sudah diinvoice".
  List<DocSummary> get visible {
    final r = range.value;
    return docs.where((d) {
      if (r != null && !r.covers(d.doc.at)) return false;
      if (status.value != null) return d.status == status.value;
      return kind.value != DocKind.order || !d.hasInvoice;
    }).toList();
  }

  DocSummary? get opened => docs.firstWhereOrNull((d) => d.doc.id == panelId.value);

  String employeeName(int? id) {
    final e = employees.firstWhereOrNull((e) => e.id == id);
    return e == null ? '' : (e.active ? e.name : '${e.name} (nonaktif)');
  }

  /// Export daftar yang sedang tampil (rentang tanggal + filter status) ke .xlsx, satu baris per dokumen (R4 #3).
  Future<String?> export() => exportXlsx(
    db,
    sheet: kind.value == DocKind.order ? 'Pemesanan' : 'Tagihan',
    file: kind.value == DocKind.order ? 'pemesanan' : 'tagihan',
    range: range.value,
    noun: 'dokumen',
    headers: [
      'No.',
      'Tanggal',
      'Jatuh tempo',
      'Customer',
      'No. HP',
      'Mobil',
      'Plat',
      'Subtotal',
      'Diskon',
      'PPN',
      'Total',
      'Dibayar',
      'Sisa',
      'Status',
    ],
    rows: [
      for (final s in visible)
        [
          s.doc.no,
          tgl(s.doc.at),
          s.doc.dueAt == null ? '' : tgl(s.doc.dueAt!),
          s.customerName ?? 'UMUM',
          s.customerPhone ?? '',
          s.doc.car,
          s.doc.plate,
          s.subtotal,
          s.doc.discount,
          s.doc.tax,
          s.total,
          s.paid,
          s.outstanding,
          s.status.label,
        ],
    ],
  );

  /// Simpan PDF lalu buka di aplikasi PDF bawaan (Preview: bisa langsung cetak).
  Future<void> openPdf(int docId) async {
    final path = await saveInvoicePdf(db, docId);
    await launchUrl(Uri.file(path));
  }

  /// Buka chat WhatsApp dengan pesan siap kirim + tampilkan file PDF di Finder untuk dilampirkan.
  Future<void> sendWa(int docId) async {
    final path = await saveInvoicePdf(db, docId);
    final s = await db.docSummary(docId);
    final lines = await db.linesQuery(docId).get();
    await launchUrl(waUri(s.customerPhone, waMessage(s, lines, await db.allSettings())));
    if (Platform.isMacOS) await Process.run('open', ['-R', path]);
  }
}
