import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'db.dart';
import 'money.dart';

const _blue = PdfColor.fromInt(0xFF3B6CB7);
const _navy = PdfColor.fromInt(0xFF1E2A44);
const _head = PdfColor.fromInt(0xFF2F3B52);
const _cell = PdfColor.fromInt(0xFFE8EAEE);
const _grey = PdfColor.fromInt(0xFF555555);

/// Layout mengikuti contoh nota client (docs/contoh-invoice-INV00246.pdf).
Future<Uint8List> buildInvoicePdf(AppDb db, Invoice inv) async {
  final lines = await (db.select(db.invoiceLines)..where((l) => l.invoiceId.equals(inv.id))).get();
  final cust = inv.customerId == null
      ? null
      : await (db.select(db.customers)..where((c) => c.id.equals(inv.customerId!))).getSingle();
  final s = {for (final r in await db.select(db.settings).get()) r.key: r.value};
  final logoPath = s['logo_path'] ?? '';
  final logo = logoPath.isNotEmpty && File(logoPath).existsSync()
      ? pw.MemoryImage(File(logoPath).readAsBytesSync())
      : null;
  final shop = s['shop_name'] ?? 'STAR GARAGE';
  final date = DateFormat('dd/MM/yyyy').format(inv.at);

  pw.Widget section(String title, List<pw.Widget> body) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _navy, fontSize: 10)),
          pw.Divider(color: _navy, thickness: 2, height: 14),
          ...body,
        ],
      );
  pw.Widget muted(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 3),
      child: pw.Text(t, style: const pw.TextStyle(color: _grey, fontSize: 9)));
  pw.Widget totalRow(String k, String v, {bool big = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(k, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 13 : 10)),
          pw.Text(v, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 13 : 10)),
        ]),
      );

  final doc = pw.Document(title: inv.no, author: shop);
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    build: (_) => pw.Stack(children: [
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(
            width: 160,
            height: 70,
            child: logo != null
                ? pw.Image(logo, fit: pw.BoxFit.contain, alignment: pw.Alignment.centerLeft)
                : pw.Text(shop, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Spacer(),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Invoice', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _blue)),
            pw.SizedBox(height: 10),
            pw.Table(columnWidths: {0: const pw.FixedColumnWidth(90), 1: const pw.FixedColumnWidth(70)}, children: [
              for (final (k, v) in [('Nomor', inv.no), ('Tanggal', date), ('Pembayaran', inv.payMethod)])
                pw.TableRow(children: [
                  pw.Text(k, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(v, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9)),
                ]),
            ]),
          ]),
        ]),
        pw.SizedBox(height: 30),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: section('Informasi Perusahaan', [
              pw.Text(shop, style: pw.TextStyle(color: _blue, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if ((s['shop_address'] ?? '').isNotEmpty) muted(s['shop_address']!),
              if ((s['shop_phone'] ?? '').isNotEmpty) muted('Telp: ${s['shop_phone']}'),
              if ((s['shop_email'] ?? '').isNotEmpty) muted('Email: ${s['shop_email']}'),
            ]),
          ),
          pw.SizedBox(width: 40),
          pw.Expanded(
            child: section('Tagihan Kepada', [
              pw.Text(cust?.name ?? 'UMUM', style: pw.TextStyle(color: _blue, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              if (cust != null) muted('Telp: ${cust.phone}'),
              if ('${inv.car} ${inv.plate}'.trim().isNotEmpty) muted('Mobil: ${[inv.car, inv.plate].where((x) => x.isNotEmpty).join(' / ')}'),
            ]),
          ),
        ]),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: ['Produk', 'Deskripsi', 'Kuantitas', 'Harga', 'Diskon', 'Jumlah'],
          data: [
            for (final l in lines)
              [l.name, l.description, '${l.qty}', rp(l.price), '${l.discountPct}%', rp(l.total)],
          ],
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: _head),
          cellStyle: const pw.TextStyle(fontSize: 9, color: _grey),
          cellDecoration: (_, __, ___) => const pw.BoxDecoration(color: _cell),
          border: pw.TableBorder.symmetric(inside: const pw.BorderSide(color: PdfColors.white, width: 2)),
          cellPadding: const pw.EdgeInsets.all(6),
          columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(3)},
          cellAlignments: {2: pw.Alignment.center, 3: pw.Alignment.centerRight, 4: pw.Alignment.center, 5: pw.Alignment.centerRight},
          headerAlignments: {2: pw.Alignment.center, 3: pw.Alignment.centerRight, 4: pw.Alignment.center, 5: pw.Alignment.centerRight},
        ),
        pw.SizedBox(height: 16),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            flex: 5,
            child: section('Pesan', [
              for (final line in (s['invoice_note'] ?? '').split('\n'))
                pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Text(line, style: const pw.TextStyle(fontSize: 9))),
              pw.Text('Terbilang', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(terbilang(inv.total), style: const pw.TextStyle(fontSize: 9)),
            ]),
          ),
          pw.SizedBox(width: 30),
          pw.Expanded(
            flex: 4,
            child: pw.Column(children: [
              totalRow('Subtotal', 'Rp ${rp(inv.subtotal)}'),
              if (inv.ppn) totalRow('PPN $ppnRate%', 'Rp ${rp(inv.total - inv.subtotal)}'),
              totalRow('Total', 'Rp ${rp(inv.total)}', big: true),
              totalRow('Status', 'LUNAS'),
            ]),
          ),
        ]),
        pw.SizedBox(height: 30),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 160,
            child: pw.Column(children: [
              pw.Text('Dengan Hormat,', style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 60),
              pw.Text(shop, style: const pw.TextStyle(fontSize: 9, decoration: pw.TextDecoration.underline)),
              pw.Text('Finance', style: const pw.TextStyle(fontSize: 9)),
            ]),
          ),
        ),
      ]),
      if (inv.isVoid)
        pw.Center(
          child: pw.Transform.rotateBox(
            angle: 0.5,
            child: pw.Text('VOID', style: pw.TextStyle(fontSize: 120, color: PdfColors.red200, fontWeight: pw.FontWeight.bold)),
          ),
        ),
    ]),
  ));
  return doc.save();
}
