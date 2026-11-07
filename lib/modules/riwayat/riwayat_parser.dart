import '../../core/xlsx_values.dart';

/// Pembaca spreadsheet catatan lama client ("PEMASUKAN + HITUNG UANG"): satu sheet per bulan, kiri = penjualan
/// per baris barang (A–P), kanan = daftar pengeluaran (V–AA). Sheet ringkasan ("UANG …") dilewati.
/// Posisi kolom dipatok ke format itu (import sekali jalan, bukan importer umum) dan diperiksa lewat judul kolom.
///
/// Hanya membaca nilai mentah + total yang dihitung sheet sendiri (hasil rumus) untuk pembanding; tidak
/// menyentuh database. Keputusan bisnis (rekening, kategori, produk, customer) ada di riwayat_repo.dart.

// Kolom penjualan (A = 0).
const _date = 0, _plate = 1, _car = 2, _owner = 3, _group = 4, _item = 5, _qty = 6, _price = 7, _disc = 9;
const _cost = 10, _costTotal = 11, _total = 14, _pay = 15;
// Kolom pengeluaran.
const _xDate = 21, _xName = 22, _xQty = 23, _xAmount = 24, _xAccount = 25, _xCategory = 26;

class OldLine {
  OldLine({required this.group, required this.name, required this.qty, required this.price, this.cost});
  final String group, name; // group = kolom BARANG pertama (mis. "FL", "JASA PASANG")
  final int qty, price;
  final int? cost; // harga beli per unit; null = kosong di sheet
}

class OldPayment {
  OldPayment(this.account, this.amount);
  final String account; // teks apa adanya dari kolom PEMBAYARAN
  final int amount;
}

class OldInvoice {
  OldInvoice({
    required this.sheet,
    required this.row,
    required this.at,
    required this.customer,
    required this.car,
    required this.plate,
  });
  final String sheet;
  final int row; // nomor baris Excel (mulai 1)
  final DateTime at;
  final String customer, car, plate;
  final lines = <OldLine>[];
  final payments = <OldPayment>[]; // biasanya satu; dua bila dibayar dengan dua cara
  int sheetDiscount = 0; // isi kolom DISKON (informasi; total yang dipakai = kolom TOTAL PENJUALAN)

  int get subtotal => lines.fold(0, (s, l) => s + l.qty * l.price);

  /// Uang yang diterima menurut sheet = patokan total invoice.
  int get total => payments.fold(0, (s, p) => s + p.amount);
}

class OldExpense {
  OldExpense({
    required this.sheet,
    required this.row,
    required this.at,
    required this.name,
    required this.qty,
    required this.amount,
    required this.account,
    required this.category,
  });
  final String sheet;
  final int row;
  final DateTime at;
  final String name, qty, account, category; // qty = teks kolom KET/JUMLAH (bisa "10", bisa "SEP")
  final int amount; // positif = uang keluar
}

/// Pembanding per sheet: total yang ditulis sheet sendiri vs jumlah baris yang terbaca.
class SheetCheck {
  SheetCheck(this.sheet);
  final String sheet;
  int? salesLabel, expenseLabel; // sel "TOTAL" & "TOTAL PENGELUARAN"; null = tidak ditemukan
  int sales = 0, expenses = 0, invoices = 0, expenseRows = 0;
  bool get ok => (salesLabel ?? sales) == sales && (expenseLabel ?? expenses) == expenses;
}

class OldData {
  final invoices = <OldInvoice>[];
  final expenses = <OldExpense>[];
  final checks = <SheetCheck>[];
  final problems = <String>[]; // "SHEET baris N: …" — ditampilkan di pratinjau, tidak menghentikan import
}

String _text(Object? v) => switch (v) {
  null => '',
  double d when d == d.roundToDouble() => '${d.round()}',
  _ => '$v'.replaceAll(RegExp(r'\s+'), ' ').trim(),
};

int? _int(Object? v) => v is double ? v.round() : null;

OldData parseOldWorkbook(XlsxValues x) {
  final out = OldData();
  for (final MapEntry(key: sheet, value: rows) in x.sheets.entries) {
    if (sheet.toUpperCase().startsWith('UANG')) continue;
    Object? at(List<Object?> r, int c) => c < r.length ? r[c] : null;
    final head = rows.isEmpty ? const <Object?>[] : rows.first;
    String h(int c) => _text(at(head, c)).toUpperCase();
    if (h(_date) != 'TANGGAL' || h(_pay) != 'PEMBAYARAN' || h(_xDate) != 'TANGGAL' || h(_xAmount) != 'HARGA') {
      out.problems.add('$sheet: susunan kolom tidak dikenal — sheet dilewati');
      continue;
    }
    final check = SheetCheck(sheet);
    out.checks.add(check);
    OldInvoice? cur;
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i], row = i + 1;
      String where() => '$sheet baris $row';

      // --- penjualan: baris barang = kolom BARANG (nama) terisi; tanggal terisi = invoice baru.
      final item = _text(at(r, _item));
      final rowDate = x.date(at(r, _date)), rowTotal = _int(at(r, _total));
      if (item.isEmpty && rowDate != null && rowTotal != null && rowTotal != 0) {
        // Uang masuk tanpa rincian barang (DP/pelunasan yang barangnya tidak ditulis): ikut total sheet,
        // jadi invoice tanpa baris — repo memberinya satu baris "Penjualan".
        final v = OldInvoice(
          sheet: sheet,
          row: row,
          at: rowDate,
          customer: _text(at(r, _owner)),
          car: _text(at(r, _car)),
          plate: _text(at(r, _plate)).toUpperCase(),
        )..payments.add(OldPayment(_text(at(r, _pay)), rowTotal));
        out.invoices.add(v);
        cur = v; // baris barang tanpa tanggal sesudahnya milik uang masuk ini, bukan invoice sebelumnya
        check.invoices++;
        check.sales += rowTotal;
      }
      if (item.isNotEmpty) {
        final date = x.date(at(r, _date));
        if (date != null) {
          cur = OldInvoice(
            sheet: sheet,
            row: row,
            at: date,
            customer: _text(at(r, _owner)),
            car: _text(at(r, _car)),
            plate: _text(at(r, _plate)).toUpperCase(),
          );
          out.invoices.add(cur);
          check.invoices++;
        }
        if (cur == null) {
          out.problems.add('${where()}: barang "$item" tanpa tanggal invoice di atasnya — dilewati');
        } else {
          final qty = _int(at(r, _qty)), price = _int(at(r, _price));
          if (qty == null || qty <= 0) out.problems.add('${where()}: qty "$item" kosong — dianggap 1');
          if (price == null) out.problems.add('${where()}: harga jual "$item" kosong — dianggap 0');
          // Harga beli satuan dipakai (kolom total beli di sheet tidak selalu rumus qty × satuan). Kecuali
          // qty > 1 dan "satuan" = total beli → yang tertulis ternyata total, dibagi qty.
          var cost = _int(at(r, _cost));
          if (cost != null && cost > 0 && qty != null && qty > 1 && cost == _int(at(r, _costTotal))) {
            out.problems.add('${where()}: harga beli satuan "$item" berisi total — dibagi qty');
            cost = (cost / qty).round();
          }
          cur.lines.add(
            OldLine(
              group: _text(at(r, _group)),
              name: item,
              qty: qty == null || qty <= 0 ? 1 : qty,
              price: price ?? 0,
              cost: cost,
            ),
          );
          cur.sheetDiscount += _int(at(r, _disc)) ?? 0;
          // Kolom TOTAL PENJUALAN biasanya hanya terisi di baris pertama invoice; terisi di baris lanjutan =
          // pembayaran kedua (dibayar dengan dua cara) — atau satu-satunya bila baris pertama kosong.
          final paid = _int(at(r, _total));
          if (paid != null && paid != 0) {
            cur.payments.add(OldPayment(_text(at(r, _pay)), paid));
            check.sales += paid;
          }
        }
      }

      // --- pengeluaran (blok kanan, baris yang sama tapi data terpisah).
      final xDate = x.date(at(r, _xDate));
      final rawAmount = at(r, _xAmount);
      if (xDate != null && rawAmount != null) {
        final amount = _int(rawAmount);
        final name = _text(at(r, _xName));
        if (amount == null) {
          out.problems.add('${where()}: nominal pengeluaran "$name" bukan angka ("${_text(rawAmount)}") — dilewati');
        } else if (amount <= 0) {
          out.problems.add('${where()}: nominal pengeluaran "$name" nol/minus — dilewati');
        } else {
          out.expenses.add(
            OldExpense(
              sheet: sheet,
              row: row,
              at: xDate,
              name: name,
              qty: _text(at(r, _xQty)),
              amount: amount,
              account: _text(at(r, _xAccount)),
              category: _text(at(r, _xCategory)).toUpperCase(),
            ),
          );
          check.expenses += amount;
          check.expenseRows++;
        }
      }

      // --- total yang ditulis sheet sendiri (sel judul, lalu angka di kanannya).
      for (var c = _pay + 1; c < r.length - 1; c++) {
        final label = _text(r[c]).toUpperCase();
        if (label == 'TOTAL') check.salesLabel ??= _int(r[c + 1]);
        if (label.startsWith('TOTAL PENGELUA')) check.expenseLabel ??= _int(r[c + 1]);
      }
    }
    for (final inv in out.invoices.where((v) => v.sheet == sheet && v.payments.isEmpty)) {
      out.problems.add('$sheet baris ${inv.row}: total penjualan kosong — invoice dianggap belum dibayar');
    }
  }
  return out;
}
