import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../core/proof.dart';
import '../../db/database.dart';
import 'gudang_controller.dart';
import 'gudang_repo.dart';

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
  StockedProduct? item;
  final qty = TextEditingController(text: '1');
  final cost = TextEditingController();
  int get total => parseRupiah(qty.text) * parseRupiah(cost.text);
}

/// Pembelian stok (owner): tanggal, supplier, rekening, baris barang.
Future<bool?> showPurchaseDialog(BuildContext context, GudangController c) async {
  final accounts = await (c.db.select(c.db.accounts)..where((a) => a.active.equals(true))).get();
  if (!context.mounted) return null;
  if (accounts.isEmpty) {
    warn(context, 'Belum ada rekening aktif');
    return null;
  }
  return showDialog<bool>(context: context, builder: (_) => _PurchaseDialog(c, accounts));
}

class _PurchaseDialog extends StatefulWidget {
  const _PurchaseDialog(this.c, this.accounts);
  final GudangController c;
  final List<Account> accounts;
  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<_PurchaseDialog> {
  DateTime date = DateTime.now();
  late int accountId = widget.accounts.first.id;
  final supplier = TextEditingController();
  final note = TextEditingController();
  final billNo = TextEditingController();
  var proof = '';
  var paidNow = true;
  final lines = [_Line()];

  List<StockedProduct> get barang => widget.c.products.where((s) => !s.isService && s.product.active).toList();

  @override
  void dispose() {
    for (final t in [
      supplier,
      note,
      billNo,
      for (final l in lines) ...[l.qty, l.cost],
    ]) {
      t.dispose();
    }
    super.dispose();
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
                  Expanded(child: Labeled('Supplier', TextField(controller: supplier))),
                  const SizedBox(width: S.md),
                  SizedBox(width: 170, child: Labeled('No. nota', TextField(controller: billNo))),
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
                        onPressed: lines.length == 1
                            ? null
                            : () => setState(() {
                                final removed = lines.removeAt(i);
                                removed.qty.dispose();
                                removed.cost.dispose();
                              }),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => lines.add(_Line())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah barang'),
                ),
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
