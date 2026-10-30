import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import 'gudang_repo.dart';

/// Isi form produk, dipakai bersama panel Gudang dan "Barang/jasa baru" di Penjualan & Pembelian (R4 #1, #5).
class ProductFields {
  ProductFields(this.p, {bool isService = false}) : isService = p?.isService ?? isService, active = p?.active ?? true;
  final Product? p;
  bool isService, active;
  late final name = TextEditingController(text: p?.name);
  late final sku = TextEditingController(text: p?.sku);
  late final category = TextEditingController(text: p?.category);
  late final unit = TextEditingController(text: p?.unit ?? 'PCS');
  late final sell = TextEditingController(text: p == null ? '' : rp(p!.sellPrice));
  late final buy = TextEditingController(text: p == null ? '' : rp(p!.buyPrice));
  late final minStock = TextEditingController(text: '${p?.minStock ?? 0}');
  late final incentive = TextEditingController(text: p == null ? '' : rp(p!.incentive));
  late final opening = TextEditingController(text: '0');

  /// SKU produk baru diisi otomatis (R4 #2) sampai diketik/dipilih sendiri.
  late bool skuAuto = p == null;

  ProductsCompanion toCompanion() => ProductsCompanion(
    id: p == null ? const Value.absent() : Value(p!.id),
    name: Value(name.text),
    sku: Value(sku.text),
    category: Value(category.text.trim()),
    unit: Value(unit.text.trim().isEmpty ? 'PCS' : unit.text.trim().toUpperCase()),
    isService: Value(isService),
    sellPrice: Value(parseRupiah(sell.text)),
    buyPrice: Value(parseRupiah(buy.text)),
    minStock: Value(isService ? 0 : parseRupiah(minStock.text)),
    incentive: Value(parseRupiah(incentive.text)),
    active: Value(active),
  );

  void dispose() {
    for (final t in [name, sku, category, unit, sell, buy, minStock, incentive, opening]) {
      t.dispose();
    }
  }
}

class ProductFormFields extends StatefulWidget {
  const ProductFormFields({
    super.key,
    required this.f,
    required this.products,
    this.barangOnly = false,
    this.minOpening = 0,
  });
  final ProductFields f;
  final List<Product> products; // semua produk: sumber kategori & SKU otomatis
  final bool barangOnly; // Pembelian: hanya barang, tanpa stok awal
  final int minOpening;
  @override
  State<ProductFormFields> createState() => _ProductFormFieldsState();
}

class _ProductFormFieldsState extends State<ProductFormFields> {
  ProductFields get f => widget.f;
  late final skus = [for (final p in widget.products) p.sku];
  late final prefixes = skuPrefixes(skus);
  late final categories = widget.products.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList()..sort();

  void _guessSku(String name) {
    if (!f.skuAuto) return;
    final prefix = name.trim().isEmpty
        ? null
        : guessSkuPrefix(name, [for (final p in widget.products) (p.name, p.sku)]);
    f.sku.text = prefix == null ? '' : nextSku(prefix, skus); // controller sendiri memperbarui field
  }

  @override
  Widget build(BuildContext context) {
    final isNew = f.p == null;
    Widget gap() => const SizedBox(height: S.md);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tipe hanya bisa dipilih saat membuat produk (stok & riwayat bergantung padanya).
        if (isNew && !widget.barangOnly)
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Barang')),
              ButtonSegment(value: true, label: Text('Jasa')),
            ],
            selected: {f.isService},
            onSelectionChanged: (s) => setState(() => f.isService = s.first),
          )
        else
          Align(alignment: Alignment.centerLeft, child: Pill(f.isService ? 'Jasa' : 'Barang', Tone.neutral)),
        gap(),
        Labeled('Nama *', TextField(controller: f.name, autofocus: isNew, onChanged: _guessSku)),
        gap(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Labeled(
                'Kode / SKU',
                TextField(
                  controller: f.sku,
                  onChanged: (_) => f.skuAuto = false,
                  decoration: InputDecoration(
                    helperText: isNew ? 'Otomatis dari produk yang mirip' : null,
                    suffixIcon: prefixes.isEmpty
                        ? null
                        : PopupMenuButton<String>(
                            tooltip: 'Pilih prefix (nomor berikutnya otomatis)',
                            icon: const Icon(Icons.arrow_drop_down),
                            itemBuilder: (_) => [for (final p in prefixes) PopupMenuItem(value: p, child: Text(p))],
                            onSelected: (p) => setState(() {
                              f.skuAuto = false;
                              f.sku.text = nextSku(p, skus);
                            }),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: S.md),
            SizedBox(width: 100, child: Labeled('Satuan', TextField(controller: f.unit))),
          ],
        ),
        gap(),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: f.category.text),
          optionsBuilder: (v) => categories.where((c) => c.toLowerCase().contains(v.text.toLowerCase())),
          onSelected: (v) => f.category.text = v,
          fieldViewBuilder: (_, ctrl, focus, _) =>
              Labeled('Kategori', TextField(controller: ctrl, focusNode: focus, onChanged: (v) => f.category.text = v)),
        ),
        gap(),
        Row(
          children: [
            Expanded(
              child: MoneyField(controller: f.sell, label: 'Harga jual *'),
            ),
            const SizedBox(width: S.md),
            Expanded(
              child: Obx(
                () => Get.find<OwnerController>().isOwner.value
                    ? MoneyField(controller: f.buy, label: 'Harga beli')
                    : const Labeled(
                        'Harga beli',
                        InputDecorator(
                          decoration: InputDecoration(),
                          child: OwnerOnly(child: SizedBox()),
                        ),
                      ),
              ),
            ),
          ],
        ),
        gap(),
        Row(
          children: [
            Expanded(
              child: MoneyField(controller: f.incentive, label: 'Tarif insentif teknisi'),
            ),
            if (!f.isService) ...[
              const SizedBox(width: S.md),
              Expanded(
                child: MoneyField(controller: f.minStock, label: 'Stok minimal', prefix: ''),
              ),
            ],
          ],
        ),
        if (isNew && !f.isService && !widget.barangOnly) ...[
          gap(),
          MoneyField(
            controller: f.opening,
            label: widget.minOpening > 0 ? 'Stok awal (minimal ${widget.minOpening})' : 'Stok awal',
            prefix: '',
          ),
        ],
      ],
    );
  }
}

/// "Barang/jasa baru" dari form lain (minta PIN owner: saveProduct dikunci owner). Mengembalikan produk tersimpan.
/// [products] = semua produk yang sudah dipegang pemanggil. [minOpening]: Penjualan butuh stok ≥ 1 supaya barang
/// bisa masuk invoice. [barangOnly]: Pembelian — stok awal disembunyikan karena stok masuk lewat baris pembelian
/// itu sendiri (kalau diisi juga, stok terhitung dua kali).
Future<Product?> showProductDialog(
  BuildContext context,
  AppDb db,
  List<Product> products, {
  bool barangOnly = false,
  int minOpening = 0,
}) async {
  if (!await Get.find<OwnerController>().ensure(context) || !context.mounted) return null;
  final f = ProductFields(null)..opening.text = '$minOpening';
  // Controller teks tidak di-dispose manual: dialog masih beranimasi setelah ditutup (pola yang sama di app ini).
  return showDialog<Product>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(barangOnly ? 'Barang baru' : 'Barang / jasa baru'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: ProductFormFields(f: f, products: products, barangOnly: barangOnly, minOpening: minOpening),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(
          onPressed: () => runAction(ctx, () async {
            final opening = parseRupiah(f.opening.text); // barangOnly: field tersembunyi, tetap 0
            if (!f.isService && opening < minOpening) {
              throw ArgumentError('Stok awal minimal $minOpening supaya bisa masuk invoice');
            }
            final id = await db.saveProduct(f.toCompanion(), openingStock: opening);
            final p = await (db.select(db.products)..where((x) => x.id.equals(id))).getSingle();
            if (ctx.mounted) Navigator.pop(ctx, p);
          }),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}
