import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format.dart';
import '../../db/database.dart';
import 'gaji_repo.dart';

const _blue = PdfColor.fromInt(0xFF3B6CB7);
const _navy = PdfColor.fromInt(0xFF1E2A44);
const _grey = PdfColor.fromInt(0xFF555555);

/// Slip gaji A4: ringkasan komponen + terbilang + satu kolom tanda tangan (Finance), sesuai permintaan
/// client (tanpa kolom tanda terima karyawan). Layout mengikuti gaya nota (invoice_pdf.dart).
Future<Uint8List> buildSlipPdf(AppDb db, Slip s) async {
  final set = await db.allSettings();
  final logoFile = File(set['logo_path']!);
  final logo = set['logo_path']!.isNotEmpty && logoFile.existsSync()
      ? pw.MemoryImage(logoFile.readAsBytesSync())
      : null;
  final shop = set['shop_name']!;

  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf')),
    bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf')),
  );
  const small = pw.TextStyle(fontSize: 9);
  final bold9 = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

  pw.Widget muted(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 3),
    child: pw.Text(t, style: const pw.TextStyle(color: _grey, fontSize: 9)),
  );
  pw.Widget totalRow(String k, String v, {bool big = false, bool minus = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          k,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 13 : 10),
        ),
        pw.Text(
          minus ? '− $v' : v,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: big ? 13 : 10),
        ),
      ],
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
                    'Slip Gaji',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _blue),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Periode ${periodLabel(s.start, s.end)}', style: small),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            s.employee.name,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _navy),
          ),
          muted(s.employee.role == 'sales' ? 'Sales' : 'Teknisi'),
          pw.SizedBox(height: 20),
          pw.Divider(color: _navy, thickness: 2),
          pw.SizedBox(height: 8),
          for (final (k, v, minus) in rows) totalRow(k, rupiah(v), minus: minus),
          pw.Divider(color: PdfColors.grey300),
          totalRow('Total diterima', rupiah(s.total), big: true),
          pw.SizedBox(height: 4),
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
