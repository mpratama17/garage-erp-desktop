import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/proof.dart';
import '../../core/table.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import '../penjualan/penjualan_repo.dart';
import 'gaji_controller.dart';
import 'gaji_repo.dart';

/// Gaji & insentif — seluruh halaman khusus owner (berisi gaji karyawan).
class GajiPage extends StatelessWidget {
  const GajiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final owner = Get.find<OwnerController>();
    return Obx(() {
      if (!owner.isOwner.value) {
        return EmptyState(
          message: 'Gaji & insentif hanya untuk owner.',
          action: FilledButton(onPressed: () => owner.ensure(context), child: const Text('Buka dengan PIN')),
        );
      }
      return const _Gaji();
    });
  }
}

class _Gaji extends StatelessWidget {
  const _Gaji();

  @override
  Widget build(BuildContext context) {
    final c = Get.put(GajiController(Get.find<AppDb>()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Gaji',
          subtitle: 'Slip gaji per periode: gaji pokok, makan, insentif teknisi, tunjangan kerja sales.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => _employeeDialog(context, c, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Karyawan'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.lg),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 320,
              child: Obx(
                () => SegmentedButton<GajiTab>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: GajiTab.slip, label: Text('Slip gaji')),
                    ButtonSegment(value: GajiTab.karyawan, label: Text('Karyawan')),
                  ],
                  selected: {c.tab.value},
                  onSelectionChanged: (s) => c.tab.value = s.first,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xl),
            child: Obx(() => c.tab.value == GajiTab.slip ? _slips(context, c) : _employees(context, c)),
          ),
        ),
      ],
    );
  }

  Widget _slips(BuildContext context, GajiController c) {
    final p = c.period.value;
    return AppTable<Slip>(
      rows: c.slips.toList(),
      searchHint: 'Cari karyawan…',
      searchText: (s) => s.employee.name,
      emptyMessage: 'Belum ada karyawan. Tambah lewat tombol Karyawan.',
      onTap: (s) => _slipDialog(context, c, s),
      toolbar: [
        Text('Total ${rp(c.total)}', style: T.label),
        const SizedBox(width: S.lg),
        IconButton(tooltip: 'Periode sebelumnya', onPressed: () => c.shift(-1), icon: const Icon(Icons.chevron_left)),
        SizedBox(
          width: 230,
          child: Text(p == null ? '' : periodLabel(p.$1, p.$2), textAlign: TextAlign.center, style: T.section),
        ),
        IconButton(tooltip: 'Periode berikutnya', onPressed: () => c.shift(1), icon: const Icon(Icons.chevron_right)),
      ],
      columns: [
        Col('Nama', (s) => Text(s.employee.name), flex: 3),
        Col('Peran', (s) => Text(employeeRoles[s.employee.role] ?? s.employee.role), flex: 2),
        Col('Gaji pokok', (s) => Text(rp(s.baseSalary), style: T.money), flex: 2, numeric: true),
        Col('Makan', (s) => Text(rp(s.mealAllowance), style: T.money), flex: 2, numeric: true),
        Col(
          'Insentif / tunj. kerja',
          (s) => Text(rp(s.incentive + s.commission), style: T.money),
          flex: 3,
          numeric: true,
        ),
        Col('Lembur + bonus', (s) => Text(rp(s.overtime + s.bonus), style: T.money), flex: 2, numeric: true),
        Col('Potongan', (s) => Text(rp(s.deduction), style: T.money), flex: 2, numeric: true),
        Col(
          'Total',
          (s) => Text(rp(s.total), style: T.money.copyWith(fontWeight: FontWeight.w700)),
          flex: 2,
          numeric: true,
        ),
        Col('Status', (s) => s.paid ? const Pill('Dibayar', Tone.success) : const Pill('Belum', Tone.neutral), flex: 2),
      ],
    );
  }

  Widget _employees(BuildContext context, GajiController c) => AppTable<Employee>(
    rows: c.employees.toList(),
    searchHint: 'Cari karyawan…',
    searchText: (e) => e.name,
    emptyMessage: 'Belum ada karyawan.',
    onTap: (e) => _employeeDialog(context, c, e),
    columns: [
      Col('Nama', (e) => Text(e.name), flex: 3),
      Col('Peran', (e) => Text(employeeRoles[e.role] ?? e.role), flex: 2),
      Col('Gaji pokok', (e) => Text(rp(e.baseSalary), style: T.money), flex: 2, numeric: true),
      Col('Tunjangan makan', (e) => Text(rp(e.mealAllowance), style: T.money), flex: 2, numeric: true),
      Col(
        'Status',
        (e) => e.active ? const Pill('Aktif', Tone.success) : const Pill('Nonaktif', Tone.neutral),
        flex: 2,
      ),
    ],
  );
}

// ------------------------------------------------------------------ slip

Future<void> _slipDialog(BuildContext context, GajiController c, Slip s) async {
  final isSales = s.employee.role == 'sales';
  final overtime = TextEditingController(text: rp(s.overtime)),
      bonus = TextEditingController(text: rp(s.bonus)),
      deduction = TextEditingController(text: rp(s.deduction)),
      commission = TextEditingController(
        text: s.saved?.commissionOverride == null ? '' : rp(s.saved!.commissionOverride!),
      ),
      note = TextEditingController(text: s.saved?.note);

  Future<void> save() => c.db.saveSlip(
    employeeId: s.employee.id,
    start: s.start,
    commission: commission.text.trim().isEmpty ? null : parseRupiah(commission.text),
    overtime: parseRupiah(overtime.text),
    bonus: parseRupiah(bonus.text),
    deduction: parseRupiah(deduction.text),
    note: note.text,
  );

  Widget row(String label, int value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: S.xs),
    child: Row(
      children: [
        Expanded(child: Text(label, style: bold ? T.section : null)),
        Text(rupiah(value), style: T.money.copyWith(fontWeight: bold ? FontWeight.w700 : null)),
      ],
    ),
  );

  // Total ikut isian yang sedang diketik (belum disimpan).
  int liveTotal() => s.paid
      ? s.total
      : s.totalWith(
          commission: !isSales
              ? null
              : (commission.text.trim().isEmpty ? s.autoCommission : parseRupiah(commission.text)),
          overtime: parseRupiah(overtime.text),
          bonus: parseRupiah(bonus.text),
          deduction: parseRupiah(deduction.text),
        );

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Slip gaji ${s.employee.name} · ${periodLabel(s.start, s.end)}'),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                row('Gaji pokok', s.baseSalary),
                row('Tunjangan makan', s.mealAllowance),
                if (s.incentive != 0 || !isSales) row('Insentif pekerjaan (${s.lines.length} pekerjaan)', s.incentive),
                if (isSales || s.commission != 0)
                  row(
                    s.paid || s.saved?.commissionOverride != null
                        ? 'Tunjangan kerja'
                        : 'Tunjangan kerja (omzet ${rupiah(s.omzet)} × ${s.commissionPct}%)',
                    s.commission,
                  ),
                if (s.paid) ...[
                  row('Lembur', s.overtime),
                  row('Bonus / THR', s.bonus),
                  row('Potongan', -s.deduction),
                ] else ...[
                  const SizedBox(height: S.md),
                  Row(
                    children: [
                      Expanded(
                        child: MoneyField(controller: overtime, label: 'Lembur', onChanged: (_) => setState(() {})),
                      ),
                      const SizedBox(width: S.md),
                      Expanded(
                        child: MoneyField(controller: bonus, label: 'Bonus / THR', onChanged: (_) => setState(() {})),
                      ),
                      const SizedBox(width: S.md),
                      Expanded(
                        child: MoneyField(
                          controller: deduction,
                          label: 'Potongan (kasbon, dll)',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (isSales) ...[
                    const SizedBox(height: S.md),
                    MoneyField(
                      controller: commission,
                      onChanged: (_) => setState(() {}),
                      label: 'Koreksi tunjangan kerja (kosong = otomatis ${rp(s.autoCommission)})',
                    ),
                  ],
                  const SizedBox(height: S.md),
                  TextField(
                    controller: note,
                    decoration: const InputDecoration(labelText: 'Catatan'),
                  ),
                ],
                const Divider(height: S.xl),
                row(s.paid ? 'Total dibayar' : 'Total', liveTotal(), bold: true),
                if (s.paid) Text('Dibayar ${tgl(s.payment!.at)} · ${s.payment!.description}', style: T.label),
                if (s.lines.isNotEmpty) ...[
                  const SizedBox(height: S.lg),
                  Text('Rincian insentif', style: T.section),
                  const SizedBox(height: S.sm),
                  _IncentiveTable(s.lines),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (s.paid)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: C.danger),
              onPressed: () async {
                final ok = await _confirm(
                  ctx,
                  'Batalkan pembayaran gaji?',
                  '${rupiah(s.total)} kembali ke rekening. Slip kembali mengikuti data terbaru.',
                );
                if (!ok || !ctx.mounted) return;
                await runAction(ctx, () async {
                  await c.db.cancelSlipPayment(s.saved!.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                }, 'Pembayaran dibatalkan');
              },
              child: const Text('Batalkan pembayaran'),
            ),
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: Text(s.paid ? 'Tutup' : 'Batal')),
          if (!s.paid) ...[
            OutlinedButton(
              onPressed: () => runAction(ctx, () async {
                await save();
                if (ctx.mounted) Navigator.pop(ctx);
              }, 'Slip tersimpan'),
              child: const Text('Simpan'),
            ),
            FilledButton(
              onPressed: () => runAction(ctx, () async {
                await save();
                if (ctx.mounted && await _payDialog(ctx, c, s) && ctx.mounted) Navigator.pop(ctx);
              }),
              child: const Text('Bayar'),
            ),
          ],
        ],
      ),
    ),
  );
  for (final t in [overtime, bonus, deduction, commission, note]) {
    t.dispose();
  }
}

class _IncentiveTable extends StatelessWidget {
  const _IncentiveTable(this.lines);
  final List<IncentiveLine> lines;

  @override
  Widget build(BuildContext context) {
    Widget cell(String t, {bool num = false, TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: S.sm),
      child: Text(t, textAlign: num ? TextAlign.right : null, style: style),
    );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(4),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(2),
        6: FlexColumnWidth(2),
      },
      border: const TableBorder(horizontalInside: BorderSide(color: C.border)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: C.bg),
          children: [
            for (final (h, n) in [
              ('Tanggal', false),
              ('Invoice', false),
              ('Mobil', false),
              ('Pekerjaan', false),
              ('Qty', true),
              ('Tarif', true),
              ('Bagian', true),
            ])
              cell(h, num: n, style: T.label),
          ],
        ),
        for (final l in lines)
          TableRow(
            children: [
              cell(tgl(l.invoice.at)),
              cell(l.invoice.no),
              cell([l.invoice.car, l.invoice.plate].where((x) => x.isNotEmpty).join(' · ')),
              cell(l.line.name),
              cell('${l.line.qty}', num: true),
              cell(rp(l.line.incentive), num: true),
              cell(l.shared ? '${rp(l.share)} (½)' : rp(l.share), num: true, style: T.money),
            ],
          ),
      ],
    );
  }
}

/// Pilih rekening & tanggal lalu bayar. true = berhasil dibayar.
Future<bool> _payDialog(BuildContext context, GajiController c, Slip s) async {
  final accounts = await c.db.watchActiveAccounts().first;
  if (!context.mounted) return false;
  if (accounts.isEmpty) {
    toast(context, 'Belum ada rekening aktif');
    return false;
  }
  int? accountId = accounts.first.id;
  var date = DateTime.now();
  var proof = '';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Bayar gaji ${s.employee.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: accountField('Dari rekening', accountId, accounts, (v) => accountId = v)),
                  const SizedBox(width: S.md),
                  SizedBox(width: 140, child: dateField(ctx, date, (d) => setState(() => date = d))),
                ],
              ),
              const SizedBox(height: S.md),
              proofRow(proof, () async {
                final p = await pickProof('gaji');
                if (p != null) setState(() => proof = p);
              }),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (accountId == null) return toast(ctx, 'Pilih rekening');
              await runAction(ctx, () async {
                await c.db.paySlip(
                  employeeId: s.employee.id,
                  start: s.start,
                  accountId: accountId!,
                  at: date,
                  proofPath: proof,
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              }, 'Gaji dibayar');
            },
            child: const Text('Bayar'),
          ),
        ],
      ),
    ),
  );
  return ok == true;
}

Future<bool> _confirm(BuildContext context, String title, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tidak')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    ) ==
    true;

// ------------------------------------------------------------------ karyawan

Future<void> _employeeDialog(BuildContext context, GajiController c, Employee? e) async {
  final name = TextEditingController(text: e?.name),
      base = TextEditingController(text: e == null ? '' : rp(e.baseSalary)),
      meal = TextEditingController(text: e == null ? '' : rp(e.mealAllowance));
  var role = e?.role ?? 'teknisi', active = e?.active ?? true;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(e == null ? 'Karyawan baru' : 'Ubah karyawan'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: e == null,
                decoration: const InputDecoration(labelText: 'Nama *'),
              ),
              const SizedBox(height: S.md),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [for (final r in employeeRoles.entries) ButtonSegment(value: r.key, label: Text(r.value))],
                selected: {role},
                onSelectionChanged: (s) => setState(() => role = s.first),
              ),
              const SizedBox(height: S.md),
              Row(
                children: [
                  Expanded(
                    child: MoneyField(controller: base, label: 'Gaji pokok'),
                  ),
                  const SizedBox(width: S.md),
                  Expanded(
                    child: MoneyField(controller: meal, label: 'Tunjangan makan'),
                  ),
                ],
              ),
              if (e != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  subtitle: const Text('Karyawan nonaktif tidak bisa dipilih di invoice dan tidak dibuatkan slip.'),
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
              await c.db.saveEmployee(
                EmployeesCompanion(
                  id: e == null ? const Value.absent() : Value(e.id),
                  name: Value(name.text),
                  role: Value(role),
                  baseSalary: Value(parseRupiah(base.text)),
                  mealAllowance: Value(parseRupiah(meal.text)),
                  active: Value(active),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            }, 'Karyawan tersimpan'),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
  for (final t in [name, base, meal]) {
    t.dispose();
  }
}
