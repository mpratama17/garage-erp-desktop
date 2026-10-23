import 'package:flutter/material.dart';

import 'theme.dart';

class Col<R> {
  const Col(this.label, this.cell, {this.flex = 2, this.numeric = false, this.text});
  final String label;
  final Widget Function(R row) cell;
  final int flex;
  final bool numeric; // rata kanan

  /// Teks sel untuk filter per kolom (aktif bila tabel memakai `columnFilters`); null = kolom tanpa filter.
  final String Function(R row)? text;
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
    this.columnFilters = false,
  });

  final List<Col<R>> columns;
  final List<R> rows;

  /// Teks yang dicocokkan dengan kata kunci pencarian untuk tiap baris.
  final String Function(R row) searchText;
  final ValueChanged<R>? onTap;
  final bool Function(R row)? selected;
  final String emptyMessage, searchHint;
  final List<Widget> toolbar;

  /// Tampilkan baris isian filter di bawah judul kolom (kolom yang punya [Col.text]).
  final bool columnFilters;

  @override
  State<AppTable<R>> createState() => _AppTableState<R>();
}

class _AppTableState<R> extends State<AppTable<R>> {
  static const pageSize = 25;
  String _q = '';
  int _page = 0;
  // Per judul kolom, bukan indeks: susunan kolom bisa berubah (mis. Kas & Bank saat satu rekening dipilih).
  final _colQ = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final colQ = {
      if (widget.columnFilters) // baris filter tersembunyi = filter tidak berlaku
        for (final (i, c) in widget.columns.indexed)
          if (c.text != null && (_colQ[c.label] ?? '').isNotEmpty) i: _colQ[c.label]!.toLowerCase(),
    };
    final filtered = q.isEmpty && colQ.isEmpty
        ? widget.rows
        : widget.rows.where((r) {
            if (q.isNotEmpty && !widget.searchText(r).toLowerCase().contains(q)) return false;
            return colQ.entries.every(
              (e) => (widget.columns[e.key].text?.call(r) ?? '').toLowerCase().contains(e.value),
            );
          }).toList();
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
            child: cells([for (final c in widget.columns) Text(c.label)], style: T.label),
          ),
          if (widget.columnFilters) ...[
            const Divider(),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: 4),
              child: Row(
                children: [
                  for (final (i, c) in widget.columns.indexed) ...[
                    if (i > 0) const SizedBox(width: S.lg),
                    Expanded(
                      flex: c.flex,
                      child: c.text == null
                          ? const SizedBox()
                          : TextFormField(
                              key: ValueKey(c.label),
                              initialValue: _colQ[c.label],
                              style: T.body.copyWith(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Filter…',
                                hintStyle: T.body.copyWith(fontSize: 12, color: C.inkMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: S.sm, vertical: S.sm),
                              ),
                              onChanged: (v) => setState(() {
                                _colQ[c.label] = v.trim();
                                _page = 0;
                              }),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
