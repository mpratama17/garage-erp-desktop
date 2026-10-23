import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import 'biaya_controller.dart';
import 'biaya_repo.dart';

/// Daftar biaya berulang: tiap templat punya tombol Catat (tanggal + pegawai yang masuk). Kelola templat = owner.
Future<void> recurringDialog(BuildContext context, BiayaController c) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Biaya berulang'),
    content: SizedBox(
      width: 520,
      height: 380,
      child: Obx(() {
        if (c.recurring.isEmpty) {
          return const EmptyState(
            message: 'Belum ada biaya berulang. Buat templat, mis. "Uang transport" Rp20.000 per pegawai.',
          );
        }
        return ListView(
          children: [
            for (final t in c.recurring)
              ListTile(
                title: Text(t.name, style: t.active ? null : const TextStyle(color: C.inkMuted)),
                subtitle: Text(
                  [
                    '${rupiah(t.amount)}${t.perEmployee ? ' per pegawai' : ''}',
                    c.categories.firstWhereOrNull((k) => k.id == t.categoryId)?.name ?? '',
                    if (!t.active) 'nonaktif',
                  ].where((x) => x.isNotEmpty).join(' · '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Ubah templat',
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () async {
                        if (await Get.find<OwnerController>().ensure(ctx) && ctx.mounted) {
                          await _templateDialog(ctx, c, t);
                        }
                      },
                    ),
                    if (t.active) FilledButton(onPressed: () => _recordDialog(ctx, c, t), child: const Text('Catat')),
                  ],
                ),
              ),
          ],
        );
      }),
    ),
    actions: [
      OutlinedButton(
        onPressed: () async {
          if (await Get.find<OwnerController>().ensure(ctx) && ctx.mounted) await _templateDialog(ctx, c, null);
        },
        child: const Text('+ Templat'),
      ),
      FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Selesai')),
    ],
  ),
);

/// Catat satu templat pada satu tanggal: centang pegawai yang masuk (templat per-pegawai).
Future<void> _recordDialog(BuildContext context, BiayaController c, RecurringExpense t) async {
  var date = DateTime.now();
  final people = c.employees.where((e) => e.active).toList();
  final picked = <int>{for (final e in people) e.id};
  var busy = false;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final n = t.perEmployee ? picked.length : 1;
        return AlertDialog(
          title: Text('Catat ${t.name}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 160, child: dateField(ctx, date, (d) => setState(() => date = d))),
                if (t.perEmployee) ...[
                  const SizedBox(height: S.md),
                  Text('Pegawai yang masuk', style: T.fieldLabel),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final e in people)
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(e.name),
                              value: picked.contains(e.id),
                              onChanged: (v) => setState(() => v == true ? picked.add(e.id) : picked.remove(e.id)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: S.md),
                Text('Total ${rupiah(t.amount * n)} ($n × ${rupiah(t.amount)})', style: T.section),
              ],
            ),
          ),
          actions: [
            OutlinedButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      final ok = await runAction(
                        ctx,
                        () => c.db.recordRecurring(t.id, date, employeeIds: picked.toList()),
                        '${t.name} tercatat',
                      );
                      if (!ctx.mounted) return;
                      if (ok) {
                        Navigator.pop(ctx);
                      } else {
                        setState(() => busy = false);
                      }
                    },
              child: const Text('Catat'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _templateDialog(BuildContext context, BiayaController c, RecurringExpense? t) async {
  final accounts = await (c.db.select(c.db.accounts)..where((a) => a.active.equals(true))).get();
  if (!context.mounted) return;
  if (accounts.isEmpty) return warn(context, 'Belum ada rekening aktif');
  final categories = c.categories.where((k) => k.active || k.id == t?.categoryId).toList();
  final name = TextEditingController(text: t?.name ?? 'Uang transport');
  final amount = TextEditingController(text: t == null ? '' : rp(t.amount));
  int? categoryId = t?.categoryId ?? categories.firstWhereOrNull((k) => k.name == 'Transportasi')?.id;
  int? accountId = t?.accountId ?? accounts.first.id;
  var perEmployee = t?.perEmployee ?? true, active = t?.active ?? true;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(t == null ? 'Templat baru' : 'Ubah templat'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Labeled('Nama biaya *', TextField(controller: name)),
              const SizedBox(height: S.md),
              MoneyField(controller: amount, label: 'Nominal per kejadian *'),
              const SizedBox(height: S.md),
              Labeled(
                'Kategori *',
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: categoryId,
                  items: [for (final k in categories) DropdownMenuItem(value: k.id, child: Text(k.name))],
                  onChanged: (v) => categoryId = v,
                ),
              ),
              const SizedBox(height: S.md),
              accountField('Dibayar dari rekening', accountId, accounts, (v) => accountId = v),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Per pegawai'),
                subtitle: const Text('Satu biaya untuk tiap pegawai yang dicentang saat mencatat.'),
                value: perEmployee,
                onChanged: (v) => setState(() => perEmployee = v),
              ),
              if (t != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (categoryId == null || accountId == null) return warn(ctx, 'Pilih kategori dan rekening');
              final ok = await runAction(
                ctx,
                () => c.db.saveRecurring(
                  RecurringExpensesCompanion(
                    id: t == null ? const Value.absent() : Value(t.id),
                    name: Value(name.text),
                    categoryId: Value(categoryId!),
                    accountId: Value(accountId!),
                    amount: Value(parseRupiah(amount.text)),
                    perEmployee: Value(perEmployee),
                    active: Value(active),
                  ),
                ),
                'Templat tersimpan',
              );
              if (ok && ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}
