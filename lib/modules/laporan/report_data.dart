/// Satu baris laporan; [bold] untuk subjudul/total. Angka (int) tampil sebagai Rupiah kecuali kolom ditandai jumlah.
class RRow {
  const RRow(this.cells, {this.bold = false});
  final List<Object?> cells;
  final bool bold;
}

/// Hasil satu laporan siap tampil & export: judul, header kolom, baris, catatan kaki.
class ReportData {
  const ReportData(this.title, this.headers, this.rows, {this.notes = const [], this.countCols = const {}});
  final String title;
  final List<String> headers;
  final List<RRow> rows;
  final List<String> notes;

  /// Indeks kolom berisi jumlah (qty/hari), bukan Rupiah.
  final Set<int> countCols;
}
