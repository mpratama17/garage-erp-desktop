import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/db/database.dart';
import 'package:garage_erp_desktop/modules/biaya/biaya_repo.dart';
import 'package:garage_erp_desktop/modules/gaji/gaji_repo.dart';
import 'package:garage_erp_desktop/modules/gudang/gudang_repo.dart';
import 'package:garage_erp_desktop/modules/kas/kas_repo.dart';
import 'package:garage_erp_desktop/modules/kontak/kontak_repo.dart';
import 'package:garage_erp_desktop/modules/penjualan/penjualan_repo.dart';

/// C18: app terkunci (tanpa PIN owner) = hanya lihat, kecuali kasir: penjualan, pemesanan + DP, pembayaran,
/// customer (tambah & ubah), catat biaya baru. Semua dicek di repo, bukan hanya tombol di UI.
void main() {
  late AppDb db;
  late int jasa, bca, tunai, budi, listrik;
  final d = DateTime(2026, 10, 20);
  LineInput line() => LineInput(productId: jasa, name: 'Pasang', qty: 1, price: 100000);

  setUp(() async {
    db = AppDb(NativeDatabase.memory())..ownerUnlocked = true;
    jasa = await db.saveProduct(ProductsCompanion.insert(name: 'Pasang', isService: const Value(true)));
    final acc = {for (final a in await db.select(db.accounts).get()) a.name: a.id};
    (bca, tunai) = (acc['BCA']!, acc['Tunai']!);
    budi = await db.saveCustomer(CustomersCompanion.insert(name: 'BUDI'));
    listrik = (await db.watchCategories().first).firstWhere((k) => k.name == 'Listrik').id;
    db.ownerUnlocked = false;
  });
  tearDown(() => db.close());

  test('kasir boleh: penjualan, pemesanan + DP, pembayaran, customer, biaya baru', () async {
    final inv = await db.saveDoc(kind: DocKind.invoice, at: d, customerId: budi, lines: [line()]);
    await db.addPayment(inv, PaymentInput(accountId: bca, amount: 50000, at: d));
    final so = await db.saveDoc(
      kind: DocKind.order,
      at: d,
      lines: [line()],
      payNow: PaymentInput(accountId: tunai, amount: 20000, at: d),
    );
    await db.invoiceFromOrder(so, at: d);
    final c = await db.saveCustomer(CustomersCompanion.insert(name: 'SITI'));
    await db.saveCustomer(CustomersCompanion(id: Value(c), name: const Value('SITI A'), car: const Value('Brio')));
    await db.saveExpense(at: d, accountId: tunai, categoryId: listrik, description: 'Token', amount: 50000);
  });

  test('kasir ditolak: mengubah/menghapus apa pun dan menambah selain penjualan & customer', () async {
    final inv = await db.saveDoc(kind: DocKind.invoice, at: d, lines: [line()]);
    final exp = await db.saveExpense(at: d, accountId: tunai, categoryId: listrik, description: 'Token', amount: 1);
    final refused = <String, Future<Object?> Function()>{
      'ubah invoice (belum dibayar)': () => db.saveDoc(id: inv, kind: DocKind.invoice, at: d, lines: [line()]),
      'batal invoice': () => db.voidDoc(inv, 'x'),
      'tambah produk': () => db.saveProduct(ProductsCompanion.insert(name: 'Baru')),
      'ubah produk': () => db.saveProduct(ProductsCompanion(id: Value(jasa), name: const Value('Ganti'))),
      'stok opname': () => db.adjustStock(jasa, 1, 'x'),
      'pembelian stok': () => db.recordPurchase(at: d, accountId: bca, lines: []),
      'import produk': () => db.applyImport([]),
      'hapus customer': () => db.deleteCustomer(budi),
      'import customer': () => db.applyCustomerImport([]),
      'transfer': () => db.transfer(fromId: bca, toId: tunai, amount: 1, at: d),
      'modal masuk': () =>
          db.addIncome(accountId: bca, amount: 1, at: d, kind: CashKind.capital, description: 'x'),
      'kelola rekening': () => db.saveAccount(AccountsCompanion.insert(name: 'Baru')),
      'ubah biaya': () => db.saveExpense(
        id: exp,
        at: d,
        accountId: tunai,
        categoryId: listrik,
        description: 'x',
        amount: 2,
      ),
      'hapus biaya': () => db.deleteExpense(exp),
      'kategori biaya': () => db.saveCategory(ExpenseCategoriesCompanion.insert(name: 'Baru')),
      'karyawan': () => db.saveEmployee(EmployeesCompanion.insert(name: 'X', role: 'teknisi')),
    };
    for (final e in refused.entries) {
      await expectLater(e.value, throwsArgumentError, reason: e.key); // sebagian melempar sinkron
    }
    expect((await db.docSummary(inv)).doc.isVoid, false);
  });
}
