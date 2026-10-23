import 'package:drift/drift.dart';

import '../../db/database.dart';
import '../gaji/gaji_repo.dart' show salaryKind;
import '../kas/kas_repo.dart' show CashKind;
import '../penjualan/penjualan_repo.dart' show DocKind;
import '../biaya/biaya_repo.dart' show expenseKind;

/// Jurnal TURUNAN: dibangun ulang dari data yang sudah ada (invoice, kas, pembelian, stok) setiap laporan dibuka.
/// Tidak ada input jurnal manual dan tidak ada tabel jurnal — satu sumber kebenaran, tidak bisa tidak sinkron.
enum AcctKind { asset, liability, equity, revenue, expense }

class Coa {
  const Coa(this.code, this.name, this.kind);
  final String code, name;
  final AcctKind kind;
}

class JLine {
  const JLine(this.code, this.debit, this.credit);
  final String code;
  final int debit, credit;
}

class JEntry {
  JEntry(this.at, this.ref, this.memo, this.lines);
  final DateTime at;
  final String ref, memo;
  final List<JLine> lines;
}

/// Kode akun tetap. Kas & bank: 11xx (id rekening); biaya: 6xxx (id kategori).
abstract final class Ac {
  static const piutang = '1200', persediaan = '1300', transfer = '1900';
  static const utangUsaha = '2100', uangMuka = '2200', utangPpn = '2300';
  static const modal = '3100', prive = '3200';
  static const penjualan = '4100', pendapatanLain = '4200';
  static const hpp = '5100', selisihStok = '5200';
  static const gaji = '6900', biayaLain = '6999';
  static String kas(int accountId) => '11${accountId.toString().padLeft(2, '0')}';
  static String biaya(int categoryId) => '6${categoryId.toString().padLeft(3, '0')}';
  static bool isKas(String code) => code.startsWith('11');
}

class Journal {
  Journal(this.entries, this.accounts);
  final List<JEntry> entries; // urut tanggal
  final Map<String, Coa> accounts;

  /// Saldo per akun (debit − kredit) untuk entri pada [from, to). Null = tanpa batas.
  Map<String, int> net({DateTime? from, DateTime? to}) {
    final m = <String, int>{};
    for (final e in entries) {
      if ((from != null && e.at.isBefore(from)) || (to != null && !e.at.isBefore(to))) continue;
      for (final l in e.lines) {
        m[l.code] = (m[l.code] ?? 0) + l.debit - l.credit;
      }
    }
    return m;
  }

  /// Laba bersih (pendapatan − beban) dari saldo [net]; akun modal/prive tidak ikut.
  int profit(Map<String, int> net) => -net.entries
      .where((e) {
        final k = accounts[e.key]?.kind;
        return k == AcctKind.revenue || k == AcctKind.expense;
      })
      .fold(0, (t, e) => t + e.value);
}

// Batas "sebelum semua transaksi" untuk saldo awal rekening.
final _epoch = DateTime(2000);

extension AkuntansiRepo on AppDb {
  /// Daftar akun (untuk memilih akun di buku besar), urut kode. Tanpa membangun seluruh jurnal.
  Future<List<Coa>> chartOfAccounts() async {
    requireOwner();
    return (await _coa()).coa.values.toList()..sort((a, b) => a.code.compareTo(b.code));
  }

  /// Seluruh jurnal. Khusus owner (berisi modal & laba).
  Future<Journal> journal() async {
    requireOwner();
    final (:coa, :accts, :cats) = await _coa();

    final out = <JEntry>[];
    // Satu pasang debit/kredit; nominal negatif membalik arah. Nol dilewati.
    void move(DateTime at, String ref, String memo, String debit, String credit, int amount) {
      if (amount == 0) return;
      final d = amount > 0 ? debit : credit, c = amount > 0 ? credit : debit, a = amount.abs();
      out.add(JEntry(at, ref, memo, [JLine(d, a, 0), JLine(c, 0, a)]));
    }

    for (final a in accts.values) {
      move(_epoch, 'Saldo awal', 'Saldo awal ${a.name}', Ac.kas(a.id), Ac.modal, a.openingBalance);
    }

    final cash = await (select(
      cashEntries,
    )..orderBy([(c) => OrderingTerm.asc(c.at), (c) => OrderingTerm.asc(c.id)])).get();
    final docs = {for (final d in await select(invoices).get()) d.id: d};
    final lineRows = await select(invoiceLines).get();
    final gross = <int, int>{}, cogs = <int, int>{};
    for (final l in lineRows) {
      gross[l.invoiceId] = (gross[l.invoiceId] ?? 0) + l.qty * l.price - l.discount;
      cogs[l.invoiceId] = (cogs[l.invoiceId] ?? 0) + l.qty * (l.cost ?? 0);
    }
    // Uang yang diterima per dokumen (DP pemesanan ikut berpindah ke invoice turunannya).
    final received = <int, int>{};
    for (final c in cash.where((c) => c.kind == 'payment' && c.refId != null)) {
      received[c.refId!] = (received[c.refId!] ?? 0) + c.amount;
    }

    for (final d in docs.values.where((d) => d.kind == DocKind.invoice && !d.isVoid)) {
      final net = (gross[d.id] ?? 0) - d.discount;
      out.add(
        JEntry(d.at, d.no, 'Penjualan ${d.no}', [
          JLine(Ac.piutang, net + d.tax, 0),
          if (net > 0) JLine(Ac.penjualan, 0, net) else if (net < 0) JLine(Ac.penjualan, -net, 0),
          if (d.tax > 0) JLine(Ac.utangPpn, 0, d.tax),
        ]),
      );
      // Transaksi lama tidak menggerakkan stok: barangnya terjual sebelum tercatat di sistem, jadi lawan HPP
      // adalah modal (seperti stok awal), bukan persediaan — kalau tidak, persediaan di neraca jadi minus.
      move(d.at, d.no, 'HPP ${d.no}', Ac.hpp, d.legacy ? Ac.modal : Ac.persediaan, cogs[d.id] ?? 0);
      if (d.orderId != null) {
        final dp = received[d.orderId] ?? 0;
        move(d.at, d.no, 'DP pemesanan dipindah ke ${d.no}', Ac.uangMuka, Ac.piutang, dp);
      }
    }

    for (final p in await select(purchases).get()) {
      move(
        p.at,
        'Beli #${p.id}',
        'Pembelian stok${p.supplier.isEmpty ? '' : ' — ${p.supplier}'}',
        Ac.persediaan,
        Ac.utangUsaha,
        p.total,
      );
    }

    for (final c in cash) {
      final kas = Ac.kas(c.accountId), a = c.amount;
      final ref = c.kind == 'payment' || c.kind == 'refund' ? (docs[c.refId]?.no ?? 'Kas #${c.id}') : 'Kas #${c.id}';
      switch (c.kind) {
        case 'payment' || 'refund':
          final d = docs[c.refId];
          final onOpenInvoice = d != null && d.kind == DocKind.invoice && !d.isVoid;
          move(c.at, ref, c.description, kas, onOpenInvoice ? Ac.piutang : Ac.uangMuka, a);
        case 'purchase':
          move(c.at, ref, c.description, Ac.utangUsaha, kas, -a);
        case expenseKind:
          final cat = cats[c.refId];
          final code = cat == null ? Ac.biayaLain : (cat.personal ? Ac.prive : Ac.biaya(cat.id));
          move(c.at, ref, c.description, code, kas, -a);
        case salaryKind:
          move(c.at, ref, c.description, Ac.gaji, kas, -a);
        case CashKind.transfer:
          move(c.at, ref, c.description, kas, Ac.transfer, a);
        case CashKind.capital:
          move(c.at, ref, c.description, kas, Ac.modal, a);
        default: // income & jenis tak dikenal
          move(c.at, ref, c.description, kas, Ac.pendapatanLain, a);
      }
    }

    // Stok: opname (adjust) & stok awal dinilai harga beli saat ini.
    final adj = select(stockMoves).join([innerJoin(products, products.id.equalsExp(stockMoves.productId))])
      ..where(stockMoves.kind.isIn(['adjust', 'opening']));
    for (final r in await adj.get()) {
      final m = r.readTable(stockMoves), p = r.readTable(products);
      move(
        m.at,
        'Stok #${m.id}',
        '${m.kind == 'opening' ? 'Stok awal' : 'Opname'} ${p.name}',
        Ac.persediaan,
        m.kind == 'opening' ? Ac.modal : Ac.selisihStok,
        m.qty * p.buyPrice,
      );
    }

    // Urut tanggal; tanggal sama tetap urut pembuatan (List.sort tidak dijamin stabil → pakai indeks).
    final order = {for (final (i, e) in out.indexed) e: i};
    out.sort((a, b) {
      final c = a.at.compareTo(b.at);
      return c != 0 ? c : order[a]!.compareTo(order[b]!);
    });
    return Journal(out, coa);
  }

  /// Bagan akun: akun tetap + satu akun per rekening & per kategori biaya operasional.
  Future<({Map<String, Coa> coa, Map<int, Account> accts, Map<int, ExpenseCategory> cats})> _coa() async {
    final coa = <String, Coa>{
      for (final c in const [
        Coa(Ac.piutang, 'Piutang Usaha', AcctKind.asset),
        Coa(Ac.persediaan, 'Persediaan', AcctKind.asset),
        Coa(Ac.transfer, 'Transfer Antar Rekening (perantara)', AcctKind.asset),
        Coa(Ac.utangUsaha, 'Utang Usaha', AcctKind.liability),
        Coa(Ac.uangMuka, 'Uang Muka Pemesanan', AcctKind.liability),
        Coa(Ac.utangPpn, 'Utang PPN', AcctKind.liability),
        Coa(Ac.modal, 'Modal Pemilik', AcctKind.equity),
        Coa(Ac.prive, 'Prive (pengeluaran pribadi)', AcctKind.equity),
        Coa(Ac.penjualan, 'Penjualan', AcctKind.revenue),
        Coa(Ac.pendapatanLain, 'Pemasukan Lain', AcctKind.revenue),
        Coa(Ac.hpp, 'Harga Pokok Penjualan', AcctKind.expense),
        Coa(Ac.selisihStok, 'Selisih / Penyesuaian Stok', AcctKind.expense),
        Coa(Ac.gaji, 'Beban Gaji', AcctKind.expense),
        Coa(Ac.biayaLain, 'Biaya Tanpa Kategori', AcctKind.expense),
      ])
        c.code: c,
    };
    final accts = {for (final a in await select(accounts).get()) a.id: a};
    for (final a in accts.values) {
      coa[Ac.kas(a.id)] = Coa(Ac.kas(a.id), 'Kas & Bank — ${a.name}', AcctKind.asset);
    }
    final cats = {for (final c in await select(expenseCategories).get()) c.id: c};
    for (final c in cats.values) {
      if (!c.personal) coa[Ac.biaya(c.id)] = Coa(Ac.biaya(c.id), 'Biaya — ${c.name}', AcctKind.expense);
    }
    return (coa: coa, accts: accts, cats: cats);
  }
}
