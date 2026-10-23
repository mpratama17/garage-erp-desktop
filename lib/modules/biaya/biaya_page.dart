import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/proof.dart';
import '../../core/range_picker.dart';
import '../../core/table.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import 'biaya_controller.dart';
import 'biaya_recurring.dart';
import 'biaya_repo.dart';

class BiayaPage extends StatelessWidget {
  const BiayaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(BiayaController(Get.find<AppDb>()));
    final owner = Get.find<OwnerController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Biaya',
          subtitle: 'Operasional & pribadi. Stok dicatat di Gudang, gaji di Gaji.',
          actions: [
            OutlinedButton(onPressed: () => recurringDialog(context, c), child: const Text('Biaya berulang')),
            OutlinedButton(
              onPressed: () async {
                if (await owner.ensure(context) && context.mounted) await _categoriesDialog(context, c);
              },
              child: const Text('Kategori'),
            ),
            FilledButton.icon(
              onPressed: () => _expenseDialog(context, c, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Biaya'),
            ),
          ],
        ),
        Obx(
          () => KpiRow([
            KpiCard(
              icon: Icons.payments_outlined,
              tone: Tone.info,
              label: 'Total biaya',
              value: rupiah(c.total()),
              hint: '${c.expenses.length} biaya',
            ),
            KpiCard(
              icon: Icons.build_outlined,
              tone: Tone.warning,
              label: 'Operasional',
              value: rupiah(c.total(personal: false)),
              hint: 'Masuk laba rugi',
            ),
            KpiCard(
              icon: Icons.home_outlined,
              tone: Tone.purple,
              label: 'Pribadi',
              value: rupiah(c.total(personal: true)),
              hint: 'Di bawah laba bersih usaha',
            ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xl),
            child: Obx(() => _table(context, c)),
          ),
        ),
      ],
    );
  }

  Widget _table(BuildContext context, BiayaController c) => AppTable<ExpenseRow>(
    rows: c.shown,
    searchHint: 'Cari biaya…',
    searchText: (r) => '${r.entry.description} ${r.entry.note} ${r.category?.name ?? ''} ${r.accountName}',
    emptyMessage: 'Tidak ada biaya pada rentang ini.',
    onTap: (r) => _expenseDialog(context, c, r),
    toolbar: [
      SegmentedButton<BiayaFilter>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: BiayaFilter.semua, label: Text('Semua')),
          ButtonSegment(value: BiayaFilter.operasional, label: Text('Operasional')),
          ButtonSegment(value: BiayaFilter.pribadi, label: Text('Pribadi')),
        ],
        selected: {c.filter.value},
        onSelectionChanged: (s) => c.filter.value = s.first,
      ),
      const SizedBox(width: S.lg),
      RangeButton(range: c.range.value, onChanged: (r) => c.range.value = r!),
    ],
    columns: [
      Col('Tanggal', (r) => Text(tgl(r.entry.at)), flex: 2),
      Col('Kategori', (r) => Pill(r.category?.name ?? '-', r.personal ? Tone.warning : Tone.neutral), flex: 3),
      Col('Nama', (r) => Text([r.entry.description, if (r.entry.note.isNotEmpty) r.entry.note].join(' · ')), flex: 5),
      Col('Rekening', (r) => Text(r.accountName), flex: 2),
      Col('Nominal', (r) => Text(rp(r.amount), style: T.money), flex: 2, numeric: true),
      Col(
        '',
        (r) => r.entry.proofPath.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
                tooltip: 'Buka bukti',
                onPressed: () => runAction(
                  context,
                  () => launchUrl(Uri.file(r.entry.proofPath)),
                  null,
                  'File bukti tidak bisa dibuka — mungkin sudah dipindah atau dihapus.',
                ),
                icon: const Icon(Icons.attach_file, size: 18),
              ),
        flex: 1,
        numeric: true,
      ),
    ],
  );
}

String _categoryLabel(ExpenseCategory k) => k.personal ? '${k.name} (pribadi)' : k.name;

/// Catat biaya baru ([r] null) atau ubah/hapus biaya lama (owner).
Future<void> _expenseDialog(BuildContext context, BiayaController c, ExpenseRow? r) async {
  if (r != null && !(await Get.find<OwnerController>().ensure(context) && context.mounted)) return;
  final e = r?.entry;
  // Dibaca langsung (bukan dari stream controller yang mungkin belum terisi).
  // Biaya lama boleh tetap menunjuk rekening/kategori yang sudah nonaktif.
  final accounts = [
    for (final a in await c.db.select(c.db.accounts).get())
      if (a.active || a.id == e?.accountId) a,
  ];
  final categories = [
    for (final k in await c.db.categoriesQuery().get())
      if (k.active || k.id == e?.refId) k,
  ];
  if (!context.mounted) return;
  if (accounts.isEmpty) return warn(context, 'Belum ada rekening aktif');
  int? accountId = e?.accountId ?? accounts.first.id;
  // Kategori diketik/dicari lalu dipilih; yang dipakai = teks yang cocok persis dengan salah satu kategori.
  final current = categories.firstWhereOrNull((k) => k.id == e?.refId);
  final category = TextEditingController(text: current == null ? '' : _categoryLabel(current));
  var date = e?.at ?? DateTime.now();
  var proof = e?.proofPath ?? '';
  final name = TextEditingController(text: e?.description),
      amount = TextEditingController(text: r == null ? '' : rp(r.amount)),
      note = TextEditingController(text: e?.note);
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(r == null ? 'Catat biaya' : 'Ubah biaya'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Labeled(
                'Nama biaya *',
                TextField(
                  controller: name,
                  autofocus: r == null,
                  decoration: const InputDecoration(hintText: 'mis. Token listrik bengkel'),
                ),
              ),
              const SizedBox(height: S.md),
              Labeled(
                'Kategori *',
                DropdownMenu<int>(
                  controller: category,
                  expandedInsets: EdgeInsets.zero,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  menuHeight: 320,
                  hintText: 'Ketik untuk mencari…',
                  dropdownMenuEntries: [
                    for (final k in categories) DropdownMenuEntry(value: k.id, label: _categoryLabel(k)),
                  ],
                ),
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
              accountField('Dibayar dari rekening', accountId, accounts, (v) => accountId = v),
              const SizedBox(height: S.md),
              Labeled('Keterangan', TextField(controller: note)),
              const SizedBox(height: S.md),
              proofRow(proof, () async {
                final p = await pickProof('biaya');
                if (p != null) setState(() => proof = p);
              }),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: dialogActions(
          danger: r == null
              ? null
              : DangerButton(
                  label: 'Hapus',
                  onPressed: () async {
                    final ok = await confirmAction(
                      ctx,
                      title: 'Hapus biaya ini?',
                      message:
                          '${r.entry.description} · ${rupiah(r.amount)}\nSaldo ${r.accountName} bertambah kembali.',
                      confirmLabel: 'Hapus biaya',
                      destructive: true,
                    );
                    if (!ok || !ctx.mounted) return;
                    await runAction(ctx, () async {
                      await c.db.deleteExpense(r.entry.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }, 'Biaya dihapus');
                  },
                ),
          children: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                // Nama kategori unik (dicek di repo), jadi cocokkan teks tanpa beda huruf besar/spasi.
                final typed = category.text.trim().toLowerCase();
                final categoryId = categories.firstWhereOrNull((k) => _categoryLabel(k).toLowerCase() == typed)?.id;
                if (categoryId == null) return warn(ctx, 'Pilih kategori dari daftar');
                if (accountId == null) return warn(ctx, 'Pilih rekening');
                await runAction(ctx, () async {
                  await c.db.saveExpense(
                    id: e?.id,
                    at: date,
                    accountId: accountId!,
                    categoryId: categoryId,
                    description: name.text,
                    amount: parseRupiah(amount.text),
                    note: note.text,
                    proofPath: proof,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }, 'Biaya tersimpan');
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Kelola kategori (owner): tambah, ubah nama, tandai pribadi, nonaktifkan.
Future<void> _categoriesDialog(BuildContext context, BiayaController c) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Kategori biaya'),
    content: SizedBox(
      width: 480,
      height: 480,
      child: Obx(
        () => ListView(
          children: [
            for (final k in c.categories)
              ListTile(
                dense: true,
                title: Text(k.name, style: k.active ? null : const TextStyle(color: C.inkMuted)),
                subtitle: Text([k.personal ? 'Pribadi' : 'Operasional', if (!k.active) 'nonaktif'].join(' · ')),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _categoryDialog(ctx, c, k),
              ),
          ],
        ),
      ),
    ),
    actions: [
      OutlinedButton(onPressed: () => _categoryDialog(ctx, c, null), child: const Text('+ Kategori')),
      FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Selesai')),
    ],
  ),
);

Future<void> _categoryDialog(BuildContext context, BiayaController c, ExpenseCategory? k) async {
  final name = TextEditingController(text: k?.name);
  var personal = k?.personal ?? false, active = k?.active ?? true;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(k == null ? 'Kategori baru' : 'Ubah kategori'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Labeled('Nama *', TextField(controller: name, autofocus: k == null)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pengeluaran pribadi'),
                subtitle: const Text(
                  'Di laba rugi tampil di bawah laba bersih usaha. Berlaku juga untuk biaya lama di kategori ini.',
                ),
                value: personal,
                onChanged: (v) => setState(() => personal = v),
              ),
              if (k != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  subtitle: const Text('Tidak bisa dipilih untuk biaya baru.'),
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
              await c.db.saveCategory(
                ExpenseCategoriesCompanion(
                  id: k == null ? const Value.absent() : Value(k.id),
                  name: Value(name.text),
                  personal: Value(personal),
                  active: Value(active),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            }, 'Kategori tersimpan'),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}
