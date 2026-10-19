import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pilih foto/PDF bukti pembayaran lalu salin ke `~/Documents/Garage ERP Bukti/<tahun>/<bulan>/`.
/// Kembalikan path salinan, atau null bila dibatalkan.
// ponytail: folder lokal; sinkron ke Google Drive ditunda (keputusan client) — cukup ganti folder induknya nanti.
Future<String?> pickProof(String label) async {
  final f = await openFile(
    acceptedTypeGroups: [
      const XTypeGroup(label: 'Bukti', extensions: ['jpg', 'jpeg', 'png', 'pdf', 'heic']),
    ],
  );
  if (f == null) return null;
  final now = DateTime.now();
  final dir = Directory(
    p.join(
      (await getApplicationDocumentsDirectory()).path,
      'Garage ERP Bukti',
      '${now.year}',
      now.month.toString().padLeft(2, '0'),
    ),
  );
  await dir.create(recursive: true);
  final safe = label.replaceAll(RegExp(r'[^A-Za-z0-9-]+'), '-');
  final dest = p.join(dir.path, '$safe-${now.millisecondsSinceEpoch}${p.extension(f.path).toLowerCase()}');
  await File(f.path).copy(dest);
  return dest;
}
