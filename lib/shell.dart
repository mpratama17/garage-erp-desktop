import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'core/format.dart';
import 'core/theme.dart';
import 'core/ui.dart';
import 'db/database.dart';
import 'modules/biaya/biaya_page.dart';
import 'modules/dashboard/dashboard_page.dart';
import 'modules/gaji/gaji_page.dart';
import 'modules/gudang/gudang_controller.dart';
import 'modules/gudang/gudang_page.dart';
import 'modules/kas/kas_page.dart';
import 'modules/kontak/kontak_controller.dart';
import 'modules/kontak/kontak_page.dart';
import 'modules/laporan/laporan_page.dart';
import 'modules/pembelian/pembelian_controller.dart';
import 'modules/pembelian/pembelian_page.dart';
import 'modules/pengaturan/pengaturan_page.dart';
import 'modules/penjualan/penjualan_controller.dart';
import 'modules/penjualan/penjualan_page.dart';
import 'modules/penjualan/penjualan_repo.dart' show DocKind;
import 'modules/search_repo.dart';

/// Halaman di sidebar. Urutan menu ada di [_sidebarGroups]; Pengaturan ditaruh terpisah di bawah.
enum AppPage {
  dashboard('Beranda', Icons.space_dashboard_outlined, Color(0xFF2F5BEA)),
  penjualan('Penjualan', Icons.receipt_long_outlined, Color(0xFF0F9D6B)),
  pembelian('Pembelian', Icons.shopping_cart_outlined, Color(0xFFE8890C)),
  gudang('Gudang', Icons.inventory_2_outlined, Color(0xFF7C4DDB)),
  biaya('Biaya', Icons.payments_outlined, Color(0xFFD6336C)),
  kontak('Kontak', Icons.people_alt_outlined, Color(0xFF0B8FA3)),
  kas('Kas & Bank', Icons.account_balance_wallet_outlined, Color(0xFF2B8A3E)),
  gaji('Gaji', Icons.badge_outlined, Color(0xFFC77700)),
  laporan('Laporan', Icons.insights_outlined, Color(0xFF4C6EF5)),
  pengaturan('Pengaturan', Icons.settings_outlined, Color(0xFF64748B));

  const AppPage(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  Widget get page => switch (this) {
    dashboard => const DashboardPage(),
    penjualan => const PenjualanPage(),
    pembelian => const PembelianPage(),
    gudang => const GudangPage(),
    kontak => const KontakPage(),
    kas => const KasPage(),
    biaya => const BiayaPage(),
    gaji => const GajiPage(),
    laporan => const LaporanPage(),
    pengaturan => const PengaturanPage(),
  };
}

/// Halaman aktif + sidebar ciut/lebar; dipakai sidebar dan cari global (buka halaman + record).
/// [pembelianTagihan] = Pembelian ▸ Tagihan Pembelian (hanya yang belum dibayar).
class Nav extends GetxController {
  final page = AppPage.dashboard.obs;
  final sidebarExpanded = true.obs;
  final pembelianTagihan = false.obs;
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.put(Nav());
    return Scaffold(
      body: Row(
        children: [
          const _Sidebar(),
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

const _sidebarCollapsedWidth = 76.0, _sidebarExpandedWidth = 232.0;

/// Di bawah lebar ini (mis. Split View setengah layar) sidebar dipaksa ciut supaya isi halaman tetap lega.
const _narrowWidth = 1000.0;

/// Menu per kelompok; antar kelompok hanya garis pemisah tipis (tanpa judul).
const _sidebarGroups = <List<AppPage>>[
  [AppPage.penjualan, AppPage.pembelian],
  [AppPage.gudang, AppPage.biaya],
  [AppPage.kontak, AppPage.kas, AppPage.gaji],
  [AppPage.laporan],
];

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<Nav>();
    final narrow = MediaQuery.sizeOf(context).width < _narrowWidth;
    return StreamBuilder<Map<String, String>>(
      stream: _settings,
      builder: (context, snap) {
        final s = snap.data ?? settingDefaults;
        return Obx(() {
          final extended = nav.sidebarExpanded.value && !narrow;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: extended ? _sidebarExpandedWidth : _sidebarCollapsedWidth,
            color: C.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SidebarHeader(s, extended),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: S.sm),
                    child: Column(
                      children: [
                        _NavItem(AppPage.dashboard, extended: extended),
                        for (final pages in _sidebarGroups) ...[
                          const _GroupDivider(),
                          for (final p in pages) _NavItem(p, extended: extended),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: S.sm),
                  child: _NavItem(AppPage.pengaturan, extended: extended),
                ),
                if (extended) _BackupCard(s),
                if (!narrow) _ToggleButton(extended: extended, onTap: nav.sidebarExpanded.toggle),
              ],
            ),
          );
        });
      },
    );
  }
}

/// Garis pemisah tipis antar kelompok menu.
class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: S.sm, horizontal: S.md),
    child: Divider(),
  );
}

/// Anak menu (dropdown) per halaman; tampil saat halaman induknya aktif dan sidebar lebar.
typedef _Child = ({String label, IconData icon, bool Function() selected, VoidCallback open});

List<_Child> _childrenOf(AppPage page) {
  final nav = Get.find<Nav>();
  switch (page) {
    case AppPage.penjualan:
      PenjualanController pc() => Get.put(PenjualanController(Get.find<AppDb>()));
      return [
        (
          label: 'Tagihan',
          icon: Icons.request_quote_outlined,
          selected: () => pc().kind.value == DocKind.invoice,
          open: () => pc().kind.value = DocKind.invoice,
        ),
        (
          label: 'Pemesanan',
          icon: Icons.event_note_outlined,
          selected: () => pc().kind.value == DocKind.order,
          open: () => pc().kind.value = DocKind.order,
        ),
      ];
    case AppPage.pembelian:
      return [
        (
          label: 'Tagihan Pembelian',
          icon: Icons.request_quote_outlined,
          selected: () => nav.pembelianTagihan.value,
          open: () => nav.pembelianTagihan.value = true,
        ),
      ];
    default:
      return const [];
  }
}

/// Satu menu: ikon berwarna + label (label disembunyikan saat ciut), pil lembut saat aktif, hover halus.
class _NavItem extends StatefulWidget {
  const _NavItem(this.page, {required this.extended});
  final AppPage page;
  final bool extended;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<Nav>();
    final children = _childrenOf(widget.page);
    return Obx(() {
      final selected = nav.page.value == widget.page;
      final color = selected ? C.primary : C.inkMuted;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: GestureDetector(
                onTap: () {
                  if (widget.page == AppPage.pembelian) nav.pembelianTagihan.value = false;
                  nav.page.value = widget.page;
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: S.xs + 2),
                  decoration: BoxDecoration(
                    color: selected && !children.any((ch) => ch.selected()) ? C.primarySoft : (_hovered ? C.bg : null),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Label baru tampil saat panel cukup lebar (selama animasi ciut/lebar tidak meluber).
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final label = widget.extended && box.maxWidth > 110;
                      return Row(
                        mainAxisAlignment: label ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          Icon(widget.page.icon, size: 21, color: widget.page.color),
                          if (label) ...[
                            const SizedBox(width: S.md),
                            Expanded(
                              child: Text(
                                widget.page.label,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                style: T.body.copyWith(
                                  color: color,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (children.isNotEmpty)
                              Icon(selected ? Icons.expand_less : Icons.expand_more, size: 18, color: C.inkMuted),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (selected && widget.extended)
            for (final ch in children) _ChildItem(widget.page, ch),
        ],
      );
    });
  }
}

class _ChildItem extends StatelessWidget {
  const _ChildItem(this.page, this.child);
  final AppPage page;
  final _Child child;

  @override
  Widget build(BuildContext context) => Obx(() {
    final on = child.selected();
    return Padding(
      padding: const EdgeInsets.only(left: S.xl, top: 1, bottom: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          child.open();
          Get.find<Nav>().page.value = page;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: S.xs + 1),
          decoration: BoxDecoration(color: on ? C.primarySoft : null, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(child.icon, size: 17, color: on ? C.primary : C.inkMuted),
              const SizedBox(width: S.sm),
              Expanded(
                child: Text(
                  child.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: T.body.copyWith(
                    fontSize: 13,
                    color: on ? C.primary : C.inkMuted,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}

/// Ciutkan/lebarkan panel menu.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.extended, required this.onTap});
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('sidebar_toggle_button'),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Align(
        alignment: extended ? Alignment.centerRight : Alignment.center,
        child: Icon(extended ? Icons.chevron_left : Icons.chevron_right, color: C.inkMuted, size: 20),
      ),
    ),
  );
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader(this.s, this.extended);
  final Map<String, String> s;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final icon = s['logo_icon_path']!;
    final logo = icon.isNotEmpty && File(icon).existsSync()
        ? Image.file(File(icon), width: 40, height: 40, fit: BoxFit.contain)
        : Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.build_outlined, color: C.surface, size: 20),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(S.xs, S.sm, S.xs, S.lg),
      child: Row(
        mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          logo,
          // Gap di dalam Expanded: tidak overflow saat lebar panel sedang dianimasikan.
          if (extended)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: S.md),
                child: Text(s['shop_name']!, style: T.section, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
      ),
    );
  }
}

/// Status backup di bawah menu (hanya saat panel terbuka).
class _BackupCard extends StatelessWidget {
  const _BackupCard(this.s);
  final Map<String, String> s;

  @override
  Widget build(BuildContext context) {
    final lastBackup = DateTime.tryParse(s['last_backup_at']!);
    final off = s['backup_schedule'] == 'off';
    final bad = lastBackup == null || off;
    final text = [
      if (lastBackup == null)
        'Belum pernah dibackup'
      else
        'Backup ${tgl(lastBackup)} ${DateFormat.Hm().format(lastBackup)}',
      if (off) 'otomatis mati',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(S.xs, S.sm, S.xs, S.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: S.sm),
        decoration: BoxDecoration(color: C.field, borderRadius: BorderRadius.circular(S.rInput)),
        child: Row(
          children: [
            Icon(Icons.cloud_done_outlined, size: 18, color: bad ? Tone.danger.fg : Tone.success.fg),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: S.sm),
                child: Text(text, style: T.label.copyWith(color: bad ? Tone.danger.fg : C.inkMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ topbar

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: S.xl),
    decoration: const BoxDecoration(
      color: C.surface,
      border: Border(bottom: BorderSide(color: C.border)),
    ),
    child: Row(
      children: [
        Flexible(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: const _GlobalSearch()),
        ),
        const Spacer(),
        // Tanggal disembunyikan di jendela sempit (Split View).
        if (MediaQuery.sizeOf(context).width >= _narrowWidth) ...[
          const Icon(Icons.calendar_today_outlined, size: 16, color: C.inkMuted),
          const SizedBox(width: S.sm),
          const _Today(),
        ],
        const SizedBox(width: S.lg),
        const OwnerLockButton(),
      ],
    ),
  );
}

/// Tanggal hari ini; ikut berganti bila app terbuka melewati tengah malam.
class _Today extends StatefulWidget {
  const _Today();

  @override
  State<_Today> createState() => _TodayState();
}

class _TodayState extends State<_Today> {
  late final _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));

  @override
  void initState() {
    super.initState();
    _timer; // mulai timer
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(DateFormat('EEEE, d MMMM y', 'id').format(DateTime.now()), style: T.label);
}

/// Buka invoice/pemesanan [d] di halaman Penjualan (dari cari global, riwayat stok, riwayat belanja).
void openDoc(Invoice d) {
  final c = Get.put(PenjualanController(Get.find<AppDb>()));
  c.kind.value = d.kind;
  c.status.value = null;
  c.panelId.value = d.id;
  Get.find<Nav>().page.value = AppPage.penjualan;
}

/// Buka pembelian [id] di halaman Pembelian (dari riwayat stok Gudang).
void openPurchase(int id) {
  Get.put(PembelianController(Get.find<AppDb>())).purchaseId.value = id;
  Get.find<Nav>()
    ..pembelianTagihan.value = false
    ..page.value = AppPage.pembelian;
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
              onTap: () => go(() => openDoc(d.doc)),
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

  static void _openCustomer(int id) {
    Get.put(KontakController(_db))
      ..tab.value = KontakTab
          .customer // panel customer hanya ada di tab Customer
      ..panelId.value = id;
    _show(AppPage.kontak);
  }

  static void _openProduct(Product p) {
    final c = Get.put(GudangController(_db));
    c.tab.value = p.isService ? GudangTab.jasa : GudangTab.barang;
    c.panelId.value = p.id;
    _show(AppPage.gudang);
  }
}
