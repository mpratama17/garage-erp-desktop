import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'format.dart';
import 'theme.dart';

/// Bulan berjalan (tanggal 1 – akhir bulan): rentang awal halaman yang memakai filter tanggal.
DateTimeRange thisMonth() {
  final n = DateTime.now();
  return DateTimeRange(start: DateTime(n.year, n.month), end: DateTime(n.year, n.month + 1, 0));
}

extension RangeDays on DateTimeRange {
  /// Batas eksklusif (sehari sesudah [end]) untuk query [start, endExclusive).
  DateTime get endExclusive => dayAfter(end);
  bool covers(DateTime d) => !d.isBefore(start) && d.isBefore(endExclusive);
}

/// Pop-up kecil pilih rentang tanggal: dua bulan berdampingan (satu bulan bila jendela sempit).
/// Satu widget untuk Dashboard, Penjualan, Pembelian, Biaya, dan Kas & Bank. Hasil: tanggal awal & akhir (inklusif).
Future<DateTimeRange?> pickRange(BuildContext context, {DateTimeRange? initial, DateTime? first, DateTime? last}) =>
    showDialog<DateTimeRange>(
      context: context,
      builder: (_) => _RangeDialog(initial: initial, first: first ?? DateTime(2020), last: last ?? DateTime.now()),
    );

/// Tombol berisi rentang terpilih; [range] null = "Semua tanggal". Ada tombol x kecil untuk mengosongkan
/// bila [onChanged] menerima null (mis. daftar yang boleh tanpa filter).
class RangeButton extends StatelessWidget {
  const RangeButton({super.key, required this.range, required this.onChanged, this.clearable = false});
  final DateTimeRange? range;
  final ValueChanged<DateTimeRange?> onChanged;
  final bool clearable;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: () async {
        final r = await pickRange(context, initial: range);
        if (r != null) onChanged(r);
      },
      icon: const Icon(Icons.date_range_outlined, size: 18),
      label: Text(
        range == null ? 'Semua tanggal' : '${tgl(range!.start)} – ${tgl(range!.end)}',
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
    if (!clearable || range == null) return button;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: button),
        IconButton(tooltip: 'Hapus rentang', onPressed: () => onChanged(null), icon: const Icon(Icons.close, size: 18)),
      ],
    );
  }
}

class _RangeDialog extends StatefulWidget {
  const _RangeDialog({required this.initial, required this.first, required this.last});
  final DateTimeRange? initial;
  final DateTime first, last;

  @override
  State<_RangeDialog> createState() => _RangeDialogState();
}

class _RangeDialogState extends State<_RangeDialog> {
  // Kiri = bulan awal rentang; tanpa rentang awal, tampilkan bulan lalu + bulan ini.
  late DateTime _month = widget.initial != null
      ? DateTime(widget.initial!.start.year, widget.initial!.start.month)
      : DateTime(widget.last.year, widget.last.month - 1);
  late DateTime? _start = widget.initial?.start;
  late DateTime? _end = widget.initial?.end;

  void _tap(DateTime d) => setState(() {
    if (_start == null || _end != null) {
      _start = d;
      _end = null;
    } else if (d.isBefore(_start!)) {
      _start = d;
    } else {
      _end = d;
    }
  });

  void _quick(DateTime from, DateTime to) => setState(() {
    _start = from;
    _end = to;
    _month = from;
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final t = DateTime(now.year, now.month, now.day);
    // Pilihan cepat mengikuti Kledo (referensi client).
    final presets = <(String, DateTime, DateTime)>[
      ('Kemarin', DateTime(t.year, t.month, t.day - 1), DateTime(t.year, t.month, t.day - 1)),
      ('Hari ini', t, t),
      ('Bulan ini', DateTime(t.year, t.month), t),
      ('Bulan lalu', DateTime(t.year, t.month - 1), DateTime(t.year, t.month, 0)),
      ('7 hari terakhir', DateTime(t.year, t.month, t.day - 6), t),
      ('30 hari terakhir', DateTime(t.year, t.month, t.day - 29), t),
      ('Tahun ini', DateTime(t.year), t),
      ('Tahun lalu', DateTime(t.year - 1), DateTime(t.year - 1, 12, 31)),
      ('1 tahun terakhir', DateTime(t.year - 1, t.month, t.day), t),
      ('2 tahun terakhir', DateTime(t.year - 2, t.month, t.day), t),
    ];
    Widget preset((String, DateTime, DateTime) p) {
      final on = _start == p.$2 && _end == p.$3;
      return TextButton(
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          minimumSize: const Size(0, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: S.md),
          textStyle: T.body.copyWith(fontSize: 13),
          foregroundColor: on ? C.primary : C.ink,
          backgroundColor: on ? C.primarySoft : null,
        ),
        onPressed: () => _quick(p.$2, p.$3),
        child: Text(p.$1),
      );
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.all(S.lg),
          child: LayoutBuilder(
            builder: (context, box) {
              final two = box.maxWidth > 660;
              final calendar = Row(
                children: [
                  IconButton(
                    tooltip: 'Bulan sebelumnya',
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _Month(_month, _start, _end, widget.first, widget.last, _tap)),
                        if (two) ...[
                          const SizedBox(width: S.lg),
                          Expanded(
                            child: _Month(
                              DateTime(_month.year, _month.month + 1),
                              _start,
                              _end,
                              widget.first,
                              widget.last,
                              _tap,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bulan berikutnya',
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Lebar: daftar pilihan cepat di kiri kalender (seperti Kledo); sempit: dibungkus di atas.
                  if (two)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          padding: const EdgeInsets.only(right: S.sm),
                          margin: const EdgeInsets.only(right: S.md),
                          decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: C.border)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [for (final p in presets) preset(p)],
                          ),
                        ),
                        Expanded(child: calendar),
                      ],
                    )
                  else ...[
                    Wrap(spacing: S.xs, children: [for (final p in presets) preset(p)]),
                    const SizedBox(height: S.sm),
                    calendar,
                  ],
                  const SizedBox(height: S.sm),
                  Wrap(
                    spacing: S.sm,
                    runSpacing: S.xs,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _start == null ? 'Pilih tanggal awal' : '${tgl(_start!)} – ${_end == null ? '…' : tgl(_end!)}',
                        style: T.label,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                          const SizedBox(width: S.sm),
                          FilledButton(
                            // Satu tanggal saja = rentang satu hari.
                            onPressed: _start == null
                                ? null
                                : () => Navigator.pop(context, DateTimeRange(start: _start!, end: _end ?? _start!)),
                            child: const Text('Terapkan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Month extends StatelessWidget {
  const _Month(this.month, this.start, this.end, this.first, this.last, this.onTap);
  final DateTime month;
  final DateTime? start, end;
  final DateTime first, last;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final offset = DateTime(month.year, month.month).weekday - 1; // Senin di kiri
    final lo = DateUtils.dateOnly(first), hi = DateUtils.dateOnly(last);
    Widget cell(int day) {
      final d = DateTime(month.year, month.month, day);
      final disabled = d.isBefore(lo) || d.isAfter(hi);
      final isEdge = d == start || d == end;
      final inside = start != null && end != null && d.isAfter(start!) && d.isBefore(end!);
      return GestureDetector(
        onTap: disabled ? null : () => onTap(d),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          alignment: Alignment.center,
          height: 32,
          decoration: BoxDecoration(
            color: isEdge ? C.primary : (inside ? C.primarySoft : null),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$day',
            style: T.body.copyWith(
              fontSize: 13,
              color: isEdge ? C.surface : (disabled ? C.border : C.ink),
              fontWeight: isEdge ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    final cells = <Widget>[
      for (final h in const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']) Center(child: Text(h, style: T.label)),
      for (var i = 0; i < offset; i++) const SizedBox(),
      for (var d = 1; d <= days; d++) cell(d),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: S.xs),
          child: Text(DateFormat('MMMM y', 'id').format(month), style: T.section),
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.15,
          children: cells,
        ),
      ],
    );
  }
}
