import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

import 'core/error_log.dart';
import 'core/owner.dart';
import 'core/theme.dart';
import 'db/database.dart';
import 'shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorLog();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Inter'], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  await initializeDateFormatting('id');

  final db = Get.put(AppDb());
  Get.put(OwnerController(db));

  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  windowManager.addListener(_BackupOnClose(db));
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(title: 'Workshop ERP', size: Size(1440, 900), minimumSize: Size(1280, 720), center: true),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(const App());
  // Backup harian saat app dibuka. Gagal backup tidak boleh menghalangi app terbuka;
  // tanggal "Backup terakhir" di sidebar yang tidak bergerak menjadi tandanya.
  db.autoBackup().catchError((Object e) => debugPrint('Backup gagal: $e'));
}

class _BackupOnClose extends WindowListener {
  _BackupOnClose(this.db);
  final AppDb db;

  @override
  Future<void> onWindowClose() async {
    try {
      // Folder Google Drive bisa lambat/offline: jangan sampai jendela tidak bisa ditutup.
      await db.autoBackup(force: true).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Backup saat tutup gagal: $e');
    } finally {
      await db.close();
      await windowManager.destroy();
    }
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Workshop ERP',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    locale: const Locale('id'),
    supportedLocales: const [Locale('id')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (_, child) => Listener(onPointerDown: (_) => Get.find<OwnerController>().touch(), child: child),
    home: const Shell(),
  );
}
