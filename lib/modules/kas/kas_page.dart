import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/proof.dart';
import '../../core/table.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import 'kas_controller.dart';
import 'kas_repo.dart';

class KasPage extends StatelessWidget {
  const KasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(KasController(Get.find<AppDb>()));
    final owner = Get.find<OwnerController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Kas & Bank',
          subtitle: 'Saldo, mutasi, transfer.',
          actions: [
            OutlinedButton(onPressed: () => _incomeDialog(context, c), child: const Text('Uang masuk lain')),
            OutlinedButton(onPressed: () => _transferDialog(context, c), child: const Text('Transfer')),
            // Tambah rekening jarang dipakai (owner) → tombol sekunder, bukan aksi utama.
            OutlinedButton.icon(
              onPressed: () async {
                if (await owner.ensure(context) && context.mounted) await _accountDialog(context, c, null);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Rekening'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.lg),
          child: Obx(
            () => Wrap(
              spacing: S.md,
              runSpacing: S.md,
              children: [
                _BalanceCard(
                  icon: 'money-stack.png',
                  label: 'Semua rekening',
                  value: c.totalBalance,
                  selected: c.accountId.value == null,
                  onTap: () => c.accountId.value = null,
                ),
                for (final a in c.accounts)
                  _BalanceCard(
                    icon: _accountIcons[a.name.toLowerCase()],
                    label: a.active ? a.name : '${a.name} (nonaktif)',
                    value: c.balances[a.id],
                    note: a.note,
                    selected: c.accountId.value == a.id,
                    onTap: () => c.accountId.value = a.id,
                    onEdit: () async {
                      if (await owner.ensure(context) && context.mounted) await _accountDialog(context, c, a);
                    },
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: S.xxl),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 320,
              child: Obx(
                () => SegmentedButton<KasTab>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: KasTab.mutasi, label: Text('Mutasi')),
                    ButtonSegment(value: KasTab.arus, label: Text('Arus kas')),
                  ],
                  selected: {c.tab.value},
                  onSelectionChanged: (s) => c.tab.value = s.first,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: S.lg),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xl),
            child: Obx(() => c.tab.value == KasTab.mutasi ? _Mutasi(c: c) : _Arus(c: c)),
          ),
        ),
      ],
    );
  }
}

/// Logo per nama rekening; rekening lain memakai ikon umum.
const _accountIcons = {
  'bca': 'bca-logo.png',
  'mandiri': 'mandiri-logo.png',
  'shopeepay': 'spay-logo.png',
  'tunai': 'money.png',
};

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.icon,
    this.note = '',
    this.onEdit,
  });
  final String? icon; // file di assets/icons/
  final String label, note;
  final int? value; // null = owner terkunci → ••••
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Material(
      color: selected ? C.primarySoft : C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(S.rCard),
        side: BorderSide(color: selected ? C.primary : C.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(S.rCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(S.lg, S.md, S.xs, S.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 28,
                      child: icon == null
                          ? const Icon(Icons.account_balance_outlined, size: 24, color: C.inkMuted)
                          : Image.asset('assets/icons/$icon', height: 28, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: S.xs),
                    Text(label, style: T.label, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: S.xs),
                    // Saldo = data owner: •••• + gembok sampai PIN dimasukkan (klik = minta PIN).
                    OwnerOnly(
                      child: Text(
                        value == null ? '—' : rupiah(value!),
                        style: T.section.copyWith(
                          fontFeatures: T.money.fontFeatures,
                          color: (value ?? 0) < 0 ? C.danger : C.ink,
                        ),
                      ),
                    ),
                    Text(note, style: T.label, overflow: TextOverflow.ellipsis), // selalu ada agar tinggi kartu sama
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Ubah rekening',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Mutasi extends StatelessWidget {
  const _Mutasi({required this.c});
  final KasController c;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final single = c.accountId.value != null;
    final m = c.month.value;
    final rows = c.entries.toList();
    // Semua rekening: transfer internal bukan uang masuk/keluar usaha.
    final counted = rows.where((r) => single || r.entry.kind != CashKind.transfer);
    final income = counted.where((r) => r.entry.amount > 0).fold(0, (t, r) => t + r.entry.amount);
    final expense = counted.where((r) => r.entry.amount < 0).fold(0, (t, r) => t - r.entry.amount);
    return AppTable<EntryRow>(
      rows: rows,
      searchHint: 'Cari keterangan…',
      searchText: (r) => '${r.entry.description} ${r.entry.note} ${r.accountName} ${cashKindLabel[r.entry.kind]}',
      emptyMessage: 'Tidak ada transaksi di bulan ini.',
      toolbar: [
        Text('Masuk ${rp(income)} · Keluar ${rp(expense)}', style: T.label),
        const SizedBox(width: S.lg),
        MonthNav(month: m, onShift: c.shiftMonth),
      ],
      columns: [
        Col('Tanggal', (r) => Text(tgl(r.entry.at)), flex: 2),
        if (!single) Col('Rekening', (r) => Text(r.accountName), flex: 2),
        Col('Jenis', (r) => Pill(cashKindLabel[r.entry.kind] ?? r.entry.kind, _tone(r.entry.kind)), flex: 2),
        Col(
          'Keterangan',
          (r) => Text([r.entry.description, if (r.entry.note.isNotEmpty) r.entry.note].join(' · ')),
          flex: 6,
        ),
        Col(
          'Masuk',
          (r) => Text(r.entry.amount > 0 ? rp(r.entry.amount) : '', style: T.money.copyWith(color: Tone.success.fg)),
          flex: 2,
          numeric: true,
        ),
        Col(
          'Keluar',
          (r) => Text(r.entry.amount < 0 ? rp(-r.entry.amount) : '', style: T.money.copyWith(color: C.danger)),
          flex: 2,
          numeric: true,
        ),
        if (single && c.balances.isNotEmpty)
          Col(
            'Saldo',
            (r) => Text(r.balanceAfter == null ? '' : rp(r.balanceAfter!), style: T.money),
            flex: 2,
            numeric: true,
          ),
        Col('', (r) => _RowActions(r: r, c: c), flex: 1, numeric: true),
      ],
    );
  }

  static Tone _tone(String kind) => switch (kind) {
    'payment' || 'capital' || 'income' => Tone.success,
    'transfer' => Tone.info,
    'refund' => Tone.warning,
    _ => Tone.neutral,
  };
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.r, required this.c});
  final EntryRow r;
  final KasController c;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (r.entry.proofPath.isNotEmpty)
        IconButton(
          tooltip: 'Buka bukti',
          onPressed: () => runAction(
            context,
            () => launchUrl(Uri.file(r.entry.proofPath)),
            null,
            'File bukti tidak bisa dibuka — mungkin sudah dipindah atau dihapus.',
          ),
          icon: const Icon(Icons.attach_file, size: 18),
        ),
      if (CashKind.manual.contains(r.entry.kind))
        IconButton(
          tooltip: 'Hapus transaksi',
          onPressed: () async {
            if (!await Get.find<OwnerController>().ensure(context) || !context.mounted) return;
            final ok = await confirmAction(
              context,
              title: 'Hapus transaksi ini?',
              message: r.entry.kind == CashKind.transfer
                  ? 'Transfer dihapus di kedua rekening.'
                  : '${r.entry.description} · ${rupiah(r.entry.amount)}',
              confirmLabel: 'Hapus transaksi',
              destructive: true,
            );
            if (ok && context.mounted) {
              await runAction(context, () => c.db.deleteManualEntry(r.entry.id), 'Transaksi dihapus');
            }
          },
          icon: const Icon(Icons.delete_outline, size: 18),
        ),
    ],
  );
}

class _Arus extends StatelessWidget {
  const _Arus({required this.c});
  final KasController c;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final rows = c.flow.toList();
    final income = rows.fold(0, (t, f) => t + f.income), expense = rows.fold(0, (t, f) => t + f.expense);
    Widget cell(String t, {TextStyle? style, int flex = 2, bool right = true}) => Expanded(
      flex: flex,
      child: Text(t, textAlign: right ? TextAlign.right : TextAlign.left, style: style ?? T.money),
    );
    Widget row(FlowRow? f, {bool header = false}) => Container(
      height: S.row,
      padding: const EdgeInsets.symmetric(horizontal: S.lg),
      decoration: BoxDecoration(
        color: header ? C.bg : null,
        border: const Border(bottom: BorderSide(color: C.border)),
      ),
      child: Row(
        children: header
            ? [
                cell('Periode', style: T.label, flex: 3, right: false),
                cell('Pemasukan', style: T.label),
                cell('Pengeluaran', style: T.label),
                cell('Arus kas bersih', style: T.label),
              ]
            : [
                cell(f!.label, style: T.body, flex: 3, right: false),
                cell(rp(f.income), style: T.money.copyWith(color: Tone.success.fg)),
                cell(rp(f.expense), style: T.money.copyWith(color: C.danger)),
                cell(
                  rp(f.net),
                  style: T.money.copyWith(fontWeight: FontWeight.w600, color: f.net < 0 ? C.danger : C.ink),
                ),
              ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(S.md),
            child: Row(
              children: [
                SegmentedButton<Period>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: Period.daily, label: Text('Harian')),
                    ButtonSegment(value: Period.monthly, label: Text('Bulanan')),
                    ButtonSegment(value: Period.quarterly, label: Text('Kuartal')),
                    ButtonSegment(value: Period.yearly, label: Text('Tahunan')),
                  ],
                  selected: {c.period.value},
                  onSelectionChanged: (s) => c.period.value = s.first,
                ),
                const Spacer(),
                if (c.period.value != Period.yearly) ...[
                  IconButton(
                    tooltip: 'Tahun sebelumnya',
                    onPressed: () => c.year.value--,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('${c.year.value}', style: T.section),
                  IconButton(
                    tooltip: 'Tahun berikutnya',
                    onPressed: () => c.year.value++,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ],
            ),
          ),
          row(null, header: true),
          Expanded(
            child: rows.isEmpty
                ? Center(child: Text('Belum ada transaksi di periode ini.', style: T.pageSubtitle))
                : ListView(children: [for (final f in rows.reversed) row(f)]),
          ),
          Container(
            color: C.bg,
            padding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: S.md),
            child: Row(
              children: [
                cell('Total', style: T.section, flex: 3, right: false),
                cell(rp(income), style: T.money.copyWith(fontWeight: FontWeight.w600)),
                cell(rp(expense), style: T.money.copyWith(fontWeight: FontWeight.w600)),
                cell(
                  rp(income - expense),
                  style: T.money.copyWith(fontWeight: FontWeight.w700, color: income < expense ? C.danger : C.ink),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(S.lg, 0, S.lg, S.md),
            child: Text(
              'Transfer antar rekening tidak dihitung. Pembelian stok, biaya, gaji, dan pengembalian dana = pengeluaran.',
              style: T.label,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ dialog

Future<void> _transferDialog(BuildContext context, KasController c) async {
  final accounts = c.activeAccounts;
  if (accounts.length < 2) return warn(context, 'Butuh minimal 2 rekening aktif');
  int? from = accounts.first.id, to = accounts[1].id;
  var date = DateTime.now();
  var proof = '';
  final amount = TextEditingController(), note = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Transfer antar rekening'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: accountField('Dari', from, accounts, (v) => from = v)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: S.sm),
                    child: Icon(Icons.arrow_forward),
                  ),
                  Expanded(child: accountField('Ke', to, accounts, (v) => to = v)),
                ],
              ),
              const SizedBox(height: S.md),
              Row(
                children: [
                  Expanded(
                    child: MoneyField(controller: amount, label: 'Nominal *'),
                  ),
                  const SizedBox(width: S.md),
                  SizedBox(width: 140, child: dateField(ctx, date, (d) => setState(() => date = d))),
                ],
              ),
              const SizedBox(height: S.md),
              Labeled(
                'Keterangan',
                TextField(
                  controller: note,
                  decoration: const InputDecoration(hintText: 'mis. top up ShopeePay'),
                ),
              ),
              const SizedBox(height: S.md),
              proofRow(proof, () async {
                final p = await pickProof('transfer');
                if (p != null) setState(() => proof = p);
              }),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (from == null || to == null) return warn(ctx, 'Pilih rekening');
              await runAction(ctx, () async {
                await c.db.transfer(
                  fromId: from!,
                  toId: to!,
                  amount: parseRupiah(amount.text),
                  at: date,
                  note: note.text,
                  proofPath: proof,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }, 'Transfer tersimpan');
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _incomeDialog(BuildContext context, KasController c) async {
  final accounts = c.activeAccounts;
  if (accounts.isEmpty) return warn(context, 'Belum ada rekening aktif');
  int? accountId = accounts.first.id;
  var kind = CashKind.capital;
  var date = DateTime.now();
  var proof = '';
  final amount = TextEditingController(),
      desc = TextEditingController(text: 'Modal dari owner'),
      note = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Uang masuk lain'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: CashKind.capital, label: Text('Modal masuk')),
                  ButtonSegment(value: CashKind.income, label: Text('Pemasukan lain')),
                ],
                selected: {kind},
                onSelectionChanged: (s) => setState(() {
                  kind = s.first;
                  if (desc.text == 'Modal dari owner' && kind == CashKind.income) desc.clear();
                }),
              ),
              const SizedBox(height: S.md),
              Row(
                children: [
                  Expanded(child: accountField('Ke rekening', accountId, accounts, (v) => accountId = v)),
                  const SizedBox(width: S.md),
                  SizedBox(width: 140, child: dateField(ctx, date, (d) => setState(() => date = d))),
                ],
              ),
              const SizedBox(height: S.md),
              MoneyField(controller: amount, label: 'Nominal *'),
              const SizedBox(height: S.md),
              Labeled('Keterangan *', TextField(controller: desc)),
              const SizedBox(height: S.md),
              Labeled('Catatan', TextField(controller: note)),
              const SizedBox(height: S.md),
              proofRow(proof, () async {
                final p = await pickProof('pemasukan');
                if (p != null) setState(() => proof = p);
              }),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (accountId == null) return warn(ctx, 'Pilih rekening');
              await runAction(ctx, () async {
                await c.db.addIncome(
                  accountId: accountId!,
                  amount: parseRupiah(amount.text),
                  at: date,
                  kind: kind,
                  description: desc.text,
                  note: note.text,
                  proofPath: proof,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }, 'Tersimpan');
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}

/// Tambah ([a] null) / ubah rekening — owner.
Future<void> _accountDialog(BuildContext context, KasController c, Account? a) async {
  final name = TextEditingController(text: a?.name);
  final opening = TextEditingController(text: a == null ? '' : rp(a.openingBalance));
  final note = TextEditingController(text: a?.note);
  var active = a?.active ?? true;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(a == null ? 'Rekening baru' : 'Ubah rekening ${a.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Labeled('Nama *', TextField(controller: name, autofocus: a == null)),
              const SizedBox(height: S.md),
              MoneyField(controller: opening, label: 'Saldo awal', hint: 'saat mulai pakai app'),
              const SizedBox(height: S.md),
              Labeled(
                'Keterangan',
                TextField(
                  controller: note,
                  decoration: const InputDecoration(hintText: 'mis. no. rekening / atas nama'),
                ),
              ),
              if (a != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  subtitle: const Text('Tidak bisa dipilih untuk transaksi baru.'),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => runAction(ctx, () async {
              await c.db.saveAccount(
                AccountsCompanion(
                  id: a == null ? const Value.absent() : Value(a.id),
                  name: Value(name.text),
                  openingBalance: Value(parseRupiah(opening.text)),
                  note: Value(note.text),
                  active: Value(active),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            }, 'Rekening tersimpan'),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}
