// Render contoh nota ke PDF (lokal): OUT=/path flutter test tool/preview/pdf_preview_test.dart
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/penjualan/invoice_pdf.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('nota contoh', () async {
    final db = (AppDb(NativeDatabase.memory())..ownerUnlocked = true);
    for (final (k, v) in [
      ('shop_name', 'STAR GARAGE'),
      ('shop_address', 'Jl. Contoh No. 1, Pasuruan'),
      ('shop_phone', '0812-0000-0000'),
      ('shop_email', 'bengkel@example.com'),
      (
        'invoice_note',
        'REKENING BCA\n0000000000\nAN CONTOH NAMA\n"Barang yang sudah dibeli tidak dapat ditukar/dikembalikan kecuali ada perjanjian"\n"KLAIM GARANSI WAJIB BAWA NOTA"',
      ),
      if (File('docs/logo-star-garage.jpeg').existsSync())
        ('logo_path', File('docs/logo-star-garage.jpeg').absolute.path),
    ]) {
      await db.setSetting(k, v);
    }
    final paket = await db.saveProduct(
      ProductsCompanion.insert(name: 'PAKET TRADE ANNIVERSARY', isService: const Value(true)),
    );
    final power = await db.saveProduct(ProductsCompanion.insert(name: 'POWER+ V6'), openingStock: 3);
    final cust = await db
        .into(db.customers)
        .insert(CustomersCompanion.insert(name: 'MILA', phone: const Value('081100004444')));
    final bca = (await db.select(db.accounts).get()).first.id;
    final so = await db.saveDoc(
      kind: DocKind.order,
      at: DateTime(2026, 9, 22),
      customerId: cust,
      lines: [
        LineInput(
          productId: paket,
          name: 'PAKET TRADE ANNIVERSARY',
          description: '2set mp maxii ww',
          qty: 1,
          price: 2250000,
        ),
        LineInput(productId: power, name: 'POWER+ V6', qty: 1, price: 550000),
      ],
      payNow: PaymentInput(accountId: bca, amount: 1350000, at: DateTime(2026, 9, 22)),
    );
    final inv = await db.invoiceFromOrder(so, at: DateTime(2026, 9, 22));
    final path = await saveInvoicePdf(db, inv, dir: Platform.environment['OUT']!);
    // ignore: avoid_print
    print(path);
    await db.close();
  });
}
