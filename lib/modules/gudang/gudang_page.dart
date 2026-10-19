import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../core/format.dart';
import '../../core/owner.dart';
import '../../core/table.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../db/database.dart';
import 'gudang_controller.dart';
import 'gudang_dialogs.dart';
import 'gudang_repo.dart';

class GudangPage extends StatelessWidget {
  const GudangPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(GudangController(Get.find<AppDb>()));
    final owner = Get.find<OwnerController>();

    Future<void> ownerAction(Future<String?> Function() run) async {
      if (!await owner.ensure(context)) return;
      final msg = await run();
      if (msg != null && context.mounted) toast(context, msg);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Gudang',
          subtitle: 'Barang, jasa, dan stok.',
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
                if (r.errors.isNotEmpty && context.mounted) await showImportErrors(context, r.summary, r.errors);
                return r.summary;
              }),
              child: const Text('Import'),
            ),
            OutlinedButton(onPressed: () => ownerAction(c.export), child: const Text('Export')),
            OutlinedButton(
              onPressed: () => ownerAction(() async {
                final ok = await showPurchaseDialog(context, c);
                return ok == true ? 'Pembelian tersimpan, stok bertambah' : null;
              }),
              child: const Text('Pembelian stok'),
            ),
            FilledButton.icon(
              onPressed: () => c.panelId.value = 0,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Produk'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: S.xxl),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 480,
              child: Obx(
                () => SegmentedButton<GudangTab>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: GudangTab.barang, label: Text('Barang')),
                    ButtonSegment(value: GudangTab.jasa, label: Text('Jasa')),
                    ButtonSegment(value: GudangTab.ready, label: Text('Ready Stock')),
                  ],
                  selected: {c.tab.value},
                  onSelectionChanged: (s) {
                    c.tab.value = s.first;
                    c.panelId.value = null;
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: S.lg),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.xxl, 0, S.xxl, S.xl),
            child: Obx(() {
              final isJasa = c.tab.value == GudangTab.jasa;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AppTable<StockedProduct>(
                      rows: c.visible,
                      searchHint: 'Cari nama, SKU, kategori…',
                      searchText: (s) => '${s.product.name} ${s.product.sku ?? ''} ${s.product.category}',
                      selected: (s) => s.product.id == c.panelId.value,
                      onTap: (s) => c.panelId.value = s.product.id,
                      emptyMessage: isJasa
                          ? 'Belum ada jasa.'
                          : 'Belum ada barang. Tambah produk atau Import dari Excel.',
                      columns: [
                        Col(
                          'Kode',
                          (s) => Text(s.product.sku ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                          flex: 2,
                        ),
                        Col('Nama', (s) => _Name(s), flex: 5),
                        Col('Kategori', (s) => Text(s.product.category), flex: 3),
                        Col(
                          'Harga beli',
                          (s) => OwnerOnly(child: Text(rp(s.product.buyPrice), style: T.money)),
                          flex: 2,
                          numeric: true,
                        ),
                        Col('Harga jual', (s) => Text(rp(s.product.sellPrice), style: T.money), flex: 2, numeric: true),
                        if (isJasa)
                          Col('Insentif', (s) => Text(rp(s.product.incentive), style: T.money), flex: 2, numeric: true)
                        else
                          Col('Stok', (s) => StockPill(s), flex: 2, numeric: true),
                      ],
                    ),
                  ),
                  if (c.panelId.value != null) ...[
                    const SizedBox(width: S.lg),
                    SizedBox(
                      width: 420,
                      child: ProductPanel(
                        // Kunci ikut "sudah dimuat": setelah produk baru disimpan, panel dibuat ulang
                        // begitu datanya muncul dari stream (bukan tetap sebagai form kosong).
                        key: ValueKey((c.panelId.value, c.opened?.product)),
                        controller: c,
                        item: c.opened,
                        newIsService: isJasa,
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _Name extends StatelessWidget {
  const _Name(this.s);
  final StockedProduct s;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(child: Text(s.product.name, overflow: TextOverflow.ellipsis)),
      if (!s.product.active) ...[const SizedBox(width: S.sm), const Pill('Nonaktif', Tone.neutral)],
    ],
  );
}

class StockPill extends StatelessWidget {
  const StockPill(this.s, {super.key});
  final StockedProduct s;
  @override
  Widget build(BuildContext context) {
    final tone = s.stock <= 0 ? Tone.danger : (s.isLow ? Tone.warning : Tone.success);
    final label = s.stock <= 0
        ? (s.stock == 0 ? 'Habis' : '${s.stock} (minus)')
        : '${s.stock} ${s.product.unit.toLowerCase()}';
    return Pill(label, tone);
  }
}

/// Panel kanan: form produk + riwayat stok.
class ProductPanel extends StatefulWidget {
  const ProductPanel({super.key, required this.controller, required this.item, required this.newIsService});
  final GudangController controller;
  final StockedProduct? item;
  final bool newIsService;
  @override
  State<ProductPanel> createState() => _ProductPanelState();
}

class _ProductPanelState extends State<ProductPanel> {
  late final Product? p = widget.item?.product;
  late bool isService = p?.isService ?? widget.newIsService;
  late bool active = p?.active ?? true;
  late final name = TextEditingController(text: p?.name);
  late final sku = TextEditingController(text: p?.sku);
  late final category = TextEditingController(text: p?.category);
  late final unit = TextEditingController(text: p?.unit ?? 'PCS');
  late final sell = TextEditingController(text: p == null ? '' : rp(p!.sellPrice));
  late final buy = TextEditingController(text: p == null ? '' : rp(p!.buyPrice));
  late final minStock = TextEditingController(text: '${p?.minStock ?? 0}');
  late final incentive = TextEditingController(text: p == null ? '' : rp(p!.incentive));
  late final opening = TextEditingController(text: '0');

  @override
  void dispose() {
    for (final t in [name, sku, category, unit, sell, buy, minStock, incentive, opening]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final owner = Get.find<OwnerController>().isOwner.value;
    final data = ProductsCompanion(
      id: p == null ? const Value.absent() : Value(p!.id),
      name: Value(name.text),
      sku: Value(sku.text),
      category: Value(category.text.trim()),
      unit: Value(unit.text.trim().isEmpty ? 'PCS' : unit.text.trim().toUpperCase()),
      isService: Value(isService),
      sellPrice: Value(parseRupiah(sell.text)),
      // Harga beli hanya ditulis bila owner yang menyimpan (admin tidak melihat nilainya).
      buyPrice: owner ? Value(parseRupiah(buy.text)) : const Value.absent(),
      minStock: Value(isService ? 0 : parseRupiah(minStock.text)),
      incentive: Value(parseRupiah(incentive.text)),
      active: Value(active),
    );
    try {
      final id = await widget.controller.db.saveProduct(data, openingStock: parseRupiah(opening.text));
      widget.controller.panelId.value = id;
      if (mounted) toast(context, 'Produk tersimpan');
    } on ArgumentError catch (e) {
      if (mounted) toast(context, '${e.message}');
    } catch (e) {
      if (mounted) toast(context, 'Gagal menyimpan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = Get.find<OwnerController>();
    final isNew = p == null;
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
                  child: Text(isNew ? 'Produk baru' : p!.name, style: T.section, overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => widget.controller.panelId.value = null,
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
                // Tipe hanya bisa dipilih saat membuat produk (stok & riwayat bergantung padanya).
                if (isNew)
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('Barang')),
                      ButtonSegment(value: true, label: Text('Jasa')),
                    ],
                    selected: {isService},
                    onSelectionChanged: (s) => setState(() => isService = s.first),
                  )
                else
                  Align(alignment: Alignment.centerLeft, child: Pill(isService ? 'Jasa' : 'Barang', Tone.neutral)),
                gap(),
                Labeled('Nama *', TextField(controller: name)),
                gap(),
                Row(
                  children: [
                    Expanded(child: Labeled('Kode / SKU', TextField(controller: sku))),
                    const SizedBox(width: S.md),
                    SizedBox(width: 100, child: Labeled('Satuan', TextField(controller: unit))),
                  ],
                ),
                gap(),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: category.text),
                  optionsBuilder: (v) =>
                      widget.controller.categories.where((c) => c.toLowerCase().contains(v.text.toLowerCase())),
                  onSelected: (v) => category.text = v,
                  fieldViewBuilder: (_, ctrl, focus, _) => Labeled(
                    'Kategori',
                    TextField(controller: ctrl, focusNode: focus, onChanged: (v) => category.text = v),
                  ),
                ),
                gap(),
                Row(
                  children: [
                    Expanded(
                      child: MoneyField(controller: sell, label: 'Harga jual *'),
                    ),
                    const SizedBox(width: S.md),
                    Expanded(
                      child: Obx(
                        () => owner.isOwner.value
                            ? MoneyField(controller: buy, label: 'Harga beli (owner)')
                            : const Labeled(
                                'Harga beli (owner)',
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
                      child: MoneyField(controller: incentive, label: 'Tarif insentif teknisi'),
                    ),
                    if (!isService) ...[
                      const SizedBox(width: S.md),
                      Expanded(
                        child: MoneyField(controller: minStock, label: 'Stok minimal', prefix: ''),
                      ),
                    ],
                  ],
                ),
                if (isNew && !isService) ...[gap(), MoneyField(controller: opening, label: 'Stok awal', prefix: '')],
                if (!isNew) ...[
                  gap(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktif'),
                    subtitle: const Text('Produk nonaktif tidak muncul saat membuat invoice.'),
                    value: active,
                    onChanged: (v) => setState(() => active = v),
                  ),
                ],
                gap(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => widget.controller.panelId.value = null, child: const Text('Batal')),
                    const SizedBox(width: S.sm),
                    FilledButton(onPressed: _save, child: const Text('Simpan')),
                  ],
                ),
                if (!isNew && !isService) ...[
                  const SizedBox(height: S.xl),
                  _StockHistory(controller: widget.controller, item: widget.item!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockHistory extends StatelessWidget {
  const _StockHistory({required this.controller, required this.item});
  final GudangController controller;
  final StockedProduct item;

  static const _kind = {
    'opening': 'Stok awal',
    'purchase': 'Pembelian',
    'sale': 'Penjualan',
    'void': 'Invoice batal',
    'adjust': 'Penyesuaian',
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Text('Riwayat stok', style: T.section),
          const Spacer(),
          Text('Stok sekarang: ', style: T.label),
          StockPill(item),
        ],
      ),
      const SizedBox(height: S.sm),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          onPressed: () async {
            if (!await Get.find<OwnerController>().ensure(context)) return;
            if (context.mounted && await showAdjustDialog(context, controller.db, item) == true && context.mounted) {
              toast(context, 'Stok disesuaikan');
            }
          },
          child: const Text('Stok opname'),
        ),
      ),
      const SizedBox(height: S.sm),
      StreamBuilder<List<StockMove>>(
        stream: controller.db.watchMoves(item.product.id),
        builder: (_, snap) => Column(
          children: [
            for (final m in snap.data ?? const <StockMove>[])
              Container(
                padding: const EdgeInsets.symmetric(vertical: S.sm),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: C.border)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 88, child: Text(tgl(m.at), style: T.label)),
                    Expanded(
                      child: Text(
                        [_kind[m.kind] ?? m.kind, if (m.note.isNotEmpty) m.note].join(' · '),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      m.qty > 0 ? '+${m.qty}' : '${m.qty}',
                      style: T.money.copyWith(
                        color: m.qty > 0 ? Tone.success.fg : C.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
