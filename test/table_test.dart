// AppTable: urut per kolom (naik → turun → bawaan), nilai kosong di akhir, baris pin tetap di akhir, tombol Reset.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_erp_desktop/core/table.dart';

typedef _Row = ({String name, int? amount, bool total});

void main() {
  const rows = <_Row>[
    (name: 'b', amount: 250000, total: false),
    (name: 'A', amount: 1000000, total: false),
    (name: 'c', amount: null, total: false),
    (name: 'Total', amount: 1250000, total: true),
  ];

  Future<void> pump(WidgetTester t) => t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 600,
          child: AppTable<_Row>(
            rows: rows,
            searchText: (r) => r.name,
            pinned: (r) => r.total,
            columns: [
              Col('Nama', (r) => Text(r.name), sort: (r) => r.name),
              Col('Jumlah', (r) => Text('${r.amount ?? '-'}'), numeric: true, sort: (r) => r.amount),
              Col('Aksi', (r) => const SizedBox()), // tanpa sort: tidak bisa diklik
            ],
          ),
        ),
      ),
    ),
  );

  // Urutan nama baris di layar (kolom Nama), sesuai posisi vertikal.
  List<String> order(WidgetTester t) {
    final names = {for (final r in rows) r.name};
    final found = t.widgetList<Text>(find.byType(Text)).where((w) => names.contains(w.data)).toList();
    found.sort((a, b) => t.getTopLeft(find.byWidget(a)).dy.compareTo(t.getTopLeft(find.byWidget(b)).dy));
    return [for (final w in found) w.data!];
  }

  testWidgets('klik judul: naik → turun → bawaan; angka menurut nilai, kosong di akhir, Total tetap di akhir', (
    t,
  ) async {
    await pump(t);
    expect(order(t), ['b', 'A', 'c', 'Total']); // bawaan

    await t.tap(find.text('Jumlah')); // naik: 250rb < 1jt (bukan menurut teks), kosong di akhir
    await t.pump();
    expect(order(t), ['b', 'A', 'c', 'Total']);

    await t.tap(find.text('Jumlah')); // turun: kosong tetap di akhir, Total tetap paling bawah
    await t.pump();
    expect(order(t), ['A', 'b', 'c', 'Total']);

    await t.tap(find.text('Jumlah')); // kembali ke bawaan
    await t.pump();
    expect(order(t), ['b', 'A', 'c', 'Total']);

    await t.tap(find.text('Nama')); // teks tanpa beda huruf besar/kecil: A, b, c
    await t.pump();
    expect(order(t), ['A', 'b', 'c', 'Total']);
  });

  testWidgets('Reset: muncul hanya bila ada cari/urutan, lalu membersihkan keduanya', (t) async {
    await pump(t);
    expect(find.text('Reset'), findsNothing);

    await t.tap(find.text('Nama'));
    await t.enterText(find.byType(TextField), 'c');
    await t.pump();
    expect(find.text('Reset'), findsOneWidget);
    expect(order(t), ['c']);

    await t.tap(find.text('Reset'));
    await t.pump();
    expect(find.text('Reset'), findsNothing);
    expect(order(t), ['b', 'A', 'c', 'Total']);
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text, '');
  });
}
