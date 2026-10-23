import 'package:intl/intl.dart';

final _rp = NumberFormat.decimalPattern('id');
final _date = DateFormat('dd/MM/yyyy');

/// 2250000 -> "2.250.000"
String rp(int v) => _rp.format(v);

/// 2250000 -> "Rp 2.250.000"
String rupiah(int v) => 'Rp ${rp(v)}';

/// Ringkas untuk sumbu grafik: 12400000 -> "12,4 jt", 750000 -> "750 rb", 999600 -> "1 jt".
String rpShort(int v) {
  const units = [(1e3, 'rb'), (1e6, 'jt'), (1e9, 'M')];
  final a = v.abs();
  var out = '$a';
  for (var i = units.length - 1; i >= 0; i--) {
    if (a < units[i].$1 * 0.9995) continue; // 999.600 dibulatkan jadi 1 jt, bukan "1000 rb"
    final x = a / units[i].$1;
    final r = x < 9.95 ? (x * 10).round() / 10 : x.roundToDouble();
    out = '${r == r.roundToDouble() ? r.round() : r.toString().replaceAll('.', ',')} ${units[i].$2}';
    break;
  }
  return v < 0 ? '-$out' : out;
}

/// "Rp 2.250.000" / "2.250.000" / "2250000" -> 2250000. Kosong -> 0.
int parseRupiah(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;

String tgl(DateTime d) => _date.format(d);

/// Awal hari sesudah [d]: batas eksklusif untuk rentang tanggal inklusif (query memakai [from, to)).
DateTime dayAfter(DateTime d) => DateTime(d.year, d.month, d.day + 1);

/// 08xxxxxxxx; buang spasi/strip/newline, ubah +62/62 jadi 0.
String normalizePhone(String raw) {
  var p = raw.replaceAll(RegExp(r'\D'), '');
  if (p.startsWith('0062')) p = p.substring(2); // awalan sambungan internasional
  if (p.startsWith('62')) p = '0${p.substring(2)}';
  if (p.isNotEmpty && !p.startsWith('0')) p = '0$p';
  return p;
}

/// 081234567890 -> 0812-3456-7890
String displayPhone(String p) {
  final parts = <String>[];
  for (var i = 0; i < p.length; i += 4) {
    parts.add(p.substring(i, i + 4 > p.length ? p.length : i + 4));
  }
  return parts.join('-');
}

const _satuan = [
  '',
  'satu',
  'dua',
  'tiga',
  'empat',
  'lima',
  'enam',
  'tujuh',
  'delapan',
  'sembilan',
  'sepuluh',
  'sebelas',
];

String _t(int n) {
  if (n < 12) return _satuan[n];
  if (n < 20) return '${_t(n - 10)} belas';
  if (n < 100) return '${_t(n ~/ 10)} puluh ${_t(n % 10)}';
  if (n < 200) return 'seratus ${_t(n - 100)}';
  if (n < 1000) return '${_t(n ~/ 100)} ratus ${_t(n % 100)}';
  if (n < 2000) return 'seribu ${_t(n - 1000)}';
  if (n < 1000000) return '${_t(n ~/ 1000)} ribu ${_t(n % 1000)}';
  if (n < 1000000000) return '${_t(n ~/ 1000000)} juta ${_t(n % 1000000)}';
  return '${_t(n ~/ 1000000000)} miliar ${_t(n % 1000000000)}';
}

/// 2250000 -> "Dua Juta Dua Ratus Lima Puluh Ribu Rupiah"
String terbilang(int n) {
  final words = n == 0 ? 'nol' : '${n < 0 ? 'minus ' : ''}${_t(n.abs())}';
  return '${words.split(' ').where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')} Rupiah';
}

extension StringBlank on String {
  String ifEmpty(String other) => isEmpty ? other : this;
  String? get nullIfEmpty => isEmpty ? null : this;
}
