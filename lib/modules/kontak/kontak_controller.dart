import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';

import '../../db/database.dart';
import 'kontak_repo.dart';

class KontakController extends GetxController {
  KontakController(this.db);
  final AppDb db;

  final customers = <Customer>[].obs;

  /// Panel kanan: null = tertutup, 0 = customer baru, >0 = id yang dibuka.
  final panelId = RxnInt();
  StreamSubscription<List<Customer>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = db.watchCustomers().listen(customers.assignAll);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Customer? get opened => customers.firstWhereOrNull((c) => c.id == panelId.value);

  static const _xlsx = XTypeGroup(label: 'Excel', extensions: ['xlsx']);

  Future<String?> _save(List<int> bytes, String name) async {
    final loc = await getSaveLocation(suggestedName: name, acceptedTypeGroups: [_xlsx]);
    if (loc == null) return null;
    await File(loc.path).writeAsBytes(bytes);
    return loc.path;
  }

  Future<String?> downloadTemplate() async =>
      await _save(buildCustomersXlsx([]), 'template-customer.xlsx') == null ? null : 'Template tersimpan';

  Future<String?> export() async =>
      await _save(
            buildCustomersXlsx(customers),
            'customer-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx',
          ) ==
          null
      ? null
      : 'Export tersimpan (${customers.length} customer)';

  /// Ringkasan + daftar baris dilewati/digabung, atau null bila dibatalkan.
  Future<({String summary, List<String> notes})?> import() async {
    final f = await openFile(acceptedTypeGroups: [_xlsx]);
    if (f == null) return null;
    final CustomerImport res;
    try {
      res = parseCustomersXlsx(await f.readAsBytes());
    } catch (e) {
      return (summary: 'Import gagal', notes: ['File tidak bisa dibaca sebagai .xlsx ($e)']);
    }
    final ({int created, int updated}) r;
    try {
      r = await db.applyCustomerImport(res.rows);
    } catch (e) {
      return (summary: 'Import dibatalkan, tidak ada data yang berubah', notes: ['$e']);
    }
    return (
      summary: '${r.created} customer baru, ${r.updated} diperbarui',
      notes: [
        if (res.errors.isNotEmpty) ...['Dilewati (perbaiki di file):', ...res.errors],
        if (res.merged.isNotEmpty) ...[
          'Digabung karena no. HP sama (cek apakah memang orang yang sama):',
          ...res.merged,
        ],
      ],
    );
  }
}
