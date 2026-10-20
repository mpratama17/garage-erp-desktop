import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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

  List<DocSummary> get visible => status.value == null ? docs : docs.where((d) => d.status == status.value).toList();

  DocSummary? get opened => docs.firstWhereOrNull((d) => d.doc.id == panelId.value);

  String employeeName(int? id) {
    final e = employees.firstWhereOrNull((e) => e.id == id);
    return e == null ? '' : (e.active ? e.name : '${e.name} (nonaktif)');
  }

  /// Simpan PDF lalu buka di aplikasi PDF bawaan (Preview: bisa langsung cetak).
  Future<void> openPdf(int docId) async {
    final path = await saveInvoicePdf(db, docId);
    await launchUrl(Uri.file(path));
  }

  /// Buka chat WhatsApp dengan pesan siap kirim + tampilkan file PDF di Finder untuk dilampirkan.
  Future<void> sendWa(int docId) async {
    final path = await saveInvoicePdf(db, docId);
    final s = await db.docSummary(docId);
    final lines = await db.watchLines(docId).first;
    await launchUrl(waUri(s.customerPhone, waMessage(s, lines, await db.allSettings())));
    if (Platform.isMacOS) await Process.run('open', ['-R', path]);
  }
}
