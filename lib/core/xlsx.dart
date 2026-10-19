import 'package:excel/excel.dart';

import 'format.dart';

/// Sheet pertama sebuah file .xlsx, dibaca per nama header (bukan posisi kolom).
/// Header dibandingkan tanpa "*", spasi di ujung, dan huruf besar/kecil.
class XlsxTable {
  XlsxTable._(this.rows, this._col);

  /// Melempar bila file bukan .xlsx yang valid.
  factory XlsxTable.decode(List<int> bytes) {
    final tables = Excel.decodeBytes(bytes).tables.values;
    final rows = tables.isEmpty ? <List<Data?>>[] : tables.first.rows;
    final header = rows.isEmpty ? <Data?>[] : rows.first;
    return XlsxTable._(rows, {for (var i = 0; i < header.length; i++) _key(_text(header[i])): i});
  }

  final List<List<Data?>> rows; // termasuk baris header di index 0
  final Map<String, int> _col;

  static String _key(String h) => h.replaceAll('*', '').trim().toLowerCase();

  bool has(String header) => _col.containsKey(_key(header));

  /// Baris data (tanpa header) beserta nomor barisnya di Excel (mulai 2), baris kosong dilewati.
  Iterable<(int, List<Data?>)> get dataRows sync* {
    for (var i = 1; i < rows.length; i++) {
      if (rows[i].any((c) => _text(c).isNotEmpty)) yield (i + 1, rows[i]);
    }
  }

  Data? _at(List<Data?> row, String header) {
    final i = _col[_key(header)];
    return i == null || i >= row.length ? null : row[i];
  }

  String text(List<Data?> row, String header) => _text(_at(row, header));

  /// "3400000", "3400000.0", "Rp 3.400.000", "Rp 3.400.000,00" -> 3400000. null bila kosong.
  int? number(List<Data?> row, String header) {
    final d = _at(row, header);
    final v = d?.value;
    if (v is IntCellValue) return v.value;
    if (v is DoubleCellValue) return v.value.round();
    final t = _text(d);
    if (t.isEmpty) return null;
    // Rupiah tanpa sen: buang pecahan 1–2 digit di akhir sebelum ambil digit.
    return parseRupiah(t.replaceFirst(RegExp(r'[.,]\d{1,2}$'), ''));
  }

  static String _text(Data? d) => switch (d?.value) {
    null => '',
    TextCellValue(:final value) => (value.text ?? '').trim(),
    IntCellValue(:final value) => '$value',
    DoubleCellValue(:final value) => value == value.roundToDouble() ? '${value.round()}' : '$value',
    final v => v.toString().trim(),
  };
}

/// Buat file .xlsx satu sheet. Nilai: String, int, atau null.
List<int> buildXlsx(String sheet, List<String> headers, Iterable<List<Object?>> rows) {
  final excel = Excel.createExcel();
  final name = excel.getDefaultSheet()!;
  excel.appendRow(name, [for (final h in headers) TextCellValue(h)]);
  for (final r in rows) {
    excel.appendRow(name, [
      for (final v in r)
        switch (v) {
          null => null,
          int() => IntCellValue(v),
          _ => TextCellValue('$v'),
        },
    ]);
  }
  excel.rename(name, sheet);
  return excel.encode()!;
}
