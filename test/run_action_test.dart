import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/core/ui.dart';

void main() {
  testWidgets('runAction menolak aksi kedua selama aksi pertama berjalan (klik dobel Simpan)', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );

    var runs = 0;
    final gate = Completer<void>();
    final first = runAction(ctx, () async {
      runs++;
      await gate.future;
    });
    final second = await runAction(ctx, () async => runs++);
    expect(second, isFalse);
    await tester.pump();
    expect(find.text('Masih memproses aksi sebelumnya…'), findsOneWidget);

    gate.complete();
    expect(await first, isTrue);
    expect(runs, 1);

    // Setelah selesai, aksi berikutnya jalan lagi.
    expect(await runAction(ctx, () async => runs++), isTrue);
    expect(runs, 2);
    await tester.pump(const Duration(seconds: 10)); // habiskan timer notifikasi
  });
}
