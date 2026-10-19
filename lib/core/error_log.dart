import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Semua error Flutter/Dart juga ditulis ke ~/Library/Logs/Garage ERP/app.log,
/// supaya bisa dibaca developer atau dikirim client (Debug Console tidak tersimpan).
// ponytail: satu file, dipotong saat > 1 MB; cukup untuk satu PC kasir.
void installErrorLog() {
  final home = Platform.environment['HOME'] ?? '.';
  final file = File(p.join(home, 'Library', 'Logs', 'Garage ERP', 'app.log'));
  try {
    file.parent.createSync(recursive: true);
    if (file.existsSync() && file.lengthSync() > 1024 * 1024) file.writeAsStringSync('');
  } on FileSystemException {
    return; // tanpa log file pun app tetap jalan
  }

  void write(Object error, StackTrace? stack) {
    try {
      file.writeAsStringSync('[${DateTime.now().toIso8601String()}] $error\n$stack\n\n', mode: FileMode.append);
    } on FileSystemException {
      // abaikan: log adalah alat bantu, bukan fungsi utama
    }
  }

  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    write(details.exceptionAsString(), details.stack);
    previous?.call(details); // tetap tampil di Debug Console
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    write(error, stack);
    debugPrint('Uncaught: $error\n$stack');
    return true;
  };
}
