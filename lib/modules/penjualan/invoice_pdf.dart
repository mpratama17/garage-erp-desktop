import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format.dart';
import '../../db/database.dart';
import 'penjualan_repo.dart';

const _blue = PdfColor.fromInt(0xFF3B6CB7);
const _navy = PdfColor.fromInt(0xFF1E2A44);
const _head = PdfColor.fromInt(0xFF2F3B52);
const _cell = PdfColor.fromInt(0xFFE8EAEE);
const _grey = PdfColor.fromInt(0xFF555555);

/// Layout mengikuti nota client dari Kledo (INV/00245 & INV/00246).
Future<Uint8List> buildInvoicePdf(AppDb db, int docId) async {
  final s = await db.docSummary(docId);
  final inv = s.doc;
  final lines = await db.watchLines(docId).first;
  final cust = inv.customerId == null
      ? null
      : await (db.select(db.customers)..where((c) => c.id.equals(inv.customerId!))).getSingle();
  final order = inv.orderId == null
      ? null
      : await (db.select(db.invoices)..where((i) => i.id.equals(inv.orderId!))).getSingleOrNull();
  final set = await db.allSettings();
  final logoFile = File(set['logo_path']!);
  final logo = set['logo_path']!.isNotEmpty && logoFile.existsSync()
      ? pw.MemoryImage(logoFile.readAsBytesSync())
      : null;
  final shop = set['shop_name']!;
  final isOrder = s.isOrder;

  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf')),
    bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf')),
  );
  const small = pw.TextStyle(fontSize: 9);
  final bold9 = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

  pw.Widget section(String title, List<pw.Widget> body) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _navy, fontSize: 10),
      ),
      pw.Divider(color: _navy, thickness: 2, height: 14),
      ...body,
    ],
  );
  pw.Widget muted(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 3),
    child: pw.Text(t, style: const pw.TextStyle(color: _grey, fontSize: 9)),
  );
  pw.Widget totalRow(String k, String v, {bool big = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          k,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 13 : 10),
        ),
        pw.Text(
          v,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 13 : 10),
        ),
      ],
    ),
  );

  final meta = <(String, String)>[
    ('Nomor', inv.no),
    ('Tanggal', tgl(inv.at)),
    if (!isOrder && inv.dueAt != null) ('Tgl. Jatuh Tempo', tgl(inv.dueAt!)),
    if (order != null) ('Pemesanan', order.no),
  ];

  final doc = pw.Document(title: inv.no, author: shop, theme: theme);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Stack(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 150,
                    height: 80,
                    child: logo != null
                        ? pw.Image(logo, fit: pw.BoxFit.contain, alignment: pw.Alignment.centerLeft)
                        : pw.Text(shop, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        isOrder ? 'Pemesanan' : 'Invoice',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _blue),
                      ),
                      pw.SizedBox(height: 10),
                      for (final (k, v) in meta)
                        pw.Row(
                          children: [
                            pw.SizedBox(
                              width: 100,
                              child: pw.Text(k, textAlign: pw.TextAlign.right, style: small),
                            ),
                            pw.SizedBox(
                              width: 80,
                              child: pw.Text(v, textAlign: pw.TextAlign.right, style: small),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: section('Informasi Perusahaan', [
                      pw.Text(
                        shop,
                        style: pw.TextStyle(color: _blue, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 6),
                      if (set['shop_address']!.isNotEmpty) muted(set['shop_address']!),
                      if (set['shop_phone']!.isNotEmpty) muted('Telp: ${set['shop_phone']}'),
                      if (set['shop_email']!.isNotEmpty) muted('Email: ${set['shop_email']}'),
                    ]),
                  ),
                  pw.SizedBox(width: 40),
                  pw.Expanded(
                    child: section('Tagihan Kepada', [
                      pw.Text(
                        cust?.name ?? 'UMUM',
                        style: pw.TextStyle(color: _blue, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 6),
                      if (cust?.phone != null) muted('Telp: ${cust!.phone}'),
                      if ('${inv.car}${inv.plate}'.isNotEmpty)
                        muted('Mobil: ${[inv.car, inv.plate].where((x) => x.isNotEmpty).join(' / ')}'),
                    ]),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Produk', 'Deskripsi', 'Kuantitas', 'Harga', 'Diskon', 'Pajak', 'Jumlah'],
                data: [
                  for (final l in lines)
                    [
                      l.name,
                      l.description,
                      '${l.qty}',
                      rp(l.price),
                      l.discount == 0 ? '0' : rp(l.discount),
                      '',
                      rp(l.qty * l.price - l.discount),
                    ],
                ],
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: _head),
                cellStyle: const pw.TextStyle(fontSize: 9, color: _grey),
                cellDecoration: (_, _, _) => const pw.BoxDecoration(color: _cell),
                border: pw.TableBorder.symmetric(inside: const pw.BorderSide(color: PdfColors.white, width: 2)),
                cellPadding: const pw.EdgeInsets.all(6),
                columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(2.5)},
                cellAlignments: {
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                },
                headerAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: section('Pesan', [
                      for (final line in set['invoice_note']!.split('\n'))
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Text(line, style: small),
                        ),
                      pw.SizedBox(height: 4),
                      pw.Text('Terbilang', style: small),
                      pw.Text(terbilang(s.total), style: small),
                    ]),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      children: [
                        totalRow('Subtotal', rupiah(s.total)),
                        totalRow('Total', rupiah(s.total), big: true),
                        if (s.paid > 0) totalRow('Pembayaran Diterima', rupiah(s.paid)),
                        totalRow('Sisa Tagihan', rupiah(s.remaining < 0 ? 0 : s.remaining)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 160,
                  child: pw.Column(
                    children: [
                      pw.Text('Dengan Hormat,', style: small),
                      pw.SizedBox(height: 60),
                      pw.Text(shop, style: bold9.copyWith(decoration: pw.TextDecoration.underline)),
                      pw.Text('Finance', style: small),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (inv.isVoid)
            pw.Center(
              child: pw.Transform.rotateBox(
                angle: 0.5,
                child: pw.Text(
                  'BATAL',
                  style: pw.TextStyle(fontSize: 110, color: PdfColors.red200, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    ),
  );
  return doc.save();
}

/// Simpan PDF ke `folder export/Nota/INV-00247.pdf` dan kembalikan path-nya.
Future<String> saveInvoicePdf(AppDb db, int docId, {String? dir}) async {
  final s = await db.docSummary(docId);
  final folder = dir ?? await db.exportDir('Nota');
  await Directory(folder).create(recursive: true);
  final file = File(p.join(folder, '${s.doc.no.replaceAll('/', '-')}.pdf'));
  await file.writeAsBytes(await buildInvoicePdf(db, docId));
  return file.path;
}

/// Teks pesan WhatsApp untuk customer.
String waMessage(DocSummary s, Map<String, String> settings) {
  final b = StringBuffer()
    ..writeln('Halo ${s.customerName ?? 'Kak'},')
    ..writeln()
    ..writeln('Terima kasih sudah mempercayakan mobil Anda ke ${settings['shop_name']}.')
    ..writeln('${s.isOrder ? 'Pemesanan' : 'Invoice'} ${s.doc.no} — total ${rupiah(s.total)}.');
  if (s.paid > 0 && s.remaining > 0) b.writeln('Sudah dibayar ${rupiah(s.paid)}, sisa ${rupiah(s.remaining)}.');
  if (s.remaining <= 0) b.writeln('Status: LUNAS.');
  b.writeln('Nota PDF terlampir.');
  final review = settings['gmaps_review_url']!;
  if (review.isNotEmpty) {
    b
      ..writeln()
      ..writeln('Bantu kami dengan ulasan di Google Maps ya 🙏')
      ..writeln(review);
  }
  return b.toString().trim();
}

/// wa.me memakai format internasional tanpa "+": 0811… -> 62811…
Uri waUri(String? phone, String text) {
  final n = phone == null || phone.isEmpty ? '' : '62${phone.substring(1)}';
  return Uri.https('wa.me', '/$n', {'text': text});
}
