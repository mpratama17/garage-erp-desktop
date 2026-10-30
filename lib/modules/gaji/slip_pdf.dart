import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format.dart';
import '../../db/database.dart';
import '../penjualan/invoice_pdf.dart' show logoBox, pdfLogo;
import 'gaji_repo.dart';

const _blue = PdfColor.fromInt(0xFF3B6CB7);
const _navy = PdfColor.fromInt(0xFF1E2A44);
const _grey = PdfColor.fromInt(0xFF555555);

/// Slip gaji A4: ringkasan komponen + terbilang + satu kolom tanda tangan (Finance), sesuai permintaan
/// client (tanpa kolom tanda terima karyawan). Layout mengikuti gaya nota (invoice_pdf.dart).
Future<Uint8List> buildSlipPdf(AppDb db, Slip s) async {
  final set = await db.allSettings();
  final logo = pdfLogo(set['logo_path']!);
  final box = logoBox(set['logo_scale']!);
  final shop = set['shop_name']!;

  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf')),
    bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf')),
  );
  const small = pw.TextStyle(fontSize: 9);
  final bold9 = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

  const border = pw.TableBorder(
    top: pw.BorderSide(color: PdfColors.grey400),
    bottom: pw.BorderSide(color: PdfColors.grey400),
    left: pw.BorderSide(color: PdfColors.grey400),
    right: pw.BorderSide(color: PdfColors.grey400),
    horizontalInside: pw.BorderSide(color: PdfColors.grey300),
    verticalInside: pw.BorderSide(color: PdfColors.grey300),
  );
  pw.Widget cell(String t, {bool bold = false, bool right = false, PdfColor? color, double size = 10}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: pw.Text(
      t,
      textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : null, color: color),
    ),
  );

  final rows = [
    ('Gaji pokok', s.baseSalary, false),
    ('Tunjangan makan', s.mealAllowance, false),
    if (s.incentive != 0 || s.employee.role != 'sales') ('Insentif pekerjaan', s.incentive, false),
    if (s.employee.role == 'sales' || s.commission != 0) ('Tunjangan kerja', s.commission, false),
    if (s.overtime != 0) ('Lembur', s.overtime, false),
    if (s.bonus != 0) ('Bonus / THR', s.bonus, false),
    if (s.deduction != 0) ('Potongan', s.deduction, true),
  ];

  final doc = pw.Document(title: 'Slip ${s.employee.name} ${periodLabel(s.start, s.end)}', author: shop, theme: theme);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: box.x,
                height: box.y,
                child: logo != null
                    ? pw.Image(logo, fit: pw.BoxFit.contain, alignment: pw.Alignment.centerLeft)
                    : pw.Text(shop, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Slip Gaji',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _blue),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Periode ${periodLabel(s.start, s.end)}', style: small),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          // Identitas karyawan.
          pw.Table(
            border: border,
            columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(3)},
            children: [
              for (final (k, v) in [
                ('Nama', s.employee.name),
                ('Jabatan', s.employee.role == 'sales' ? 'Sales' : 'Teknisi'),
                ('Periode', periodLabel(s.start, s.end)),
              ])
                pw.TableRow(
                  children: [
                    cell(k, color: _grey),
                    cell(v, bold: true),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 16),
          // Rincian komponen gaji.
          pw.Table(
            border: border,
            columnWidths: {
              0: const pw.FixedColumnWidth(32),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _navy),
                children: [
                  cell('No', bold: true, color: PdfColors.white),
                  cell('Komponen', bold: true, color: PdfColors.white),
                  cell('Jumlah', bold: true, right: true, color: PdfColors.white),
                ],
              ),
              for (final (i, (k, v, minus)) in rows.indexed)
                pw.TableRow(
                  children: [cell('${i + 1}'), cell(k), cell(minus ? '− ${rupiah(v)}' : rupiah(v), right: true)],
                ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  cell(''),
                  cell('Total diterima', bold: true, size: 12),
                  cell(rupiah(s.total), bold: true, right: true, size: 12),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Terbilang', style: small),
          pw.Text(terbilang(s.total), style: small),
          if (s.saved?.note.isNotEmpty ?? false) ...[
            pw.SizedBox(height: 8),
            pw.Text('Catatan: ${s.saved!.note}', style: small),
          ],
          pw.SizedBox(height: 50),
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
    ),
  );
  return doc.save();
}

/// Simpan PDF ke `folder export/Slip/NamaKaryawan-periode.pdf` dan kembalikan path-nya.
Future<String> saveSlipPdf(AppDb db, Slip s) async {
  final folder = await db.exportDir('Slip');
  final name = '${s.employee.name}-${s.start.toIso8601String().substring(0, 10)}'.replaceAll(RegExp(r'[\\/]'), '-');
  final file = File(p.join(folder, '$name.pdf'));
  await file.writeAsBytes(await buildSlipPdf(db, s));
  return file.path;
}
