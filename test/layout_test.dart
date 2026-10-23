// Semua halaman harus muat di lebar setengah layar MacBook (Split View) tanpa overflow.
import 'package:flutter/material.dart' show FlutterError, SizedBox, Size;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:garage_erp_desktop/core/owner.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/main.dart';
import 'package:garage_erp_desktop/modules/kontak/kontak_controller.dart';
import 'package:garage_erp_desktop/modules/laporan/laporan_controller.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_controller.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart' show DocKind;
import 'package:garage_erp_desktop/shell.dart';

void main() {
  for (final width in [720.0, 1440.0]) {
    testWidgets('semua halaman muat di lebar ${width.toInt()}', (tester) async {
      final db = Get.put(AppDb(NativeDatabase.memory())..ownerUnlocked = true);
      Get.put(OwnerController(db)).isOwner.value = true;
      await tester.runAsync(() async {
        await initializeDateFormatting('id');
        // path_provider tidak ada di test: beri folder eksplisit.
        await db.setSetting('backup_dir', Directory.systemTemp.createTempSync('bk').path);
        await db.setSetting('export_dir', Directory.systemTemp.createTempSync('ex').path);
      });
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;

      Future<void> settle() async {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Kumpulkan semua error layout per halaman (bukan berhenti di yang pertama).
      final errors = <String>[];
      var where = 'start';
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        final lines = d.toString().split('\n');
        final i = lines.indexWhere((l) => l.contains('relevant error-causing widget'));
        final loc = i < 0 ? '' : lines.skip(i + 1).take(2).join(' ').trim();
        errors.add('[$where] ${d.exceptionAsString().split('\n').first} — $loc');
      };
      addTearDown(() => FlutterError.onError = old);

      await tester.pumpWidget(const App());
      await settle();
      final nav = Get.find<Nav>();
      for (final p in AppPage.values) {
        where = p.label;
        nav.page.value = p;
        await settle();
      }
      // Sub-halaman: Penjualan (tagihan/pemesanan), Pembelian ▸ tagihan, tab Kontak, tiap laporan.
      where = 'sub-halaman';
      Get.find<PenjualanController>().kind.value = DocKind.order;
      nav.page.value = AppPage.penjualan;
      await settle();
      nav.pembelianTagihan.value = true;
      nav.page.value = AppPage.pembelian;
      await settle();
      nav.page.value = AppPage.kontak;
      for (final t in KontakTab.values) {
        Get.find<KontakController>().tab.value = t;
        where = 'Kontak ${t.name}';
        await settle();
      }
      nav.page.value = AppPage.laporan;
      for (final r in LapReport.values) {
        where = 'Laporan ${r.label}';
        Get.find<LaporanController>().select(r);
        await settle();
      }
      FlutterError.onError = old;
      // Bongkar bersih supaya tidak ada timer drift/GetX tersisa saat tes selesai.
      await tester.pumpWidget(const SizedBox.shrink());
      Get.reset();
      await tester.pump(const Duration(seconds: 1)); // biarkan timer penutupan stream drift berjalan
      await tester.runAsync(() async {
        await db.close();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(seconds: 1));
      tester.view.reset();
      expect(errors.toSet().toList(), isEmpty);
    });
  }
}
