// Render layar ke PNG untuk review visual (bukan test CI):
//   flutter test tool/preview --update-goldens
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workshop_erp_flutter/core/owner.dart';
import 'package:workshop_erp_flutter/db/database.dart';
import 'package:workshop_erp_flutter/main.dart';

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
  }
  await inter.load();
  final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

void main() {
  testWidgets('shell', (tester) async {
    await tester.runAsync(() async {
      await initializeDateFormatting('id');
      await _loadFonts();
    });
    final db = Get.put(AppDb(NativeDatabase.memory()));
    Get.put(OwnerController(db));
    await tester.runAsync(() => db.setSetting('shop_name', 'Star Garage'));
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const App());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await expectLater(find.byType(App), matchesGoldenFile('shell.png'));
    Get.find<OwnerController>().isOwner.value = true;
    await tester.tap(find.text('Pengaturan'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    await expectLater(find.byType(App), matchesGoldenFile('pengaturan.png'));
    Get.find<OwnerController>().lock(); // hentikan timer auto-lock
    await tester.runAsync(db.close);
  });
}
