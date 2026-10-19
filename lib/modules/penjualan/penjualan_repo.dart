import 'package:drift/drift.dart';

import '../../db/database.dart';

abstract final class DocKind {
  static const invoice = 'invoice', order = 'order';
}

enum PayStatus { unpaid, partial, paid, invoiced, voided }

/// Ringkasan invoice/pemesanan untuk daftar: total & terbayar dihitung dari baris & buku kas.
class DocSummary {
  DocSummary(
    this.doc, {
    this.customerName,
    this.customerPhone,
    required this.total,
    required this.paid,
    this.hasInvoice = false,
  });
  final Invoice doc;
  final String? customerName, customerPhone;
  final int total, paid;
  final bool hasInvoice; // pemesanan yang sudah dibuatkan invoice

  int get remaining => total - paid;
  bool get isOrder => doc.kind == DocKind.order;

  PayStatus get status {
    if (doc.isVoid) return PayStatus.voided;
    if (isOrder && hasInvoice) return PayStatus.invoiced;
    if (paid >= total) return PayStatus.paid;
    return paid > 0 ? PayStatus.partial : PayStatus.unpaid;
  }

  bool overdue(DateTime today) =>
      (status == PayStatus.unpaid || status == PayStatus.partial) &&
      doc.dueAt != null &&
      doc.dueAt!.isBefore(DateTime(today.year, today.month, today.day));
}

/// Satu baris saat membuat/mengubah invoice.
class LineInput {
  LineInput({
    required this.productId,
    required this.name,
    this.description = '',
    required this.qty,
    required this.price,
    this.discount = 0,
    this.incentive = 0,
    this.cost,
    this.tech1Id,
    this.tech2Id,
  });
  final int productId;
  final String name, description;
  final int qty, price, discount, incentive;
  final int? cost, tech1Id, tech2Id;

  int get total => qty * price - discount;

  factory LineInput.from(InvoiceLine l) => LineInput(
    productId: l.productId,
    name: l.name,
    description: l.description,
    qty: l.qty,
    price: l.price,
    discount: l.discount,
    incentive: l.incentive,
    cost: l.cost,
    tech1Id: l.tech1Id,
    tech2Id: l.tech2Id,
  );
}

class PaymentInput {
  PaymentInput({required this.accountId, required this.amount, required this.at, this.note = '', this.proofPath = ''});
  final int accountId, amount;
  final DateTime at;
  final String note, proofPath;
}

int linesTotal(Iterable<LineInput> lines) => lines.fold(0, (s, l) => s + l.total);

/// Insentif satu baris untuk satu teknisi: qty × tarif, dibagi dua bila dikerjakan berdua.
int lineIncentiveShare(InvoiceLine l) {
  final techs = [l.tech1Id, l.tech2Id].whereType<int>().length;
  return techs == 0 ? 0 : (l.qty * l.incentive) ~/ techs;
}

const _summarySql = '''
SELECT i.*, c.name AS customer_name, c.phone AS customer_phone,
  COALESCE((SELECT SUM(qty * price - discount) FROM invoice_lines WHERE invoice_id = i.id), 0) AS total,
  COALESCE((SELECT SUM(amount) FROM cash_entries WHERE kind IN ('payment', 'refund')
    AND (ref_id = i.id OR (i.is_void = 0 AND i.order_id IS NOT NULL AND ref_id = i.order_id))), 0) AS paid,
  EXISTS (SELECT 1 FROM invoices x WHERE x.order_id = i.id AND x.is_void = 0) AS has_invoice
FROM invoices i LEFT JOIN customers c ON c.id = i.customer_id''';

extension PenjualanRepo on AppDb {
  Set<ResultSetImplementation> get _docTables => {invoices, invoiceLines, cashEntries, customers};

  DocSummary _summary(QueryRow r) => DocSummary(
    invoices.map(r.data),
    customerName: r.readNullable<String>('customer_name'),
    customerPhone: r.readNullable<String>('customer_phone'),
    total: r.read<int>('total'),
    paid: r.read<int>('paid'),
    hasInvoice: r.read<bool>('has_invoice'),
  );

  Stream<List<DocSummary>> watchDocs(String kind) => customSelect(
    '$_summarySql WHERE i.kind = ? ORDER BY i.at DESC, i.id DESC',
    variables: [Variable.withString(kind)],
    readsFrom: _docTables,
  ).watch().map((rows) => rows.map(_summary).toList());

  Stream<List<DocSummary>> watchCustomerInvoices(int customerId) => customSelect(
    '$_summarySql WHERE i.kind = ? AND i.customer_id = ? ORDER BY i.at DESC, i.id DESC',
    variables: [Variable.withString(DocKind.invoice), Variable.withInt(customerId)],
    readsFrom: _docTables,
  ).watch().map((rows) => rows.map(_summary).toList());

  Future<DocSummary> docSummary(int id) async => _summary(
    await customSelect(
      '$_summarySql WHERE i.id = ?',
      variables: [Variable.withInt(id)],
      readsFrom: _docTables,
    ).getSingle(),
  );

  Stream<List<Employee>> watchTechnicians() =>
      (select(employees)..where((e) => e.role.equals('teknisi') & e.active.equals(true))).watch();

  Stream<List<Account>> watchActiveAccounts() => (select(accounts)..where((a) => a.active.equals(true))).watch();

  Stream<List<InvoiceLine>> watchLines(int docId) =>
      (select(invoiceLines)
            ..where((l) => l.invoiceId.equals(docId))
            ..orderBy([(l) => OrderingTerm(expression: l.id)]))
          .watch();

  /// Pembayaran dokumen ini, termasuk DP pemesanan asalnya (untuk invoice dari pemesanan).
  Stream<List<CashEntry>> watchPayments(Invoice doc) =>
      (select(cashEntries)
            ..where(
              (c) =>
                  c.kind.isIn(['payment', 'refund']) &
                  c.refId.isIn([doc.id, if (doc.orderId != null && !doc.isVoid) doc.orderId!]),
            )
            ..orderBy([(c) => OrderingTerm(expression: c.at), (c) => OrderingTerm(expression: c.id)]))
          .watch();

  // ---------------------------------------------------------------- simpan

  /// Buat ([id] null) atau ubah invoice/pemesanan. Semua aturan dicek di sini, bukan di UI.
  /// [legacyNo]: input transaksi lama — nomor diketik manual dan stok tidak berubah.
  /// [payNow]: pembayaran yang langsung diterima (mode kasir / DP).
  Future<int> saveDoc({
    int? id,
    required String kind,
    required DateTime at,
    DateTime? dueAt,
    int? customerId,
    String car = '',
    String plate = '',
    String note = '',
    required List<LineInput> lines,
    String? legacyNo,
    PaymentInput? payNow,
  }) {
    if (kind != DocKind.invoice && kind != DocKind.order) throw ArgumentError('Jenis dokumen tidak dikenal');
    if (lines.isEmpty) throw ArgumentError('Belum ada barang/jasa');
    for (final l in lines) {
      if (l.qty <= 0) throw ArgumentError('Qty "${l.name}" harus lebih dari 0');
      if (l.price < 0 || l.discount < 0 || l.cost != null && l.cost! < 0) {
        throw ArgumentError('Harga/diskon/modal "${l.name}" tidak boleh minus');
      }
      if (l.discount > l.qty * l.price) throw ArgumentError('Diskon "${l.name}" melebihi harganya');
      if (l.tech1Id != null && l.tech1Id == l.tech2Id) throw ArgumentError('Teknisi "${l.name}" dipilih dua kali');
    }
    final legacy = legacyNo != null;
    if (legacy && legacyNo.trim().isEmpty) throw ArgumentError('Nomor transaksi lama wajib diisi');

    return transaction(() async {
      final productIds = lines.map((l) => l.productId).toSet();
      final items = {for (final p in await (select(products)..where((p) => p.id.isIn(productIds))).get()) p.id: p};
      if (items.length != productIds.length) throw ArgumentError('Ada produk yang tidak ditemukan');

      final Invoice? old = id == null ? null : await (select(invoices)..where((i) => i.id.equals(id))).getSingle();
      // Modal hanya boleh ditulis owner. Selain owner: modal lama per produk dipertahankan, baris baru kosong.
      final oldCost = <int, int?>{};
      if (old != null) {
        if (old.isVoid) throw ArgumentError('${old.no} sudah dibatalkan');
        final s = await docSummary(old.id);
        if (s.hasInvoice) throw ArgumentError('${old.no} sudah dibuatkan invoice, tidak bisa diubah');
        if (s.paid > 0) requireOwner(); // PRD PJ-9: ubah dokumen yang sudah dibayar
        for (final l in await (select(invoiceLines)..where((l) => l.invoiceId.equals(old.id))).get()) {
          oldCost.putIfAbsent(l.productId, () => l.cost);
        }
        if (linesTotal(lines) < s.paid) {
          throw ArgumentError('Total baru (${linesTotal(lines)}) lebih kecil dari yang sudah dibayar (${s.paid})');
        }
      }

      final data = InvoicesCompanion(
        kind: Value(kind),
        at: Value(at),
        dueAt: Value(dueAt),
        customerId: Value(customerId),
        car: Value(car.trim()),
        plate: Value(plate.trim().toUpperCase()),
        note: Value(note.trim()),
      );
      final int docId;
      if (old == null) {
        Future<bool> taken(String no) async =>
            await (select(invoices)..where((i) => i.no.equals(no))).getSingleOrNull() != null;
        final String no;
        if (legacy) {
          no = legacyNo.trim().toUpperCase();
          if (await taken(no)) throw ArgumentError('Nomor $no sudah dipakai');
        } else {
          // Lewati nomor yang sudah dipakai (mis. oleh transaksi lama) supaya penomoran tidak macet.
          var n = '';
          do {
            n = await takeNumber(
              kind == DocKind.invoice ? 'next_invoice_no' : 'next_so_no',
              kind == DocKind.invoice ? 'INV' : 'SO',
            );
          } while (await taken(n));
          no = n;
        }
        docId = await into(invoices).insert(data.copyWith(no: Value(no), legacy: Value(legacy)));
      } else {
        docId = old.id;
        await (update(invoices)..where((i) => i.id.equals(docId))).write(data);
        await (delete(invoiceLines)..where((l) => l.invoiceId.equals(docId))).go();
        await (delete(stockMoves)..where((m) => m.kind.equals('sale') & m.refId.equals(docId))).go();
      }

      for (final l in lines) {
        await into(invoiceLines).insert(
          InvoiceLinesCompanion.insert(
            invoiceId: docId,
            productId: l.productId,
            name: l.name.trim().isEmpty ? items[l.productId]!.name : l.name.trim(),
            description: Value(l.description.trim()),
            qty: l.qty,
            price: l.price,
            discount: Value(l.discount),
            cost: Value(ownerUnlocked ? l.cost : oldCost[l.productId]),
            incentive: Value(l.incentive),
            tech1Id: Value(l.tech1Id),
            tech2Id: Value(l.tech2Id),
          ),
        );
      }
      // Stok hanya berkurang di invoice (bukan pemesanan) dan bukan transaksi lama.
      final isLegacy = old?.legacy ?? legacy;
      if (kind == DocKind.invoice && !isLegacy) await _moveStockOut(docId, at, lines, items);
      if (payNow != null) await addPayment(docId, payNow);
      return docId;
    });
  }

  // Stok boleh minus (keputusan awal: toko sering menjual sebelum pembelian dicatat);
  // form invoice memberi peringatan, Gudang menandai stok minus.
  Future<void> _moveStockOut(int docId, DateTime at, List<LineInput> lines, Map<int, Product> items) async {
    for (final l in lines.where((l) => !items[l.productId]!.isService)) {
      await into(stockMoves).insert(
        StockMovesCompanion.insert(at: at, productId: l.productId, qty: -l.qty, kind: 'sale', refId: Value(docId)),
      );
    }
  }

  /// Pembayaran / DP. Tidak boleh melebihi sisa tagihan.
  Future<void> addPayment(int docId, PaymentInput p) => transaction(() async {
    final s = await docSummary(docId);
    if (s.doc.isVoid) throw ArgumentError('${s.doc.no} sudah dibatalkan');
    if (s.hasInvoice) throw ArgumentError('${s.doc.no} sudah dibuatkan invoice — bayar di invoicenya');
    if (p.amount <= 0) throw ArgumentError('Nominal pembayaran harus lebih dari 0');
    if (p.amount > s.remaining) throw ArgumentError('Nominal melebihi sisa tagihan (${s.remaining})');
    await requireActiveAccount(p.accountId);
    await into(cashEntries).insert(
      CashEntriesCompanion.insert(
        at: p.at,
        accountId: p.accountId,
        amount: p.amount,
        kind: 'payment',
        refId: Value(docId),
        description:
            '${s.isOrder ? 'DP' : 'Pembayaran'} ${s.doc.no}${s.customerName == null ? '' : ' — ${s.customerName}'}',
        note: Value(p.note.trim()),
        proofPath: Value(p.proofPath),
      ),
    );
  });

  /// Batalkan (owner): stok dikembalikan, uang yang diterima DOKUMEN INI dicatat keluar lagi (refund)
  /// ke rekening asalnya. Invoice dari pemesanan: DP tetap milik pemesanan, yang kembali terbuka.
  Future<void> voidDoc(int docId, String reason) => transaction(() async {
    requireOwner();
    if (reason.trim().isEmpty) throw ArgumentError('Alasan pembatalan wajib diisi');
    final s = await docSummary(docId);
    if (s.doc.isVoid) return;
    if (s.hasInvoice) throw ArgumentError('${s.doc.no} sudah dibuatkan invoice — batalkan invoicenya');
    await (update(invoices)..where((i) => i.id.equals(docId))).write(
      InvoicesCompanion(isVoid: const Value(true), voidReason: Value(reason.trim())),
    );
    final now = DateTime.now();
    for (final m in await (select(stockMoves)..where((m) => m.kind.equals('sale') & m.refId.equals(docId))).get()) {
      await into(stockMoves).insert(
        StockMovesCompanion.insert(at: now, productId: m.productId, qty: -m.qty, kind: 'void', refId: Value(docId)),
      );
    }
    for (final p in await (select(cashEntries)..where((c) => c.kind.equals('payment') & c.refId.equals(docId))).get()) {
      await into(cashEntries).insert(
        CashEntriesCompanion.insert(
          at: now,
          accountId: p.accountId,
          amount: -p.amount,
          kind: 'refund',
          refId: Value(docId),
          description: 'Pengembalian ${s.doc.no} (dibatalkan)',
          note: Value(reason.trim()),
        ),
      );
    }
  });

  /// Pemesanan -> invoice baru (nomor INV berikutnya). Baris disalin, stok berkurang.
  /// DP tetap tercatat di pemesanan dan ikut dihitung sebagai "Pembayaran Diterima" invoice.
  Future<int> invoiceFromOrder(int orderId, {DateTime? at}) => transaction(() async {
    final s = await docSummary(orderId);
    if (!s.isOrder) throw ArgumentError('${s.doc.no} bukan pemesanan');
    if (s.doc.isVoid) throw ArgumentError('${s.doc.no} sudah dibatalkan');
    if (s.hasInvoice) throw ArgumentError('${s.doc.no} sudah dibuatkan invoice');
    final lines = await (select(invoiceLines)..where((l) => l.invoiceId.equals(orderId))).get();
    final date = at ?? DateTime.now();
    final invId = await saveDoc(
      kind: DocKind.invoice,
      at: date,
      dueAt: date.add(const Duration(days: 30)),
      customerId: s.doc.customerId,
      car: s.doc.car,
      plate: s.doc.plate,
      note: s.doc.note,
      lines: lines.map(LineInput.from).toList(),
    );
    await (update(invoices)..where((i) => i.id.equals(invId))).write(InvoicesCompanion(orderId: Value(orderId)));
    return invId;
  });

  /// Modal per unit satu baris (khusus owner; null = kosongkan).
  Future<void> setLineCost(int lineId, int? cost) async {
    requireOwner();
    if (cost != null && cost < 0) throw ArgumentError('Modal tidak boleh minus');
    await (update(invoiceLines)..where((l) => l.id.equals(lineId))).write(InvoiceLinesCompanion(cost: Value(cost)));
  }

  /// Statistik customer pada [from, to): pelanggan aktif, % repeat order, top pelanggan.
  /// Aktif = punya ≥1 invoice (bukan batal) di periode. Repeat = aktif yang punya ≥2 invoice sepanjang waktu.
  Future<({int active, double repeatPct, List<({Customer customer, int total, int count})> top})> customerStats(
    DateTime from,
    DateTime to,
  ) async {
    final rows = await customSelect(
      '''
      SELECT c.*, SUM(t.total) AS total, COUNT(*) AS cnt,
        (SELECT COUNT(*) FROM invoices a WHERE a.customer_id = c.id AND a.kind = 'invoice' AND a.is_void = 0) AS all_cnt
      FROM invoices i
      JOIN customers c ON c.id = i.customer_id
      JOIN (SELECT invoice_id, SUM(qty * price - discount) AS total FROM invoice_lines GROUP BY invoice_id) t
        ON t.invoice_id = i.id
      WHERE i.kind = 'invoice' AND i.is_void = 0 AND i.at >= ? AND i.at < ?
      GROUP BY c.id ORDER BY total DESC''',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {invoices, invoiceLines, customers},
    ).get();
    final repeat = rows.where((r) => r.read<int>('all_cnt') >= 2).length;
    return (
      active: rows.length,
      repeatPct: rows.isEmpty ? 0.0 : repeat * 100 / rows.length,
      top: [
        for (final r in rows.take(10))
          (customer: customers.map(r.data), total: r.read<int>('total'), count: r.read<int>('cnt')),
      ],
    );
  }
}
