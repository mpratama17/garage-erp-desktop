import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import '../gudang/gudang_repo.dart';
import '../kontak/kontak_repo.dart';
import 'penjualan_controller.dart';
import 'penjualan_repo.dart';

/// Buka form invoice/pemesanan. [existing] = ubah; [legacy] = input transaksi lama.
/// Mengembalikan id dokumen yang tersimpan, atau null bila dibatalkan.
Future<int?> showDocEditor(
  BuildContext context,
  PenjualanController c, {
  required String kind,
  DocSummary? existing,
  bool legacy = false,
}) async {
  final lines = existing == null ? <InvoiceLine>[] : await c.db.watchLines(existing.doc.id).first;
  if (!context.mounted) return null;
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(S.xl),
      child: _DocEditor(c: c, kind: kind, existing: existing, lines: lines, legacy: legacy),
    ),
  );
}

class _Row {
  _Row({this.item, InvoiceLine? from})
    : description = TextEditingController(text: from?.description),
      qty = TextEditingController(text: '${from?.qty ?? 1}'),
      price = TextEditingController(text: rp(from?.price ?? item?.product.sellPrice ?? 0)),
      discount = TextEditingController(text: from == null || from.discount == 0 ? '' : rp(from.discount)),
      name = from?.name ?? item?.product.name ?? '',
      incentive = from?.incentive ?? item?.product.incentive ?? 0,
      cost = from?.cost,
      tech1 = from?.tech1Id,
      tech2 = from?.tech2Id;

  StockedProduct? item;
  String name;
  int incentive;
  int? cost; // modal yang sudah diisi owner terbawa saat invoice diubah; kosong lagi bila produk diganti
  int? tech1, tech2;
  final TextEditingController description, qty, price, discount;

  int get total => parseRupiah(qty.text) * parseRupiah(price.text) - parseRupiah(discount.text);

  void dispose() {
    for (final t in [description, qty, price, discount]) {
      t.dispose();
    }
  }
}

class _DocEditor extends StatefulWidget {
  const _DocEditor({required this.c, required this.kind, this.existing, required this.lines, required this.legacy});
  final PenjualanController c;
  final String kind;
  final DocSummary? existing;
  final List<InvoiceLine> lines;
  final bool legacy;
  @override
  State<_DocEditor> createState() => _DocEditorState();
}

class _DocEditorState extends State<_DocEditor> {
  late final c = widget.c;
  late final doc = widget.existing?.doc;
  late final isOrder = widget.kind == DocKind.order;
  late DateTime date = doc?.at ?? DateTime.now();
  late DateTime? due = doc?.dueAt ?? (isOrder ? null : DateTime.now().add(const Duration(days: 30)));
  late Customer? customer = c.customers.firstWhereOrNull((x) => x.id == doc?.customerId);
  late final car = TextEditingController(text: doc?.car);
  late final plate = TextEditingController(text: doc?.plate);
  late final note = TextEditingController(text: doc?.note);
  final legacyNo = TextEditingController();
  late final rows = widget.lines.isEmpty
      ? [_Row()]
      : [
          for (final l in widget.lines)
            _Row(item: c.products.firstWhereOrNull((p) => p.product.id == l.productId), from: l),
        ];
  bool payNow = true;
  final payAmount = TextEditingController();
  late int? accountId = c.accounts.firstOrNull?.id;

  bool get isNew => doc == null;
  int get total => rows.fold(0, (s, r) => s + (r.item == null ? 0 : r.total));

  @override
  void initState() {
    super.initState();
    payNow = isNew && !isOrder && !widget.legacy; // kasir: default langsung lunas
  }

  @override
  void dispose() {
    for (final r in rows) {
      r.dispose();
    }
    for (final t in [car, plate, note, legacyNo, payAmount]) {
      t.dispose();
    }
    super.dispose();
  }

  void _pickCustomer(Customer x) => setState(() {
    customer = x;
    if (car.text.isEmpty) car.text = x.car;
    if (plate.text.isEmpty) plate.text = x.plate;
  });

  Future<void> _newCustomer() async {
    final name = TextEditingController(), phone = TextEditingController();
    final id = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customer baru'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Labeled('Nama *', TextField(controller: name, autofocus: true)),
              const SizedBox(height: S.md),
              Labeled('No. HP', TextField(controller: phone)),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              try {
                final id = await c.db.saveCustomer(
                  CustomersCompanion.insert(name: name.text, phone: Value(phone.text)),
                );
                if (ctx.mounted) Navigator.pop(ctx, id);
              } on ArgumentError catch (e) {
                if (ctx.mounted) toast(ctx, '${e.message}');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    if (id == null) return;
    final x = await (c.db.select(c.db.customers)..where((x) => x.id.equals(id))).getSingle();
    _pickCustomer(x);
  }

  Future<void> _save() async {
    if (rows.any((r) => r.item == null)) {
      return toast(context, 'Pilih barang/jasa dari daftar di setiap baris (atau hapus barisnya)');
    }
    if (payNow && accountId == null) return toast(context, 'Pilih rekening pembayaran');
    final amount = parseRupiah(payAmount.text.isEmpty && !isOrder ? rp(total) : payAmount.text);
    try {
      final id = await c.db.saveDoc(
        id: doc?.id,
        kind: widget.kind,
        at: date,
        dueAt: isOrder ? null : due,
        customerId: customer?.id,
        car: car.text,
        plate: plate.text,
        note: note.text,
        legacyNo: widget.legacy ? legacyNo.text : null,
        lines: [
          for (final r in rows)
            LineInput(
              productId: r.item!.product.id,
              name: r.name,
              description: r.description.text,
              qty: parseRupiah(r.qty.text),
              price: parseRupiah(r.price.text),
              discount: parseRupiah(r.discount.text),
              incentive: r.incentive,
              cost: r.cost,
              tech1Id: r.tech1,
              tech2Id: r.tech2,
            ),
        ],
        payNow: payNow && amount > 0 ? PaymentInput(accountId: accountId!, amount: amount, at: date) : null,
      );
      if (mounted) Navigator.pop(context, id);
    } on ArgumentError catch (e) {
      if (mounted) toast(context, '${e.message}');
    } catch (e) {
      if (mounted) toast(context, 'Gagal menyimpan: $e');
    }
  }

  Future<void> _pickDate(bool isDue) async {
    final initial = (isDue ? due : date) ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: [DateTime.now().add(const Duration(days: 365)), initial].reduce((a, b) => a.isAfter(b) ? a : b),
    );
    if (d != null) setState(() => isDue ? due = d : date = d);
  }

  @override
  Widget build(BuildContext context) {
    final label = isOrder ? 'Pemesanan' : 'Invoice';
    final title = isNew ? (widget.legacy ? 'Transaksi lama ($label)' : '$label baru') : 'Ubah ${doc!.no}';
    Widget date_(String l, DateTime? v, VoidCallback onTap) => SizedBox(
      width: 150,
      child: InkWell(
        onTap: onTap,
        child: Labeled(l, InputDecorator(decoration: const InputDecoration(), child: Text(v == null ? '—' : tgl(v)))),
      ),
    );

    return SizedBox(
      width: 1180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(S.xl, S.lg, S.xl, S.lg),
            child: Row(
              children: [
                Text(title, style: T.pageTitle.copyWith(fontSize: 20)),
                const Spacer(),
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                const SizedBox(width: S.sm),
                FilledButton(onPressed: _save, child: Text(isNew ? 'Simpan $label' : 'Simpan perubahan')),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(S.xl),
              children: [
                if (widget.legacy)
                  Padding(
                    padding: const EdgeInsets.only(bottom: S.lg),
                    child: Text(
                      'Untuk mencatat transaksi yang sudah terjadi (mis. Agustus–Oktober). Nomor diketik sesuai nota '
                      'aslinya dan stok TIDAK berubah, karena stok saat ini sudah memperhitungkan penjualan tersebut.',
                      style: T.pageSubtitle,
                    ),
                  ),
                Wrap(
                  spacing: S.md,
                  runSpacing: S.md,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    if (widget.legacy)
                      SizedBox(
                        width: 150,
                        child: Labeled(
                          'Nomor *',
                          TextField(
                            controller: legacyNo,
                            decoration: InputDecoration(hintText: isOrder ? 'SO/00010' : 'INV/00240'),
                          ),
                        ),
                      ),
                    date_('Tanggal', date, () => _pickDate(false)),
                    if (!isOrder) date_('Jatuh tempo', due, () => _pickDate(true)),
                    SizedBox(width: 280, child: _customerField()),
                    TextButton.icon(
                      onPressed: _newCustomer,
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text('Customer baru'),
                    ),
                    SizedBox(width: 200, child: Labeled('Mobil', TextField(controller: car))),
                    SizedBox(
                      width: 120,
                      child: Labeled(
                        'Plat',
                        TextField(controller: plate, textCapitalization: TextCapitalization.characters),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: S.xl),
                _linesHeader(),
                for (final (i, r) in rows.indexed) _lineRow(i, r),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => rows.add(_Row())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah baris'),
                  ),
                ),
                const SizedBox(height: S.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Labeled('Catatan', TextField(controller: note, maxLines: 3))),
                    const SizedBox(width: S.xxl),
                    SizedBox(width: 380, child: _totals()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerField() => Autocomplete<Customer>(
    initialValue: TextEditingValue(text: customer?.name ?? ''),
    displayStringForOption: (x) => x.name,
    optionsBuilder: (v) {
      final q = v.text.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
      if (q.isEmpty) return const [];
      return c.customers
          .where((x) => '${x.name}${x.phone ?? ''}${x.plate}'.toLowerCase().replaceAll(' ', '').contains(q))
          .take(20);
    },
    optionsViewBuilder: (ctx, onSelected, options) => _Options(
      options: options.toList(),
      onSelected: onSelected,
      title: (x) => x.name,
      subtitle: (x) =>
          [if (x.phone != null) displayPhone(x.phone!), x.car, x.plate].where((s) => s.isNotEmpty).join(' · '),
    ),
    onSelected: _pickCustomer,
    fieldViewBuilder: (_, ctrl, focus, _) => Labeled(
      'Customer',
      TextField(
        controller: ctrl,
        focusNode: focus,
        onChanged: (v) {
          if (customer != null && v != customer!.name) setState(() => customer = null);
        },
        decoration: const InputDecoration(hintText: 'Cari nama / HP / plat · kosong = UMUM'),
      ),
    ),
  );

  static const _flex = [5, 3, 1, 2, 2, 3, 2];

  /// Kolom baris & header selalu sama lebar; [trailing] = slot 40 px (tombol hapus).
  Widget _cells(List<Widget> children, {Widget trailing = const SizedBox()}) => Row(
    children: [
      for (var i = 0; i < children.length; i++) ...[
        Expanded(flex: _flex[i], child: children[i]),
        const SizedBox(width: S.sm),
      ],
      SizedBox(width: 40, child: trailing),
    ],
  );

  Widget _linesHeader() => Container(
    color: C.bg,
    padding: const EdgeInsets.symmetric(horizontal: S.sm, vertical: S.sm),
    child: _cells([
      for (final h in ['Produk / jasa', 'Deskripsi', 'Qty', 'Harga', 'Diskon (Rp)', 'Teknisi', 'Jumlah'])
        Text(h, style: T.label),
    ]),
  );

  Widget _lineRow(int i, _Row r) {
    final active = c.products.where((s) => s.product.active).toList();
    return Padding(
      key: ObjectKey(r),
      padding: const EdgeInsets.symmetric(horizontal: S.sm, vertical: S.xs),
      child: _cells(
        [
          Autocomplete<StockedProduct>(
            initialValue: TextEditingValue(text: r.name),
            displayStringForOption: (s) => s.product.name,
            optionsBuilder: (v) {
              final q = v.text.toLowerCase();
              return active.where((s) => '${s.product.name} ${s.product.sku ?? ''}'.toLowerCase().contains(q)).take(30);
            },
            optionsViewBuilder: (ctx, onSelected, options) => _Options(
              options: options.toList(),
              onSelected: onSelected,
              title: (s) => s.product.name,
              subtitle: (s) => '${rupiah(s.product.sellPrice)} · ${s.isService ? 'Jasa' : 'Stok ${s.stock}'}',
            ),
            onSelected: (s) => setState(() {
              if (r.item?.product.id != s.product.id) r.cost = null;
              r.item = s;
              r.name = s.product.name;
              r.incentive = s.product.incentive;
              r.price.text = rp(s.product.sellPrice);
            }),
            fieldViewBuilder: (_, ctrl, focus, _) => TextField(
              controller: ctrl,
              focusNode: focus,
              onChanged: (v) {
                if (r.item != null && v != r.item!.product.name) setState(() => r.item = null);
              },
              decoration: InputDecoration(
                hintText: 'Cari produk…',
                errorText: ctrl.text.isNotEmpty && r.item == null ? 'Pilih dari daftar' : null,
              ),
            ),
          ),
          TextField(
            controller: r.description,
            decoration: const InputDecoration(hintText: 'opsional'),
          ),
          MoneyField(controller: r.qty, label: '', prefix: '', onChanged: (_) => setState(() {})),
          MoneyField(controller: r.price, label: '', prefix: '', onChanged: (_) => setState(() {})),
          MoneyField(controller: r.discount, label: '', prefix: '', onChanged: (_) => setState(() {})),
          _TechPicker(
            c: c,
            tech1: r.tech1,
            tech2: r.tech2,
            onChanged: (a, b) => setState(() {
              r.tech1 = a;
              r.tech2 = b;
            }),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rp(r.item == null ? 0 : r.total), textAlign: TextAlign.right, style: T.money),
              if (_short(r) != null) Text(_short(r)!, style: T.label.copyWith(color: C.danger)),
            ],
          ),
        ],
        trailing: IconButton(
          tooltip: 'Hapus baris',
          onPressed: rows.length == 1 ? null : () => setState(() => rows.removeAt(i).dispose()),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  /// Peringatan stok kurang (tetap boleh disimpan: stok bisa minus, lihat repo).
  String? _short(_Row r) {
    final it = r.item;
    if (it == null || it.isService || widget.legacy || isOrder) return null;
    final already = widget.lines.where((l) => l.productId == it.product.id).fold(0, (t, l) => t + l.qty);
    final need = rows.where((x) => x.item?.product.id == it.product.id).fold(0, (t, x) => t + parseRupiah(x.qty.text));
    final available = it.stock + already; // saat mengubah, stok dari invoice ini dihitung tersedia
    return need > available ? 'stok tersedia $available' : null;
  }

  Widget _totals() {
    final paid = widget.existing?.paid ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Total', style: T.section),
            const Spacer(),
            Text(rupiah(total), style: T.kpi.copyWith(fontSize: 24)),
          ],
        ),
        Text(terbilang(total), textAlign: TextAlign.right, style: T.label),
        if (paid > 0) ...[
          const SizedBox(height: S.sm),
          Row(
            children: [
              const Text('Sudah dibayar'),
              const Spacer(),
              Text(rupiah(paid), style: T.money),
            ],
          ),
        ],
        if (isNew) ...[
          const SizedBox(height: S.lg),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: payNow,
            onChanged: (v) => setState(() => payNow = v!),
            title: Text(isOrder ? 'Terima uang muka (DP) sekarang' : 'Terima pembayaran sekarang'),
          ),
          if (payNow)
            Row(
              children: [
                Expanded(
                  child: MoneyField(
                    controller: payAmount,
                    label: isOrder ? 'Nominal DP' : 'Nominal',
                    hint: isOrder ? null : 'kosong = lunas',
                  ),
                ),
                const SizedBox(width: S.sm),
                SizedBox(
                  width: 140,
                  child: Labeled(
                    'Ke rekening',
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: accountId,
                      items: [for (final a in c.accounts) DropdownMenuItem(value: a.id, child: Text(a.name))],
                      onChanged: (v) => setState(() => accountId = v),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

/// Daftar pilihan Autocomplete dengan judul + keterangan.
class _Options<O extends Object> extends StatelessWidget {
  const _Options({required this.options, required this.onSelected, required this.title, required this.subtitle});
  final List<O> options;
  final AutocompleteOnSelected<O> onSelected;
  final String Function(O) title, subtitle;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(S.rInput),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320, maxWidth: 420),
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [
            for (final o in options)
              ListTile(
                dense: true,
                title: Text(title(o)),
                subtitle: Text(subtitle(o), style: T.label),
                onTap: () => onSelected(o),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Pilih 0–2 teknisi untuk satu baris.
class _TechPicker extends StatelessWidget {
  const _TechPicker({required this.c, required this.tech1, required this.tech2, required this.onChanged});
  final PenjualanController c;
  final int? tech1, tech2;
  final void Function(int?, int?) onChanged;

  @override
  Widget build(BuildContext context) {
    final names = [tech1, tech2].whereType<int>().map(c.employeeName).where((n) => n.isNotEmpty).join(', ');
    return OutlinedButton(
      // Tampil seperti field (latar abu, tanpa garis) agar sejajar dengan input lain di baris.
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: S.md),
        backgroundColor: C.field,
        side: BorderSide.none,
        minimumSize: const Size(0, 44),
      ),
      onPressed: () async {
        if (c.technicians.isEmpty) return toast(context, 'Belum ada teknisi — tambahkan di menu Gaji');
        final picked = {?tech1, ?tech2};
        final result = await showDialog<Set<int>>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: const Text('Teknisi (maks. 2)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in [...c.technicians, ...c.employees.where((x) => !x.active && picked.contains(x.id))])
                    CheckboxListTile(
                      value: picked.contains(e.id),
                      title: Text(c.employeeName(e.id)),
                      onChanged: (v) => setState(() {
                        if (v == true && picked.length < 2) picked.add(e.id);
                        if (v == false) picked.remove(e.id);
                      }),
                    ),
                  Text('Insentif dibagi dua bila dikerjakan berdua.', style: T.label),
                ],
              ),
              actions: [FilledButton(onPressed: () => Navigator.pop(ctx, picked), child: const Text('Selesai'))],
            ),
          ),
        );
        if (result == null) return;
        final ids = result.toList();
        onChanged(ids.firstOrNull, ids.length > 1 ? ids[1] : null);
      },
      child: Text(names.isEmpty ? '—' : names, overflow: TextOverflow.ellipsis),
    );
  }
}
