import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Isi semua sheet sebuah .xlsx sebagai grid nilai **tersimpan**: hasil rumus ikut terbaca (paket `excel` hanya
/// memberi teks rumusnya). Nilai sel: `double` (angka & tanggal — tanggal masih nomor seri, ubah dengan
/// [XlsxValues.date]), `String`, `bool`, atau null. Baris & kolom mulai 0 (A1 = `[0][0]`); sel kosong = null.
class XlsxValues {
  XlsxValues._(this.sheets, this._date1904);

  /// Nama sheet → baris → kolom. Urutan sheet = urutan di workbook.
  final Map<String, List<List<Object?>>> sheets;
  final bool _date1904;

  /// Melempar [FormatException] bila bukan .xlsx yang valid.
  factory XlsxValues.decode(List<int> bytes) {
    final Archive zip;
    try {
      zip = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('Bukan file Excel (.xlsx)');
    }
    XmlDocument? doc(String path) {
      final f = zip.findFile(path);
      return f == null ? null : XmlDocument.parse(utf8.decode(f.content as List<int>));
    }

    final workbook = doc('xl/workbook.xml') ?? (throw const FormatException('Bukan file Excel (.xlsx)'));
    final date1904 = workbook.findAllElements('workbookPr').any((e) => e.getAttribute('date1904') == '1');
    // Teks bersama: satu <si> bisa berisi beberapa potongan <r><t> (rich text) → disambung.
    final shared = [
      for (final si in doc('xl/sharedStrings.xml')?.findAllElements('si') ?? const <XmlElement>[])
        si.findAllElements('t').map((t) => t.innerText).join(),
    ];
    // Nama sheet → file XML-nya lewat relasi (urutan file tidak selalu sama dengan urutan sheet).
    final rels = {
      for (final r in doc('xl/_rels/workbook.xml.rels')?.findAllElements('Relationship') ?? const <XmlElement>[])
        r.getAttribute('Id')!: r.getAttribute('Target')!,
    };
    final sheets = <String, List<List<Object?>>>{};
    for (final s in workbook.findAllElements('sheet')) {
      final id = s.attributes.firstWhere((a) => a.name.local == 'id' && a.name.prefix != null).value;
      final target = rels[id]!;
      final path = target.startsWith('/') ? target.substring(1) : 'xl/$target';
      sheets[s.getAttribute('name')!] = _grid(doc(path), shared);
    }
    return XlsxValues._(sheets, date1904);
  }

  /// Nomor seri tanggal Excel → tanggal lokal (jam diabaikan). Selain angka → null.
  DateTime? date(Object? v) {
    if (v is! double) return null;
    final base = _date1904 ? DateTime(1904) : DateTime(1899, 12, 30);
    return DateTime(base.year, base.month, base.day + v.floor());
  }

  static List<List<Object?>> _grid(XmlDocument? sheet, List<String> shared) {
    final rows = <List<Object?>>[];
    for (final row in sheet?.findAllElements('row') ?? const <XmlElement>[]) {
      final r = int.parse(row.getAttribute('r')!) - 1;
      while (rows.length <= r) {
        rows.add([]);
      }
      final cells = rows[r];
      for (final c in row.findElements('c')) {
        // Sel kosong tidak ditulis di XML → posisi kolom diambil dari referensinya ("AB12"), bukan urutan.
        final col = _column(c.getAttribute('r')!);
        final v = c.getElement('v')?.innerText;
        final value = switch (c.getAttribute('t')) {
          's' => v == null ? null : shared[int.parse(v)],
          'str' || 'e' => v,
          'inlineStr' => c.findAllElements('t').map((t) => t.innerText).join(),
          'b' => v == null ? null : v == '1',
          _ => v == null ? null : double.tryParse(v),
        };
        if (value == null || value == '') continue;
        while (cells.length <= col) {
          cells.add(null);
        }
        cells[col] = value;
      }
    }
    return rows;
  }

  static int _column(String ref) {
    var n = 0;
    for (final ch in ref.codeUnits) {
      if (ch < 65 || ch > 90) break; // huruf A–Z, berhenti di angka baris
      n = n * 26 + ch - 64;
    }
    return n - 1;
  }
}
