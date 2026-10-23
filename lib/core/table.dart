import 'package:flutter/material.dart';

import 'theme.dart';

class Col<R> {
  const Col(this.label, this.cell, {this.flex = 2, this.numeric = false, this.sort});
  final String label;
  final Widget Function(R row) cell;
  final int flex;
  final bool numeric; // rata kanan

  /// Nilai pengurut baris (angka, tanggal, atau teks); null = kolom tidak bisa diurutkan (mis. kolom aksi).
  /// Pakai nilai asli, bukan teks tampilan: "1.000.000" harus di atas "250.000", bukan di bawahnya.
  final Object? Function(R row)? sort;
}

/// Urutan nilai pengurut: kosong (null) selalu di akhir, angka/tanggal menurut nilainya, selain itu teks tanpa
/// membedakan huruf besar/kecil.
int _compareSortKeys(Object? a, Object? b) {
  if (a == null || b == null) return a == null ? (b == null ? 0 : 1) : -1;
  if (a is num && b is num) return a.compareTo(b);
  if (a is DateTime && b is DateTime) return a.compareTo(b);
  if (a is bool && b is bool) return a == b ? 0 : (a ? 1 : -1);
  return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
}

/// Tabel standar semua daftar (design.md §6): kotak cari, header, baris 48 px,
/// klik baris, paginasi 25 per halaman, empty state.
class AppTable<R> extends StatefulWidget {
  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.searchText,
    this.onTap,
    this.selected,
    this.emptyMessage = 'Belum ada data.',
    this.searchHint = 'Cari…',
    this.toolbar = const [],
    this.pinned,
  });

  final List<Col<R>> columns;
  final List<R> rows;

  /// Teks yang dicocokkan dengan kata kunci pencarian untuk tiap baris.
  final String Function(R row) searchText;
  final ValueChanged<R>? onTap;
  final bool Function(R row)? selected;
  final String emptyMessage, searchHint;
  final List<Widget> toolbar;

  /// Baris yang selalu tetap di akhir daftar dan tidak ikut diurutkan (mis. baris Total laporan).
  final bool Function(R row)? pinned;

  @override
  State<AppTable<R>> createState() => _AppTableState<R>();
}

class _AppTableState<R> extends State<AppTable<R>> {
  static const pageSize = 25;
  final _search = TextEditingController();
  String _q = '';
  int _page = 0;

  /// Kolom yang diurutkan (menurut judul, supaya tahan bila susunan kolom berubah) dan arahnya.
  String? _sortLabel;
  var _desc = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Klik judul kolom: naik → turun → urutan bawaan.
  void _toggleSort(Col<R> c) => setState(() {
    if (_sortLabel != c.label) {
      _sortLabel = c.label;
      _desc = false;
    } else if (!_desc) {
      _desc = true;
    } else {
      _sortLabel = null;
      _desc = false;
    }
    _page = 0;
  });

  /// Kosongkan kotak cari dan urutan di tabel ini saja (rentang tanggal & filter halaman tidak disentuh).
  void _reset() => setState(() {
    _search.clear();
    _q = '';
    _sortLabel = null;
    _desc = false;
    _page = 0;
  });

  /// Judul kolom; kolom yang bisa diurutkan = dapat diklik, dengan panah arah urutan.
  Widget _header(Col<R> c) {
    if (c.sort == null) return Text(c.label);
    final active = c.label == _sortLabel;
    final arrow = Icon(
      active ? (_desc ? Icons.arrow_downward : Icons.arrow_upward) : Icons.unfold_more,
      size: 14,
      color: active ? C.primary : C.inkMuted,
    );
    return InkWell(
      onTap: () => _toggleSort(c),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.numeric) arrow,
          Flexible(
            child: Text(
              c.label,
              overflow: TextOverflow.ellipsis,
              style: active ? TextStyle(color: C.primary) : null,
            ),
          ),
          if (!c.numeric) arrow,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    var filtered = q.isEmpty
        ? widget.rows
        : widget.rows.where((r) => widget.searchText(r).toLowerCase().contains(q)).toList();
    final sortCol = widget.columns.where((c) => c.sort != null && c.label == _sortLabel).firstOrNull;
    if (sortCol != null) {
      final pinned = widget.pinned;
      final body = [
        for (final r in filtered)
          if (pinned == null || !pinned(r)) r,
      ];
      // Urutan stabil: indeks asli jadi pemutus seri, supaya baris bernilai sama tidak berpindah-pindah.
      final order = {for (final (i, r) in body.indexed) r: i};
      body.sort((a, b) {
        final c = _compareSortKeys(sortCol.sort!(a), sortCol.sort!(b));
        // Nilai kosong tetap di akhir, juga saat urutan turun.
        final emptyA = sortCol.sort!(a) == null, emptyB = sortCol.sort!(b) == null;
        final byValue = (emptyA || emptyB) ? c : (_desc ? -c : c);
        return byValue != 0 ? byValue : order[a]!.compareTo(order[b]!);
      });
      filtered = [...body, if (pinned != null) ...filtered.where(pinned)];
    }
    final canReset = q.isNotEmpty || _sortLabel != null;
    final pages = (filtered.length / pageSize).ceil().clamp(1, 1 << 30);
    final page = _page.clamp(0, pages - 1);
    final shown = filtered.skip(page * pageSize).take(pageSize).toList();

    Widget cells(List<Widget> children, {TextStyle? style}) => Row(
      children: [
        for (var i = 0; i < widget.columns.length; i++)
          Expanded(
            flex: widget.columns[i].flex,
            child: Align(
              alignment: widget.columns[i].numeric ? Alignment.centerRight : Alignment.centerLeft,
              child: DefaultTextStyle.merge(
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: children[i],
              ),
            ),
          ),
      ].expand((w) => [w, const SizedBox(width: S.lg)]).toList()..removeLast(),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(S.md),
            child: Row(
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        prefixIcon: const Icon(Icons.search, size: 20),
                      ),
                      onChanged: (v) => setState(() {
                        _q = v.trim();
                        _page = 0;
                      }),
                    ),
                  ),
                ),
                if (canReset) ...[
                  const SizedBox(width: S.sm),
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Reset'),
                  ),
                ],
                // Toolbar membungkus ke baris berikut bila jendela sempit.
                if (widget.toolbar.isNotEmpty) ...[
                  const SizedBox(width: S.md),
                  Flexible(
                    flex: 2,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: S.sm,
                      runSpacing: S.sm,
                      children: widget.toolbar,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            color: C.bg,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: S.lg),
            child: cells([for (final c in widget.columns) _header(c)], style: T.label),
          ),
          const Divider(),
          Expanded(
            child: shown.isEmpty
                ? Center(child: Text(q.isEmpty ? widget.emptyMessage : 'Tidak ada yang cocok.', style: T.pageSubtitle))
                : ListView.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, i) {
                      final r = shown[i];
                      return Material(
                        color: widget.selected?.call(r) == true ? C.primarySoft : C.surface,
                        child: InkWell(
                          onTap: widget.onTap == null ? null : () => widget.onTap!(r),
                          hoverColor: C.bg,
                          child: Container(
                            height: S.row,
                            padding: const EdgeInsets.symmetric(horizontal: S.lg),
                            child: cells([for (final c in widget.columns) c.cell(r)], style: T.body),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: S.sm),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    filtered.isEmpty
                        ? '0 data'
                        : 'Menampilkan ${page * pageSize + 1}–${page * pageSize + shown.length} dari ${filtered.length}',
                    style: T.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Sebelumnya',
                  onPressed: page > 0 ? () => setState(() => _page = page - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${page + 1} / $pages', style: T.label),
                IconButton(
                  tooltip: 'Berikutnya',
                  onPressed: page < pages - 1 ? () => setState(() => _page = page + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
