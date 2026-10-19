import 'package:intl/intl.dart';

const ppnRate = 11; // persen

final _rp = NumberFormat.decimalPattern('id');
String rp(int v) => _rp.format(v);

/// Harga satu baris setelah diskon persen, dibulatkan ke rupiah.
int lineTotal(int qty, int price, int discountPct) =>
    (qty * price * (100 - discountPct) / 100).round();

int ppnOf(int subtotal) => (subtotal * ppnRate / 100).round();

/// 08xxxxxxxx; buang spasi/strip/newline, ubah +62/62 jadi 0.
String normalizePhone(String raw) {
  var p = raw.replaceAll(RegExp(r'\D'), '');
  if (p.startsWith('62')) p = '0${p.substring(2)}';
  if (p.isNotEmpty && !p.startsWith('0')) p = '0$p';
  return p;
}

const _satuan = [
  '', 'satu', 'dua', 'tiga', 'empat', 'lima', 'enam', 'tujuh', 'delapan',
  'sembilan', 'sepuluh', 'sebelas',
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
  final words = n == 0 ? 'nol' : _t(n);
  return '${words.split(' ').where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')} Rupiah';
}
