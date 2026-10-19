import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'core/format.dart';
import 'core/theme.dart';
import 'core/ui.dart';
import 'db/database.dart';
import 'modules/biaya/biaya_page.dart';
import 'modules/gaji/gaji_page.dart';
import 'modules/gudang/gudang_controller.dart';
import 'modules/gudang/gudang_page.dart';
import 'modules/kas/kas_page.dart';
import 'modules/kontak/kontak_controller.dart';
import 'modules/kontak/kontak_page.dart';
import 'modules/laporan/laporan_page.dart';
import 'modules/pengaturan/pengaturan_page.dart';
import 'modules/penjualan/penjualan_controller.dart';
import 'modules/penjualan/penjualan_page.dart';
import 'modules/search_repo.dart';

/// Halaman di sidebar (urutan = urutan menu). Pengaturan ditaruh terpisah di bawah.
enum AppPage {
  penjualan('Penjualan', Icons.receipt_long_outlined),
  gudang('Gudang', Icons.inventory_2_outlined),
  kontak('Kontak', Icons.people_outline),
  kas('Kas & Bank', Icons.account_balance_wallet_outlined),
  biaya('Biaya', Icons.payments_outlined),
  gaji('Gaji', Icons.badge_outlined),
  laporan('Laporan', Icons.bar_chart_outlined),
  pengaturan('Pengaturan', Icons.settings_outlined);

  const AppPage(this.label, this.icon);
  final String label;
  final IconData icon;

  Widget get page => switch (this) {
    penjualan => const PenjualanPage(),
    gudang => const GudangPage(),
    kontak => const KontakPage(),
    kas => const KasPage(),
    biaya => const BiayaPage(),
    gaji => const GajiPage(),
    laporan => const LaporanPage(),
    pengaturan => const PengaturanPage(),
  };
}

/// Halaman aktif; dipakai sidebar dan cari global (buka halaman + record).
class Nav extends GetxController {
  final page = AppPage.penjualan.obs;
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.put(Nav());
    return Scaffold(
      body: Row(
        children: [
          Obx(() => _Sidebar(selected: nav.page.value, onSelect: (p) => nav.page.value = p)),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: Obx(
                    () => IndexedStack(index: nav.page.value.index, children: [for (final p in AppPage.values) p.page]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _settings = () {
  final db = Get.find<AppDb>();
  return db
      .select(db.settings)
      .watch()
      .map((rows) => {...settingDefaults, for (final r in rows) r.key: r.value})
      .asBroadcastStream();
}();

// ------------------------------------------------------------------ sidebar

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});
  final AppPage selected;
  final ValueChanged<AppPage> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: S.sidebar,
      color: C.surface,
      padding: const EdgeInsets.all(S.md),
      child: StreamBuilder<Map<String, String>>(
        stream: _settings,
        builder: (context, snap) {
          final s = snap.data ?? settingDefaults;
          final icon = s['logo_icon_path']!;
          final lastBackup = DateTime.tryParse(s['last_backup_at']!);
          final backupOff = s['backup_schedule'] == 'off';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(S.sm, S.sm, S.sm, S.xl),
                child: Row(
                  children: [
                    icon.isNotEmpty && File(icon).existsSync()
                        ? Image.file(File(icon), width: 40, height: 40, fit: BoxFit.contain)
                        : Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.build_outlined, color: C.surface, size: 20),
                          ),
                    const SizedBox(width: S.md),
                    Expanded(
                      child: Text(s['shop_name']!, style: T.section, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              for (final p in AppPage.values)
                if (p != AppPage.pengaturan) _Item(p, selected == p, () => onSelect(p)),
              const Spacer(),
              _Item(AppPage.pengaturan, selected == AppPage.pengaturan, () => onSelect(AppPage.pengaturan)),
              Padding(
                padding: const EdgeInsets.all(S.sm),
                child: Text(
                  [
                    if (lastBackup == null)
                      'Belum ada backup'
                    else
                      'Backup ${tgl(lastBackup)} ${DateFormat.Hm().format(lastBackup)}',
                    if (backupOff) 'otomatis mati',
                  ].join(' · '),
                  style: T.label.copyWith(color: lastBackup == null || backupOff ? C.danger : C.inkMuted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.page, this.active, this.onTap);
  final AppPage page;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: S.xs),
    child: Material(
      color: active ? C.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        hoverColor: C.primarySoft,
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              const SizedBox(width: S.md),
              Icon(page.icon, size: 20, color: active ? C.surface : C.inkMuted),
              const SizedBox(width: S.md),
              Text(
                page.label,
                style: T.body.copyWith(
                  color: active ? C.surface : C.ink,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------------ topbar

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: S.xxl),
    decoration: const BoxDecoration(
      color: C.surface,
      border: Border(bottom: BorderSide(color: C.border)),
    ),
    child: Row(
      children: [
        const SizedBox(width: 420, child: _GlobalSearch()),
        const Spacer(),
        const Icon(Icons.calendar_today_outlined, size: 16, color: C.inkMuted),
        const SizedBox(width: S.sm),
        Text(DateFormat('EEEE, d MMMM y', 'id').format(DateTime.now()), style: T.label),
        const SizedBox(width: S.lg),
        const OwnerLockButton(),
      ],
    ),
  );
}

/// Cari invoice/pemesanan, customer, produk dari mana saja; pilih hasil = buka di halamannya.
class _GlobalSearch extends StatelessWidget {
  const _GlobalSearch();

  @override
  Widget build(BuildContext context) {
    final db = Get.find<AppDb>();
    return SearchAnchor(
      isFullScreen: false,
      viewConstraints: const BoxConstraints(minWidth: 480, maxHeight: 520),
      viewHintText: 'No. invoice, nama, HP, plat, produk…',
      viewBackgroundColor: C.surface,
      viewSurfaceTintColor: Colors.transparent,
      viewElevation: 8,
      viewSide: const BorderSide(color: C.border),
      viewShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(S.rCard)),
      headerTextStyle: T.body,
      dividerColor: C.border,
      builder: (context, controller) => SearchBar(
        controller: controller,
        hintText: 'Cari invoice, customer, produk…',
        leading: const Icon(Icons.search, size: 20, color: C.inkMuted),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: const WidgetStatePropertyAll(C.field),
        constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(S.rInput))),
        hintStyle: WidgetStatePropertyAll(T.body.copyWith(color: C.inkMuted)),
        textStyle: WidgetStatePropertyAll(T.body),
        onTap: controller.openView,
        onChanged: (_) => controller.openView(),
      ),
      // ponytail: query per ketikan tanpa debounce (maks. 15 baris, data 1 bengkel); tambah debounce bila terasa lambat.
      suggestionsBuilder: (context, controller) async {
        if (controller.text.trim().length < 2) {
          return [const ListTile(title: Text('Ketik minimal 2 huruf'))];
        }
        final r = await db.search(controller.text);
        if (r.isEmpty) return [const ListTile(title: Text('Tidak ditemukan'))];
        void go(VoidCallback open) {
          controller.closeView('');
          open();
        }

        Widget header(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(S.lg, S.md, S.lg, S.xs),
          child: Text(t, style: T.label),
        );
        return [
          if (r.docs.isNotEmpty) header('Invoice & pemesanan'),
          for (final d in r.docs)
            ListTile(
              dense: true,
              leading: const Icon(Icons.receipt_long_outlined, size: 20),
              title: Text('${d.doc.no} · ${d.customer}'),
              subtitle: Text([tgl(d.doc.at), d.doc.car, d.doc.plate].where((x) => x.isNotEmpty).join(' · ')),
              onTap: () => go(() => _openDoc(d.doc)),
            ),
          if (r.customers.isNotEmpty) header('Customer'),
          for (final c in r.customers)
            ListTile(
              dense: true,
              leading: const Icon(Icons.person_outline, size: 20),
              title: Text(c.name),
              subtitle: Text(
                [if (c.phone != null) displayPhone(c.phone!), c.car, c.plate].where((x) => x.isNotEmpty).join(' · '),
              ),
              onTap: () => go(() => _openCustomer(c.id)),
            ),
          if (r.products.isNotEmpty) header('Produk & jasa'),
          for (final p in r.products)
            ListTile(
              dense: true,
              leading: Icon(p.isService ? Icons.handyman_outlined : Icons.inventory_2_outlined, size: 20),
              title: Text(p.name),
              subtitle: Text([p.sku ?? '', p.category, 'Rp ${rp(p.sellPrice)}'].where((x) => x.isNotEmpty).join(' · ')),
              onTap: () => go(() => _openProduct(p)),
            ),
        ];
      },
    );
  }

  static AppDb get _db => Get.find<AppDb>();
  static void _show(AppPage p) => Get.find<Nav>().page.value = p;

  static void _openDoc(Invoice d) {
    final c = Get.put(PenjualanController(_db));
    c.kind.value = d.kind;
    c.status.value = null;
    c.panelId.value = d.id;
    _show(AppPage.penjualan);
  }

  static void _openCustomer(int id) {
    Get.put(KontakController(_db)).panelId.value = id;
    _show(AppPage.kontak);
  }

  static void _openProduct(Product p) {
    final c = Get.put(GudangController(_db));
    c.tab.value = p.isService ? GudangTab.jasa : GudangTab.barang;
    c.panelId.value = p.id;
    _show(AppPage.gudang);
  }
}
