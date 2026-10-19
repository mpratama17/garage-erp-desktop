import 'package:drift/drift.dart' show TableUpdateQuery, Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/table.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import 'kontak_controller.dart';
import '../penjualan/penjualan_page.dart' show statusPill;
import '../penjualan/penjualan_repo.dart';
import 'kontak_repo.dart';

class KontakPage extends StatelessWidget {
  const KontakPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(KontakController(Get.find<AppDb>()));
    final owner = Get.find<OwnerController>();

    Future<void> ownerAction(Future<String?> Function() run) async {
      if (!await owner.ensure(context)) return;
      final msg = await run();
      if (msg != null && context.mounted) toast(context, msg);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => PageHeader(
            title: 'Kontak',
            subtitle: '${c.customers.length} customer · nama, no. HP, mobil, dan plat.',
            actions: [
              OutlinedButton(
                onPressed: () async {
                  final msg = await c.downloadTemplate();
                  if (msg != null && context.mounted) toast(context, msg);
                },
                child: const Text('Template'),
              ),
              OutlinedButton(
                onPressed: () => ownerAction(() async {
                  final r = await c.import();
                  if (r == null) return null;
                  if (r.notes.isNotEmpty && context.mounted) await _showNotes(context, r.summary, r.notes);
                  return r.summary;
                }),
                child: const Text('Import'),
              ),
              OutlinedButton(onPressed: () => ownerAction(c.export), child: const Text('Export')),
              FilledButton.icon(
                onPressed: () => c.panelId.value = 0,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Customer'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.lg),
          child: _Stats(db: c.db),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xl),
            child: Obx(
              () => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AppTable<Customer>(
                      rows: c.customers.toList(),
                      searchHint: 'Cari nama, no. HP, plat…',
                      // HP dicocokkan juga tanpa 0 di depan / format apa pun yang diketik.
                      searchText: (x) => [
                        x.name,
                        x.phone ?? '',
                        if (x.phone != null) displayPhone(x.phone!),
                        x.car,
                        x.plate,
                        x.plate.replaceAll(' ', ''),
                      ].join(' '),
                      selected: (x) => x.id == c.panelId.value,
                      onTap: (x) => c.panelId.value = x.id,
                      emptyMessage: 'Belum ada customer. Tambah customer atau Import dari Google Sheet (.xlsx).',
                      columns: [
                        Col('Nama', (x) => Text(x.name, style: const TextStyle(fontWeight: FontWeight.w600)), flex: 4),
                        Col('No. HP', (x) => Text(x.phone == null ? '—' : displayPhone(x.phone!)), flex: 3),
                        Col('Mobil', (x) => Text(x.car.isEmpty ? '—' : x.car), flex: 3),
                        Col('Plat', (x) => Text(x.plate.isEmpty ? '—' : x.plate), flex: 2),
                        Col('Catatan', (x) => Text(x.note, style: T.body.copyWith(color: C.inkMuted)), flex: 4),
                      ],
                    ),
                  ),
                  if (c.panelId.value != null) ...[
                    const SizedBox(width: S.lg),
                    SizedBox(
                      width: 400,
                      child: _CustomerPanel(key: ValueKey((c.panelId.value, c.opened)), c: c, item: c.opened),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showNotes(BuildContext context, String summary, List<String> notes) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Import selesai: $summary'),
      content: SizedBox(
        width: 560,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: SingleChildScrollView(child: SelectableText(notes.join('\n'))),
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
    ),
  );
}

class _CustomerPanel extends StatefulWidget {
  const _CustomerPanel({super.key, required this.c, required this.item});
  final KontakController c;
  final Customer? item;
  @override
  State<_CustomerPanel> createState() => _CustomerPanelState();
}

class _CustomerPanelState extends State<_CustomerPanel> {
  late final x = widget.item;
  late final name = TextEditingController(text: x?.name);
  late final phone = TextEditingController(text: x?.phone == null ? '' : displayPhone(x!.phone!));
  late final car = TextEditingController(text: x?.car);
  late final plate = TextEditingController(text: x?.plate);
  late final note = TextEditingController(text: x?.note);

  @override
  void dispose() {
    for (final t in [name, phone, car, plate, note]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final id = await widget.c.db.saveCustomer(
        CustomersCompanion(
          id: x == null ? const Value.absent() : Value(x!.id),
          name: Value(name.text),
          phone: Value(phone.text),
          car: Value(car.text),
          plate: Value(plate.text),
          note: Value(note.text),
        ),
      );
      widget.c.panelId.value = id;
      if (mounted) toast(context, 'Customer tersimpan');
    } on ArgumentError catch (e) {
      if (mounted) toast(context, '${e.message}');
    } catch (e) {
      if (mounted) toast(context, 'Gagal menyimpan: $e');
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${x!.name}?'),
        content: const Text('Data customer ini dihapus permanen.'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.c.db.deleteCustomer(x!.id);
    widget.c.panelId.value = null;
    if (mounted) toast(context, 'Customer dihapus');
  }

  @override
  Widget build(BuildContext context) {
    Widget gap() => const SizedBox(height: S.md);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(S.xl, S.lg, S.sm, S.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(x == null ? 'Customer baru' : x!.name, style: T.section, overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => widget.c.panelId.value = null,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(S.xl),
              children: [
                TextField(
                  controller: name,
                  autofocus: x == null,
                  decoration: const InputDecoration(labelText: 'Nama *'),
                ),
                gap(),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'No. HP', hintText: '08…'),
                ),
                gap(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: car,
                        decoration: const InputDecoration(labelText: 'Mobil', hintText: 'mis. Toyota Innova'),
                      ),
                    ),
                    const SizedBox(width: S.md),
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: plate,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'Plat'),
                      ),
                    ),
                  ],
                ),
                gap(),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Catatan'),
                ),
                gap(),
                Row(
                  children: [
                    if (x != null)
                      TextButton(
                        onPressed: _delete,
                        style: TextButton.styleFrom(foregroundColor: C.danger),
                        child: const Text('Hapus'),
                      ),
                    const Spacer(),
                    OutlinedButton(onPressed: () => widget.c.panelId.value = null, child: const Text('Batal')),
                    const SizedBox(width: S.sm),
                    FilledButton(onPressed: _save, child: const Text('Simpan')),
                  ],
                ),
                if (x != null) ...[const SizedBox(height: S.xl), _History(db: widget.c.db, customerId: x!.id)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Riwayat belanja satu customer (invoice saja, batal tidak dihitung ke total).
class _History extends StatelessWidget {
  const _History({required this.db, required this.customerId});
  final AppDb db;
  final int customerId;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<DocSummary>>(
    stream: db.watchCustomerInvoices(customerId),
    builder: (_, snap) {
      final all = snap.data ?? const <DocSummary>[];
      final valid = all.where((s) => !s.doc.isVoid).toList();
      final total = valid.fold(0, (t, s) => t + s.total);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Riwayat belanja', style: T.section),
          const SizedBox(height: S.sm),
          Text(
            valid.isEmpty
                ? 'Belum ada invoice.'
                : '${valid.length} invoice · total ${rupiah(total)} · terakhir ${tgl(valid.first.doc.at)}',
            style: T.label,
          ),
          const SizedBox(height: S.sm),
          for (final s in all)
            Container(
              padding: const EdgeInsets.symmetric(vertical: S.sm),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: C.border)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 88, child: Text(tgl(s.doc.at), style: T.label)),
                  Expanded(
                    child: Text(
                      [s.doc.no, s.doc.plate].where((x) => x.isNotEmpty).join(' · '),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  statusPill(s),
                  const SizedBox(width: S.sm),
                  Text(rp(s.total), style: T.money),
                ],
              ),
            ),
        ],
      );
    },
  );
}

/// Pelanggan aktif, % repeat order, dan top pelanggan — bulan ini / tahun ini.
class _Stats extends StatefulWidget {
  const _Stats({required this.db});
  final AppDb db;
  @override
  State<_Stats> createState() => _StatsState();
}

class _StatsState extends State<_Stats> {
  bool yearly = false;
  late var stream = _watch();

  /// Dihitung ulang setiap invoice/baris/customer berubah. Periode dihitung saat itu juga,
  /// jadi "Bulan ini" ikut berganti walau app terbuka melewati pergantian bulan.
  Stream<({int active, double repeatPct, List<({Customer customer, int total, int count})> top})> _watch() async* {
    final db = widget.db;
    final changes = db.tableUpdates(TableUpdateQuery.onAllTables([db.invoices, db.invoiceLines, db.customers]));
    yield await _compute();
    await for (final _ in changes) {
      yield await _compute();
    }
  }

  Future<({int active, double repeatPct, List<({Customer customer, int total, int count})> top})> _compute() {
    final now = DateTime.now();
    final from = yearly ? DateTime(now.year) : DateTime(now.year, now.month);
    final to = yearly ? DateTime(now.year + 1) : DateTime(now.year, now.month + 1);
    return widget.db.customerStats(from, to);
  }

  @override
  Widget build(BuildContext context) {
    Widget card(String label, String value, {Widget? extra}) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(S.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: T.label),
              const SizedBox(height: S.xs),
              Text(value, style: T.kpi.copyWith(fontSize: 22)),
              ?extra,
            ],
          ),
        ),
      ),
    );
    return StreamBuilder(
      stream: stream,
      builder: (_, snap) {
        final st = snap.data;
        final top = st?.top ?? const [];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            card(
              'Pelanggan aktif',
              '${st?.active ?? 0}',
              extra: Padding(
                padding: const EdgeInsets.only(top: S.sm),
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: const [
                    ButtonSegment(value: false, label: Text('Bulan ini')),
                    ButtonSegment(value: true, label: Text('Tahun ini')),
                  ],
                  selected: {yearly},
                  onSelectionChanged: (v) => setState(() {
                    yearly = v.first;
                    stream = _watch();
                  }),
                ),
              ),
            ),
            const SizedBox(width: S.md),
            card('Repeat order', '${(st?.repeatPct ?? 0).toStringAsFixed(0)}%'),
            const SizedBox(width: S.md),
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(S.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top pelanggan', style: T.label),
                      const SizedBox(height: S.xs),
                      if (top.isEmpty) Text('Belum ada transaksi.', style: T.pageSubtitle),
                      for (final (i, t) in top.take(3).indexed)
                        Row(
                          children: [
                            SizedBox(width: 20, child: Text('${i + 1}', style: T.label)),
                            Expanded(child: Text(t.customer.name, overflow: TextOverflow.ellipsis)),
                            Text('${t.count}× · ${rp(t.total)}', style: T.money),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
