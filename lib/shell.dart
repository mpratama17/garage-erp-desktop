import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/format.dart';
import 'core/theme.dart';
import 'core/ui.dart';
import 'db/database.dart';
import 'modules/gudang/gudang_page.dart';
import 'modules/kontak/kontak_page.dart';
import 'modules/pengaturan/pengaturan_page.dart';

class _Menu {
  const _Menu(this.label, this.icon, this.page);
  final String label;
  final IconData icon;
  final Widget page;
}

final _menus = <_Menu>[
  const _Menu('Penjualan', Icons.receipt_long_outlined, _Soon('Penjualan')),
  const _Menu('Gudang', Icons.inventory_2_outlined, GudangPage()),
  const _Menu('Kontak', Icons.people_outline, KontakPage()),
  const _Menu('Kas & Bank', Icons.account_balance_wallet_outlined, _Soon('Kas & Bank')),
  const _Menu('Biaya', Icons.payments_outlined, _Soon('Biaya')),
  const _Menu('Gaji', Icons.badge_outlined, _Soon('Gaji')),
  const _Menu('Laporan', Icons.bar_chart_outlined, _Soon('Laporan')),
];
const _settingsIndex = 7;

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(selected: _index, onSelect: (i) => setState(() => _index = i)),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(index: _index, children: [for (final m in _menus) m.page, const PengaturanPage()]),
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

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

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
          final logo = s['logo_path']!;
          final lastBackup = DateTime.tryParse(s['last_backup_at']!);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(S.sm, S.sm, S.sm, S.xl),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(S.rInput)),
                      child: logo.isNotEmpty && File(logo).existsSync()
                          ? Image.file(File(logo), fit: BoxFit.cover)
                          : const Icon(Icons.build_outlined, color: C.surface, size: 20),
                    ),
                    const SizedBox(width: S.md),
                    Expanded(
                      child: Text(s['shop_name']!, style: T.section, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < _menus.length; i++)
                _Item(_menus[i].label, _menus[i].icon, selected == i, () => onSelect(i)),
              const Spacer(),
              _Item('Pengaturan', Icons.settings_outlined, selected == _settingsIndex, () => onSelect(_settingsIndex)),
              Padding(
                padding: const EdgeInsets.all(S.sm),
                child: Text(
                  lastBackup == null
                      ? 'Belum ada backup'
                      : 'Backup terakhir ${tgl(lastBackup)} ${lastBackup.hour.toString().padLeft(2, '0')}:${lastBackup.minute.toString().padLeft(2, '0')}',
                  style: T.label.copyWith(color: lastBackup == null ? C.danger : C.inkMuted),
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
  const _Item(this.label, this.icon, this.active, this.onTap);
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: S.xs),
    child: Material(
      color: active ? C.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(S.rInput),
      child: InkWell(
        borderRadius: BorderRadius.circular(S.rInput),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              const SizedBox(width: S.md),
              Icon(icon, size: 20, color: active ? C.primary : C.inkMuted),
              const SizedBox(width: S.md),
              Text(
                label,
                style: T.body.copyWith(
                  color: active ? C.primary : C.ink,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Placeholder untuk modul yang belum dibangun.
class _Soon extends StatelessWidget {
  const _Soon(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PageHeader(title: title),
      const Expanded(child: EmptyState(message: 'Modul ini sedang dibangun.')),
    ],
  );
}
