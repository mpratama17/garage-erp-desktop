import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../core/proof.dart';
import '../../db/database.dart';
import 'gudang_controller.dart';
import 'gudang_repo.dart';
import 'product_form.dart';

Future<void> showImportErrors(BuildContext context, String summary, List<String> errors) => showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text('Import selesai: $summary'),
    content: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${errors.length} baris dilewati — perbaiki di file lalu import ulang:', style: T.label),
          const SizedBox(height: S.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(child: SelectableText(errors.join('\n'))),
          ),
        ],
      ),
    ),
    actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
  ),
);

/// Stok opname: isi stok sebenarnya + alasan.
Future<bool?> showAdjustDialog(BuildContext context, AppDb db, StockedProduct item) async {
  final actual = TextEditingController(text: '${item.stock}');
  final note = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Stok opname — ${item.product.name}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stok tercatat: ${item.stock}', style: T.body),
            const SizedBox(height: S.md),
            Labeled(
              'Stok sebenarnya *',
              TextField(controller: actual, autofocus: true, keyboardType: TextInputType.number),
            ),
            const SizedBox(height: S.md),
            Labeled('Alasan *', TextField(controller: note)),
          ],
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(
          onPressed: () async {
            final n = int.tryParse(actual.text.trim());
            if (n == null) return warn(ctx, 'Stok sebenarnya harus angka');
            await runAction(ctx, () async {
              await db.adjustStock(item.product.id, n, note.text);
              if (ctx.mounted) Navigator.pop(ctx, true);
            });
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  return ok;
}

class _Line {
  _Line([this.item]) : cost = TextEditingController(text: item == null ? '' : rp(item.product.buyPrice));
  StockedProduct? item;
  final qty = TextEditingController(text: '1');
  final TextEditingController cost;
  int get total => parseRupiah(qty.text) * parseRupiah(cost.text);

  void dispose() {
    qty.dispose();
    cost.dispose();
  }
}

/// Pembelian stok (owner): tanggal, supplier, rekening, baris barang.
Future<bool?> showPurchaseDialog(BuildContext context, GudangController c) async {
  final accounts = await (c.db.select(c.db.accounts)..where((a) => a.active.equals(true))).get();
  if (!context.mounted) return null;
  if (accounts.isEmpty) {
    warn(context, 'Belum ada rekening aktif');
    return null;
  }
  final vendors = [for (final v in await c.db.select(c.db.vendors).get()) v.name]..sort();
  if (!context.mounted) return null;
  return showDialog<bool>(context: context, builder: (_) => _PurchaseDialog(c, accounts, vendors));
}

class _PurchaseDialog extends StatefulWidget {
  const _PurchaseDialog(this.c, this.accounts, this.vendors);
  final GudangController c;
  final List<Account> accounts;
  final List<String> vendors; // nama vendor di Kontak ▸ Vendor (untuk dicari); nama baru otomatis jadi vendor
  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<_PurchaseDialog> {
  DateTime date = DateTime.now();
  late int accountId = widget.accounts.first.id;
  final supplier = TextEditingController();
  final supplierFocus = FocusNode();
  final note = TextEditingController();
  final billNo = TextEditingController();
  var proof = '';
  var paidNow = true;
  final lines = [_Line()];

  List<StockedProduct> get barang => widget.c.products.where((s) => !s.isService && s.product.active).toList();

  @override
  void dispose() {
    supplierFocus.dispose();
    for (final t in [supplier, note, billNo]) {
      t.dispose();
    }
    for (final l in lines) {
      l.dispose();
    }
    super.dispose();
  }

  /// Barang baru dari form pembelian (R4 #5): form Gudang tanpa stok awal — stoknya masuk lewat baris ini.
  Future<void> _newProduct() async {
    final p = await showProductDialog(context, widget.c.db, [
      for (final s in widget.c.products) s.product,
    ], barangOnly: true);
    if (p == null || !mounted) return;
    setState(() {
      // Baris terakhir yang belum terisi diganti baris berisi barang baru.
      if (lines.last.item == null) lines.removeLast().dispose();
      lines.add(_Line(StockedProduct(p, 0)));
    });
  }

  Future<void> _save() async {
    final valid = lines.where((l) => l.item != null).toList();
    if (valid.length != lines.length) {
      return warn(context, 'Pilih barang dari daftar di setiap baris (atau hapus barisnya)');
    }
    await runAction(context, () async {
      await widget.c.db.recordPurchase(
        at: date,
        accountId: accountId,
        supplier: supplier.text,
        note: note.text,
        billNo: billNo.text,
        proofPath: proof,
        paidNow: paidNow,
        lines: [
          for (final l in valid)
            PurchaseLine(
              productId: l.item!.product.id,
              qty: parseRupiah(l.qty.text),
              unitCost: parseRupiah(l.cost.text),
            ),
        ],
      );
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = lines.fold(0, (s, l) => s + (l.item == null ? 0 : l.total));
    return AlertDialog(
      title: const Text('Pembelian stok'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 170,
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => date = d);
                      },
                      child: Labeled(
                        'Tanggal',
                        InputDecorator(decoration: const InputDecoration(), child: Text(tgl(date))),
                      ),
                    ),
                  ),
                  const SizedBox(width: S.md),
                  Expanded(
                    child: Labeled(
                      'Vendor',
                      RawAutocomplete<String>(
                        textEditingController: supplier,
                        focusNode: supplierFocus,
                        optionsBuilder: (v) => widget.vendors.where(
                          (n) => n.toLowerCase().contains(v.text.trim().toLowerCase()) && n != v.text,
                        ),
                        fieldViewBuilder: (_, ctrl, focus, _) => TextField(
                          controller: ctrl,
                          focusNode: focus,
                          decoration: const InputDecoration(hintText: 'Cari atau ketik vendor baru'),
                        ),
                        optionsViewBuilder: (_, onSelected, options) => Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(S.rInput),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 280),
                              child: ListView(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                children: [
                                  for (final o in options)
                                    ListTile(dense: true, title: Text(o), onTap: () => onSelected(o)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: S.md),
                  SizedBox(width: 170, child: Labeled('No. nota supplier', TextField(controller: billNo))),
                  const SizedBox(width: S.md),
                  SizedBox(
                    width: 170,
                    child: Labeled(
                      'Dibayar dari',
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: accountId,
                        items: [for (final a in widget.accounts) DropdownMenuItem(value: a.id, child: Text(a.name))],
                        onChanged: (v) => setState(() => accountId = v!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: S.lg),
              for (final (i, l) in lines.indexed)
                Padding(
                  key: ObjectKey(l), // baris tetap terikat ke datanya walau baris lain dihapus
                  padding: const EdgeInsets.only(bottom: S.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Autocomplete<StockedProduct>(
                          initialValue: TextEditingValue(text: l.item?.product.name ?? ''),
                          displayStringForOption: (s) => s.product.name,
                          optionsBuilder: (v) => barang.where(
                            (s) =>
                                '${s.product.name} ${s.product.sku ?? ''}'.toLowerCase().contains(v.text.toLowerCase()),
                          ),
                          onSelected: (s) => setState(() {
                            l.item = s;
                            l.cost.text = rp(s.product.buyPrice);
                          }),
                          fieldViewBuilder: (_, ctrl, focus, _) => Labeled(
                            'Barang',
                            TextField(
                              controller: ctrl,
                              focusNode: focus,
                              // Teks diubah tanpa memilih dari daftar = barang belum dipilih.
                              onChanged: (v) {
                                if (l.item != null && v != l.item!.product.name) setState(() => l.item = null);
                              },
                              decoration: InputDecoration(
                                errorText: ctrl.text.isNotEmpty && l.item == null ? 'Pilih dari daftar' : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: S.sm),
                      SizedBox(
                        width: 80,
                        child: MoneyField(
                          controller: l.qty,
                          label: 'Qty',
                          prefix: '',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: S.sm),
                      SizedBox(
                        width: 160,
                        child: MoneyField(controller: l.cost, label: 'Harga beli', onChanged: (_) => setState(() {})),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(rp(l.total), textAlign: TextAlign.right, style: T.money),
                      ),
                      IconButton(
                        tooltip: 'Hapus baris',
                        onPressed: lines.length == 1 ? null : () => setState(() => lines.removeAt(i).dispose()),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              Wrap(
                spacing: S.sm,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => lines.add(_Line())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah barang'),
                  ),
                  TextButton.icon(
                    onPressed: _newProduct,
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: const Text('Barang baru'),
                  ),
                ],
              ),
              const SizedBox(height: S.sm),
              Labeled('Keterangan', TextField(controller: note)),
              const SizedBox(height: S.sm),
              proofRow(proof, () async {
                final p = await pickProof(billNo.text.isEmpty ? 'pembelian' : billNo.text);
                if (p != null) setState(() => proof = p);
              }),
              const SizedBox(height: S.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: paidNow,
                onChanged: (v) => setState(() => paidNow = v!),
                title: const Text('Sudah dibayar sekarang'),
                subtitle: const Text('Matikan bila dibayar belakangan (beberapa hari lagi), bisa dilunasi nanti.'),
              ),
              const SizedBox(height: S.lg),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Total ${rupiah(total)}', style: T.section),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _save, child: Text(paidNow ? 'Simpan pembelian' : 'Simpan (belum dibayar)')),
      ],
    );
  }
}
