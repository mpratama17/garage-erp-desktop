import 'package:drift/drift.dart';

import '../../core/format.dart';
import '../../core/xlsx.dart';
import '../../db/database.dart';

/// "n 1234  ab" -> "N 1234 AB"
String normalizePlate(String s) => s.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

String _clean(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// No. HP Indonesia setelah dinormalisasi: diawali 0, 9–14 digit.
bool validPhone(String normalized) => RegExp(r'^0\d{8,13}$').hasMatch(normalized);

class CustomerRow {
  CustomerRow({required this.rowNo, required this.name, this.phone, this.car = '', this.plate = '', this.note = ''});
  final int rowNo;
  String name;
  final String? phone;
  String car, plate, note;
}

class CustomerImport {
  CustomerImport(this.rows, this.errors, this.merged);
  final List<CustomerRow> rows;
  final List<String> errors; // baris dilewati
  final List<String> merged; // baris digabung karena no. HP sama — perlu dicek client
}

/// Kolom Google Sheet customer client + export app.
const customerHeaders = ['Nama', 'NO TELEPON', 'JENIS MOBIL', 'PLAT MOBIL', 'Catatan'];

CustomerImport parseCustomersXlsx(List<int> bytes) {
  final t = XlsxTable.decode(bytes);
  if (!t.has('Nama') || !t.has('NO TELEPON')) {
    return CustomerImport([], ['Kolom "Nama" dan "NO TELEPON" wajib ada — pakai template dari tombol Template'], []);
  }
  final out = <CustomerRow>[];
  final errors = <String>[], merged = <String>[];
  final byPhone = <String, CustomerRow>{};
  for (final (rowNo, r) in t.dataRows) {
    final name = _clean(t.text(r, 'Nama'));
    if (name.isEmpty) {
      errors.add('Baris $rowNo: nama kosong');
      continue;
    }
    final rawPhone = t.text(r, 'NO TELEPON');
    final phone = normalizePhone(rawPhone);
    if (phone.isNotEmpty && !validPhone(phone)) {
      errors.add('Baris $rowNo: no. HP "$rawPhone" tidak valid ($name)');
      continue;
    }
    final row = CustomerRow(
      rowNo: rowNo,
      name: name,
      phone: phone.nullIfEmpty,
      // Sheet client memisah merek (JENIS MOBIL) dan model (MOBIL).
      car: _clean('${t.text(r, 'JENIS MOBIL')} ${t.text(r, 'MOBIL')}'),
      plate: normalizePlate(t.text(r, 'PLAT MOBIL')),
      note: t.text(r, 'Catatan'),
    );
    final first = phone.isEmpty ? null : byPhone[phone];
    if (first != null) {
      // Satu no. HP = satu customer. Isi kolom yang masih kosong dari baris berikutnya.
      merged.add('Baris $rowNo ("$name") digabung ke baris ${first.rowNo} ("${first.name}") — no. HP sama $phone');
      if (first.car.isEmpty) first.car = row.car;
      if (first.plate.isEmpty) first.plate = row.plate;
      if (first.note.isEmpty) first.note = row.note;
      continue;
    }
    if (phone.isNotEmpty) byPhone[phone] = row;
    out.add(row);
  }
  return CustomerImport(out, errors, merged);
}

List<int> buildCustomersXlsx(List<Customer> items) => buildXlsx('Customer', customerHeaders, [
  for (final c in items) [c.name, c.phone ?? '', c.car, c.plate, c.note],
]);

extension KontakRepo on AppDb {
  Stream<List<Customer>> watchCustomers() =>
      (select(customers)..orderBy([(c) => OrderingTerm(expression: c.name.collate(Collate.noCase))])).watch();

  /// Simpan customer baru/lama. Melempar [ArgumentError] dengan pesan untuk pengguna.
  Future<int> saveCustomer(CustomersCompanion c) async {
    final name = _clean(c.name.value);
    if (name.isEmpty) throw ArgumentError('Nama wajib diisi');
    final phone = normalizePhone(c.phone.value ?? '');
    if (phone.isNotEmpty && !validPhone(phone)) throw ArgumentError('No. HP tidak valid');
    if (phone.isNotEmpty) {
      final dup =
          await (select(customers)..where(
                (x) => x.phone.equals(phone) & (c.id.present ? x.id.equals(c.id.value).not() : const Constant(true)),
              ))
              .getSingleOrNull();
      if (dup != null) throw ArgumentError('No. HP $phone sudah dipakai ${dup.name}');
    }
    final data = c.copyWith(
      name: Value(name),
      phone: Value(phone.nullIfEmpty),
      car: Value(_clean(c.car.present ? c.car.value : '')),
      plate: Value(normalizePlate(c.plate.present ? c.plate.value : '')),
      note: Value(c.note.present ? c.note.value.trim() : ''),
    );
    if (c.id.present) {
      await (update(customers)..where((x) => x.id.equals(c.id.value))).write(data);
      return c.id.value;
    }
    return into(customers).insert(data);
  }

  // ponytail: hapus langsung; saat modul Penjualan ada, customer yang punya invoice ditolak oleh FK.
  /// Hapus customer yang belum pernah bertransaksi. Yang punya invoice/pemesanan tidak bisa dihapus
  /// (riwayat & laporan tetap utuh) — ubah datanya saja.
  Future<void> deleteCustomer(int id) => transaction(() async {
    final used =
        await (select(invoices)
              ..where((i) => i.customerId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    if (used != null) {
      throw ArgumentError('Customer ini sudah punya transaksi, jadi tidak bisa dihapus. Ubah datanya saja.');
    }
    await (delete(customers)..where((x) => x.id.equals(id))).go();
  });

  /// Aturan pencocokan (satu no. HP = satu orang; nama saja tidak cukup untuk menyamakan dua orang):
  /// - baris ber-HP  -> customer dengan HP itu; bila belum ada, customer TANPA HP dengan nama sama (HP-nya diisi).
  /// - baris tanpa HP -> customer TANPA HP dengan nama sama.
  /// - selain itu customer baru. Nama lama tidak ditimpa; kolom kosong di file tidak menimpa.
  Future<({int created, int updated})> applyCustomerImport(List<CustomerRow> rows) => transaction(() async {
    var created = 0, updated = 0;
    final byPhone = <String, Customer>{};
    final noPhoneByName = <String, Customer>{};
    void index(Customer c) => c.phone != null ? byPhone[c.phone!] = c : noPhoneByName[c.name.toUpperCase()] = c;
    (await select(customers).get()).forEach(index);

    for (final r in rows) {
      final key = r.name.toUpperCase();
      final match = (r.phone != null ? byPhone[r.phone] : null) ?? noPhoneByName[key];
      if (match == null) {
        final id = await into(customers).insert(
          CustomersCompanion.insert(
            name: r.name,
            phone: Value(r.phone),
            car: Value(r.car),
            plate: Value(r.plate),
            note: Value(r.note),
          ),
        );
        index(Customer(id: id, name: r.name, phone: r.phone, car: r.car, plate: r.plate, note: r.note));
        created++;
        continue;
      }
      final gainsPhone = match.phone == null && r.phone != null;
      final data = CustomersCompanion(
        phone: gainsPhone ? Value(r.phone) : const Value.absent(),
        car: r.car.isEmpty ? const Value.absent() : Value(r.car),
        plate: r.plate.isEmpty ? const Value.absent() : Value(r.plate),
        note: r.note.isEmpty ? const Value.absent() : Value(r.note),
      );
      await (update(customers)..where((x) => x.id.equals(match.id))).write(data);
      if (gainsPhone) {
        noPhoneByName.remove(key);
        index(match.copyWith(phone: Value(r.phone)));
      }
      updated++;
    }
    return (created: created, updated: updated);
  });
}
