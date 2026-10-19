import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/core/owner.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('PIN benar membuka owner walau ada listener yang langsung memuat data owner', (tester) async {
    final db = AppDb(NativeDatabase.memory());
    await tester.runAsync(() => db.setPin('qwerty'));
    final owner = Get.put(OwnerController(db));
    addTearDown(() async {
      Get.reset();
      await tester.runAsync(db.close);
    });
    // Seperti Dashboard/Kas: begitu owner terbuka, langsung minta saldo (repo menolak bila belum dibuka).
    Object? error;
    ever(owner.isOwner, (bool v) {
      if (!v) return;
      try {
        db.watchBalances();
      } catch (e) {
        error = e;
      }
    });

    late bool ok;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) =>
              TextButton(onPressed: () async => ok = await owner.ensure(context), child: const Text('buka')),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'qwerty');
    await tester.tap(find.text('Buka'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    expect(error, isNull);
    expect((ok, owner.isOwner.value, db.ownerUnlocked), (true, true, true));
    owner.lock(); // hentikan timer auto-lock
  });
}
