import 'package:drift/drift.dart';

import '../../core/format.dart';
import '../../db/database.dart';
import '../gudang/gudang_repo.dart';
import '../kas/kas_repo.dart';
import '../penjualan/penjualan_repo.dart';
import 'akuntansi_repo.dart';
import 'laporan_repo.dart';
import 'report_data.dart';

/// Laporan keuangan & akuntansi turunan jurnal + detail penjualan/pembelian. Semua khusus owner.
extension LaporanBaru on AppDb {
  // ------------------------------------------------------------------ keuangan

  /// Neraca per tanggal [asOf]: aset = kewajiban + modal (laba berjalan = pendapatan − beban sampai tanggal itu).
  Future<ReportData> neraca(DateTime asOf) async {
    final j = await journal();
    final net = j.net(to: dayAfter(asOf));
    int bal(String c) => net[c] ?? 0;
    final kas = j.accounts.keys.where(Ac.isKas).toList()..sort();
    final rows = <RRow>[];
    var assets = 0, liabilities = 0;
    void asset(String name, int v) {
      rows.add(RRow([name, v]));
      assets += v;
    }

    rows.add(const RRow(['ASET', null], bold: true));
    for (final c in kas) {
      asset(j.accounts[c]!.name, bal(c));
    }
    asset(j.accounts[Ac.piutang]!.name, bal(Ac.piutang));
    asset(j.accounts[Ac.persediaan]!.name, bal(Ac.persediaan));
    if (bal(Ac.transfer) != 0) asset(j.accounts[Ac.transfer]!.name, bal(Ac.transfer));
    rows.add(RRow(['Total aset', assets], bold: true));

    rows.add(const RRow(['KEWAJIBAN', null], bold: true));
    for (final c in [Ac.utangUsaha, Ac.uangMuka, Ac.utangPpn]) {
      rows.add(RRow([j.accounts[c]!.name, -bal(c)]));
      liabilities -= bal(c);
    }
    rows.add(RRow(['Total kewajiban', liabilities], bold: true));

    rows.add(const RRow(['MODAL', null], bold: true));
    rows.add(RRow([j.accounts[Ac.modal]!.name, -bal(Ac.modal)]));
    rows.add(RRow([j.accounts[Ac.prive]!.name, -bal(Ac.prive)]));
    final profit = j.profit(net);
    rows.add(RRow(['Laba (rugi) berjalan', profit]));
    final equity = -bal(Ac.modal) - bal(Ac.prive) + profit;
    rows.add(RRow(['Total modal', equity], bold: true));
    rows.add(RRow(['Total kewajiban + modal', liabilities + equity], bold: true));
    return ReportData(
      'Neraca per ${tgl(asOf)}',
      const ['Akun', 'Jumlah'],
      rows,
      notes: [
        if (assets != liabilities + equity)
          'PERHATIAN: neraca tidak seimbang (selisih ${rupiah(assets - liabilities - equity)}).',
        'Laba berjalan sudah termasuk pemasukan lain (kas) dan selisih opname; menu Laba rugi hanya menghitung penjualan.',
        'Persediaan dinilai dari catatan pembelian & modal per baris invoice; stok awal dinilai harga beli saat ini.',
      ],
    );
  }

  /// Perubahan modal: modal awal + laba bersih + setoran modal − prive = modal akhir.
  Future<ReportData> perubahanModal(DateTime from, DateTime end) async {
    final j = await journal();
    final to = dayAfter(end);
    int equityAt(DateTime until) {
      final n = j.net(to: until);
      return -(n[Ac.modal] ?? 0) - (n[Ac.prive] ?? 0) + j.profit(n);
    }

    final inPeriod = j.net(from: from, to: to);
    final awal = equityAt(from), akhir = equityAt(to);
    final laba = j.profit(inPeriod);
    final setoran = -(inPeriod[Ac.modal] ?? 0);
    final prive = inPeriod[Ac.prive] ?? 0;
    return ReportData(
      'Perubahan modal ${tgl(from)} – ${tgl(end)}',
      const ['Keterangan', 'Jumlah'],
      [
        RRow(['Modal awal', awal], bold: true),
        RRow(['Laba (rugi) bersih periode', laba]),
        RRow(['Tambahan modal / saldo awal rekening', setoran]),
        RRow(['Prive (pengeluaran pribadi)', -prive]),
        RRow(['Modal akhir', akhir], bold: true),
      ],
      notes: [if (awal + laba + setoran - prive != akhir) 'PERHATIAN: rincian tidak sama dengan modal akhir.'],
    );
  }

  /// Proyeksi saldo kas 3 bulan ke depan dari rata-rata 3 bulan terakhir (metode sederhana; bukan angka pasti).
  Future<ReportData> proyeksiArusKas() async {
    final j = await journal();
    final now = DateTime.now();
    final startNow = DateTime(now.year, now.month);
    final from = DateTime(now.year, now.month - 3);
    final rows = await (select(
      cashEntries,
    )..where((c) => c.at.isBiggerOrEqualValue(from) & c.at.isSmallerThanValue(startNow))).get();
    var masuk = 0, keluar = 0;
    for (final c in rows) {
      switch (c.kind) {
        case 'payment' || 'refund' || 'income':
          masuk += c.amount;
        case 'expense' || 'salary' || 'purchase':
          keluar -= c.amount;
      }
    }
    final avgIn = (masuk / 3).round(), avgOut = (keluar / 3).round();
    final kas = j.net().entries.where((e) => Ac.isKas(e.key)).fold<int>(0, (t, e) => t + e.value);
    var saldo = kas;
    final out = <RRow>[];
    for (var m = 0; m < 3; m++) {
      final month = DateTime(now.year, now.month + m);
      final awal = saldo;
      saldo = awal + avgIn - avgOut;
      out.add(RRow([periodOf(month, Period.monthly).$2, awal, avgIn, avgOut, saldo]));
    }
    final open = (await docsQuery(DocKind.invoice).get()).where((d) => !d.doc.isVoid && d.remaining > 0);
    final piutang = open.fold<int>(0, (t, d) => t + d.remaining);
    final unpaid = (await purchasesQuery().get()).where((p) => !p.paid).fold<int>(0, (t, p) => t + p.purchase.total);
    return ReportData(
      'Proyeksi arus kas 3 bulan',
      const ['Bulan', 'Saldo awal', 'Perkiraan masuk', 'Perkiraan keluar', 'Saldo akhir'],
      out,
      notes: [
        'Metode: rata-rata pemasukan dan pengeluaran kas (penjualan, biaya, gaji, pembelian stok) 3 bulan penuh '
            'terakhir, ditambahkan ke saldo kas & bank sekarang (${rupiah(kas)}). Transfer antar rekening dan '
            'setoran modal tidak dihitung.',
        'Tagihan terbuka tidak dihitung terpisah (sudah tercermin di rata-rata): piutang ${rupiah(piutang)}, '
            'utang pembelian ${rupiah(unpaid)}.',
        'Ini perkiraan, bukan angka pasti. Metode bisa disesuaikan bila client punya cara hitung lain.',
      ],
    );
  }

  /// Ringkasan eksekutif: indikator utama periode vs periode sebelumnya (sama panjang) + posisi akhir periode.
  Future<ReportData> ringkasanEksekutif(DateTime from, DateTime end) async {
    final to = dayAfter(end);
    final prevFrom = from.subtract(to.difference(from));
    final (now, prev) = await (report(from, to, Period.monthly), report(prevFrom, from, Period.monthly)).wait;
    final j = await journal();
    final pos = j.net(to: to);
    String change(int a, int b) =>
        b == 0 ? (a == 0 ? '—' : 'baru') : '${a >= b ? '▲' : '▼'} ${((a - b) * 100 / b).abs().round()}%';
    final a = now.pl.total, b = prev.pl.total;
    RRow ind(String label, int x, int y) => RRow([label, x, y, change(x, y)]);
    final invNow = now.sales.total.invoices.length, invPrev = prev.sales.total.invoices.length;
    final top = now.sales.byProduct.take(3).toList();
    return ReportData(
      'Ringkasan eksekutif ${tgl(from)} – ${tgl(end)}',
      const ['Indikator', 'Periode ini', 'Periode sebelumnya', 'Perubahan'],
      [
        const RRow(['KINERJA', null, null, null], bold: true),
        ind('Omzet (pendapatan)', a.revenue, b.revenue),
        ind('HPP', a.cogs, b.cogs),
        ind('Laba kotor', a.gross, b.gross),
        ind('Biaya operasional + gaji', a.opex, b.opex),
        ind('Laba bersih usaha', a.net, b.net),
        ind('Pengeluaran pribadi', a.personal, b.personal),
        ind('Sisa setelah pengeluaran pribadi', a.rest, b.rest),
        RRow(['Jumlah invoice', invNow, invPrev, change(invNow, invPrev)]),
        const RRow(['POSISI (akhir periode)', null, null, null], bold: true),
        RRow([
          'Saldo kas & bank',
          pos.entries.where((e) => Ac.isKas(e.key)).fold<int>(0, (t, e) => t + e.value),
          null,
          null,
        ]),
        RRow(['Piutang usaha', pos[Ac.piutang] ?? 0, null, null]),
        RRow(['Persediaan', pos[Ac.persediaan] ?? 0, null, null]),
        RRow(['Utang usaha', -(pos[Ac.utangUsaha] ?? 0), null, null]),
        if (top.isNotEmpty) const RRow(['TERLARIS', null, null, null], bold: true),
        for (final (i, t) in top.indexed) RRow(['${i + 1}. ${t.name}', t.omzet, null, '${t.qty}×']),
      ],
      notes: ['Periode sebelumnya = ${tgl(prevFrom)} – ${tgl(from.subtract(const Duration(days: 1)))}.'],
    );
  }

  // ------------------------------------------------------------------ akuntansi

  /// Ringkasan bank: saldo awal, masuk, keluar, saldo akhir tiap rekening pada periode.
  Future<ReportData> ringkasanBank(DateTime from, DateTime end) async {
    final j = await journal();
    final to = dayAfter(end);
    final before = j.net(to: from), upTo = j.net(to: to);
    final within = <String, (int, int)>{};
    for (final e in j.entries.where((e) => !e.at.isBefore(from) && e.at.isBefore(to))) {
      for (final l in e.lines.where((l) => Ac.isKas(l.code))) {
        final (d, c) = within[l.code] ?? (0, 0);
        within[l.code] = (d + l.debit, c + l.credit);
      }
    }
    final kas = j.accounts.keys.where(Ac.isKas).toList()..sort();
    var tAwal = 0, tIn = 0, tOut = 0, tAkhir = 0;
    final rows = <RRow>[];
    for (final c in kas) {
      final awal = before[c] ?? 0, akhir = upTo[c] ?? 0;
      final (d, k) = within[c] ?? (0, 0);
      rows.add(RRow([j.accounts[c]!.name.replaceFirst('Kas & Bank — ', ''), awal, d, k, akhir]));
      tAwal += awal;
      tIn += d;
      tOut += k;
      tAkhir += akhir;
    }
    rows.add(RRow(['Total', tAwal, tIn, tOut, tAkhir], bold: true));
    return ReportData(
      'Ringkasan bank ${tgl(from)} – ${tgl(end)}',
      const ['Rekening', 'Saldo awal', 'Masuk', 'Keluar', 'Saldo akhir'],
      rows,
      notes: const ['Transfer antar rekening ikut tercatat sebagai masuk/keluar di masing-masing rekening.'],
    );
  }

  /// Buku besar satu akun [code] pada periode, dengan saldo berjalan (arah saldo mengikuti jenis akun).
  Future<ReportData> bukuBesar(String code, DateTime from, DateTime end) async {
    final j = await journal();
    final acct = j.accounts[code] ?? j.accounts.values.first;
    final sign = (acct.kind == AcctKind.asset || acct.kind == AcctKind.expense) ? 1 : -1;
    final to = dayAfter(end);
    var run = (j.net(to: from)[acct.code] ?? 0) * sign;
    final rows = <RRow>[
      RRow(['', '', 'Saldo awal', null, null, run], bold: true),
    ];
    for (final e in j.entries.where((e) => !e.at.isBefore(from) && e.at.isBefore(to))) {
      for (final l in e.lines.where((l) => l.code == acct.code)) {
        run += (l.debit - l.credit) * sign;
        rows.add(RRow([tgl(e.at), e.ref, e.memo, l.debit == 0 ? null : l.debit, l.credit == 0 ? null : l.credit, run]));
      }
    }
    rows.add(RRow(['', '', 'Saldo akhir', null, null, run], bold: true));
    return ReportData('Buku besar — ${acct.code} ${acct.name}', const [
      'Tanggal',
      'Ref',
      'Keterangan',
      'Debit',
      'Kredit',
      'Saldo',
    ], rows);
  }

  /// Buku besar pembantu: [jenis] piutang (per customer) | utang (per vendor) | persediaan (per produk).
  Future<ReportData> bukuBesarPembantu(String jenis) async {
    requireOwner(); // cabang persediaan/piutang tidak lewat journal() — cek di sini
    final today = DateTime.now();
    switch (jenis) {
      case 'utang':
        final unpaid = (await purchasesQuery().get()).where((p) => !p.paid).toList()
          ..sort((a, b) => a.purchase.supplier.toLowerCase().compareTo(b.purchase.supplier.toLowerCase()));
        final total = unpaid.fold<int>(0, (t, p) => t + p.purchase.total);
        return ReportData(
          'Buku besar pembantu — utang usaha per vendor',
          const ['Vendor', 'No.', 'Tgl beli', 'Nota supplier', 'Umur (hari)', 'Sisa utang'],
          [
            for (final p in unpaid)
              RRow([
                p.purchase.supplier.isEmpty ? '(tanpa vendor)' : p.purchase.supplier,
                p.purchase.no,
                tgl(p.purchase.at),
                p.purchase.billNo,
                today.difference(p.purchase.at).inDays,
                p.purchase.total,
              ]),
            RRow(['Total', '', '', '', null, total], bold: true),
          ],
          countCols: const {4},
        );
      case 'persediaan':
        final items = (await productsQuery().get()).where((s) => !s.isService && s.stock != 0).toList();
        final total = items.fold<int>(0, (t, s) => t + s.stock * s.product.buyPrice);
        return ReportData(
          'Buku besar pembantu — persediaan per produk',
          const ['Produk', 'Kode', 'Stok', 'Harga beli', 'Nilai'],
          [
            for (final s in items)
              RRow([s.product.name, s.product.sku ?? '', s.stock, s.product.buyPrice, s.stock * s.product.buyPrice]),
            RRow(['Total', '', null, null, total], bold: true),
          ],
          countCols: const {2},
          notes: const [
            'Nilai = stok × harga beli terakhir; bisa berbeda dari saldo Persediaan di neraca (dinilai dari pembelian).',
          ],
        );
      default:
        final open = (await docsQuery(DocKind.invoice).get()).where((d) => !d.doc.isVoid && d.remaining > 0).toList()
          ..sort(
            (a, b) => (a.customerName ?? 'UMUM').toLowerCase().compareTo((b.customerName ?? 'UMUM').toLowerCase()),
          );
        final total = open.fold<int>(0, (t, d) => t + d.remaining);
        return ReportData(
          'Buku besar pembantu — piutang usaha per customer',
          const ['Customer', 'No. invoice', 'Tanggal', 'Jatuh tempo', 'Total', 'Dibayar', 'Sisa', 'Umur (hari)'],
          [
            for (final d in open)
              RRow([
                d.customerName ?? 'UMUM',
                d.doc.no,
                tgl(d.doc.at),
                d.doc.dueAt == null ? '' : tgl(d.doc.dueAt!),
                d.total,
                d.paid,
                d.remaining,
                today.difference(d.doc.at).inDays,
              ]),
            RRow(['Total', '', '', '', null, null, total, null], bold: true),
          ],
          countCols: const {7},
        );
    }
  }

  /// Jurnal umum periode: tiap transaksi dengan baris debit/kredit.
  Future<ReportData> jurnalUmum(DateTime from, DateTime end) async {
    final j = await journal();
    final to = dayAfter(end);
    final rows = <RRow>[];
    for (final e in j.entries.where((e) => !e.at.isBefore(from) && e.at.isBefore(to))) {
      for (final (i, l) in e.lines.indexed) {
        rows.add(
          RRow([
            i == 0 ? tgl(e.at) : '',
            i == 0 ? e.ref : '',
            i == 0 ? e.memo : '',
            '${l.code} ${j.accounts[l.code]?.name ?? l.code}',
            l.debit == 0 ? null : l.debit,
            l.credit == 0 ? null : l.credit,
          ]),
        );
      }
    }
    return ReportData(
      'Jurnal umum ${tgl(from)} – ${tgl(end)}',
      const ['Tanggal', 'Ref', 'Keterangan', 'Akun', 'Debit', 'Kredit'],
      rows,
      notes: const [
        'Jurnal dibuat otomatis dari transaksi (invoice, pembayaran, pembelian, biaya, gaji, transfer, opname).',
      ],
    );
  }

  /// Neraca saldo per tanggal [asOf] (kumulatif sejak awal).
  Future<ReportData> trialBalance(DateTime asOf) async {
    final j = await journal();
    final net = j.net(to: dayAfter(asOf));
    final codes = net.keys.where((c) => net[c] != 0).toList()..sort();
    var d = 0, k = 0;
    final rows = <RRow>[];
    for (final c in codes) {
      final v = net[c]!;
      rows.add(RRow([c, j.accounts[c]?.name ?? c, v > 0 ? v : null, v < 0 ? -v : null]));
      if (v > 0) {
        d += v;
      } else {
        k += -v;
      }
    }
    rows.add(RRow(['', 'Total', d, k], bold: true));
    return ReportData(
      'Trial balance per ${tgl(asOf)}',
      const ['Kode', 'Akun', 'Debit', 'Kredit'],
      rows,
      notes: [if (d != k) 'PERHATIAN: debit dan kredit tidak sama (selisih ${rupiah(d - k)}).'],
    );
  }

  // ------------------------------------------------------------------ penjualan & pembelian

  Future<ReportData> detailPenjualan(DateTime from, DateTime end) async {
    requireOwner(); // modul Laporan khusus owner (dicek di repo, bukan hanya OwnerGate)
    final q =
        select(invoiceLines).join([
            innerJoin(invoices, invoices.id.equalsExp(invoiceLines.invoiceId)),
            leftOuterJoin(customers, customers.id.equalsExp(invoices.customerId)),
          ])
          ..where(
            invoices.kind.equals(DocKind.invoice) &
                invoices.isVoid.equals(false) &
                invoices.at.isBiggerOrEqualValue(from) &
                invoices.at.isSmallerThanValue(dayAfter(end)),
          )
          ..orderBy([OrderingTerm.asc(invoices.at), OrderingTerm.asc(invoices.id), OrderingTerm.asc(invoiceLines.id)]);
    var total = 0, qty = 0;
    final rows = <RRow>[];
    for (final r in await q.get()) {
      final inv = r.readTable(invoices), l = r.readTable(invoiceLines), c = r.readTableOrNull(customers);
      final amount = l.qty * l.price - l.discount;
      total += amount;
      qty += l.qty;
      rows.add(RRow([tgl(inv.at), inv.no, c?.name ?? 'UMUM', inv.plate, l.name, l.qty, l.price, l.discount, amount]));
    }
    rows.add(RRow(['Total', '', '', '', '', qty, null, null, total], bold: true));
    return ReportData(
      'Detail penjualan ${tgl(from)} – ${tgl(end)}',
      const ['Tanggal', 'No. invoice', 'Customer', 'Plat', 'Barang / jasa', 'Qty', 'Harga', 'Diskon baris', 'Jumlah'],
      rows,
      countCols: const {5},
      notes: const ['Jumlah per baris sebelum diskon invoice dan PPN.'],
    );
  }

  Future<ReportData> detailPembelian(DateTime from, DateTime end) async {
    requireOwner(); // berisi harga beli
    final q =
        select(stockMoves).join([
            innerJoin(purchases, purchases.id.equalsExp(stockMoves.refId) & stockMoves.kind.equals('purchase')),
            innerJoin(products, products.id.equalsExp(stockMoves.productId)),
          ])
          ..where(purchases.at.isBiggerOrEqualValue(from) & purchases.at.isSmallerThanValue(dayAfter(end)))
          ..orderBy([OrderingTerm.asc(purchases.at), OrderingTerm.asc(purchases.id), OrderingTerm.asc(stockMoves.id)]);
    final paidAt = {for (final p in await purchasesQuery().get()) p.purchase.id: p.paidAt};
    var total = 0, qty = 0;
    final rows = <RRow>[];
    for (final r in await q.get()) {
      final m = r.readTable(stockMoves), p = r.readTable(purchases), item = r.readTable(products);
      final amount = m.qty * (m.unitCost ?? 0);
      total += amount;
      qty += m.qty;
      final lunas = paidAt[p.id];
      rows.add(
        RRow([
          p.no,
          tgl(p.at),
          p.supplier,
          p.billNo,
          item.name,
          m.qty,
          m.unitCost ?? 0,
          amount,
          lunas == null ? 'Belum bayar' : 'Lunas',
          lunas == null ? '' : tgl(lunas),
        ]),
      );
    }
    rows.add(RRow(['Total', '', '', '', '', qty, null, total, '', ''], bold: true));
    return ReportData(
      'Detail pembelian ${tgl(from)} – ${tgl(end)}',
      const [
        'No.',
        'Tgl beli',
        'Vendor',
        'Nota supplier',
        'Barang',
        'Qty',
        'Harga beli',
        'Jumlah',
        'Status',
        'Tgl lunas',
      ],
      rows,
      countCols: const {5},
    );
  }
}
