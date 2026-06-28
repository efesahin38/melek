import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/stundenzettel_model.dart';

class PdfService {
  static Future<Uint8List> generateStundenzettel(
    StundenzettelModel sz,
    String employeeName,
  ) async {
    final pdf = pw.Document();

    final adminSigBytes = sz.adminSignature != null
        ? base64Decode(sz.adminSignature!)
        : null;
    final empSigBytes = sz.employeeSignature != null
        ? base64Decode(sz.employeeSignature!)
        : null;

    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MELEK',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFFC9A227),
                      ),
                    ),
                    pw.Text(
                      'Arbeitszeitnachweis',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFC9A227),
                    ),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    '${months[sz.month - 1]} ${sz.year}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: const PdfColor.fromInt(0xFFC9A227)),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) => [
          // Employee Info
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Mitarbeiter',
                          style: pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(employeeName,
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _infoRow('Arbeitstage', '${sz.totalDays ?? 0} Tage'),
                    pw.SizedBox(height: 2),
                    _infoRow(
                        'Gesamtstunden',
                        '${(sz.totalHours ?? 0).toStringAsFixed(1)} Std.'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Work entries table
          pw.Text(
            'Arbeitsstunden im Detail',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              'Datum',
              'Arbeitsbeginn',
              'Arbeitsende',
              'Pause',
              'Stunden',
              'Notiz',
            ],
            data: sz.workEntries.map((e) {
              final sParts = e.startTime.split(':');
              final eParts = e.endTime.split(':');
              int breakMins = 0;
              if (sParts.length == 2 && eParts.length == 2) {
                final sMins = int.parse(sParts[0]) * 60 + int.parse(sParts[1]);
                final eMins = int.parse(eParts[0]) * 60 + int.parse(eParts[1]);
                final workedMins = (e.hours * 60).round();
                breakMins = (eMins - sMins) - workedMins;
                if (breakMins < 0) breakMins = 0;
              }
              
              return [
                DateFormat('dd.MM.yyyy').format(e.date),
                e.startTime,
                e.endTime,
                '${breakMins} Min.',
                '${e.hours.toStringAsFixed(1)} Std.',
                e.note ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1A1A38),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            rowDecoration: const pw.BoxDecoration(),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
            ),
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(65),
              1: const pw.FixedColumnWidth(70),
              2: const pw.FixedColumnWidth(70),
              3: const pw.FixedColumnWidth(55),
              4: const pw.FixedColumnWidth(55),
              5: const pw.FlexColumnWidth(),
            },
          ),
          pw.SizedBox(height: 12),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF3CD),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFC9A227), width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Gesamte Arbeitstage',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      '${sz.totalDays ?? 0} Tage',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Gesamte Arbeitsstunden',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      '${(sz.totalHours ?? 0).toStringAsFixed(1)} Std.',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Signatures
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Admin / Arbeitgeber',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    if (adminSigBytes != null) ...[
                      pw.Image(
                        pw.MemoryImage(adminSigBytes),
                        height: 60,
                      ),
                    ] else ...[
                      pw.Container(
                        height: 60,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(color: PdfColors.black)),
                        ),
                      ),
                    ],
                    if (sz.adminSignedAt != null)
                      pw.Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(sz.adminSignedAt!),
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text('Unterschrift',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Mitarbeiter',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    if (empSigBytes != null) ...[
                      pw.Image(
                        pw.MemoryImage(empSigBytes),
                        height: 60,
                      ),
                    ] else ...[
                      pw.Container(
                        height: 60,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(color: PdfColors.black)),
                        ),
                      ),
                    ],
                    if (sz.employeeSignedAt != null)
                      pw.Text(
                        DateFormat('dd.MM.yyyy HH:mm')
                            .format(sz.employeeSignedAt!),
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text('Unterschrift',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Dieses Dokument wurde elektronisch erstellt – MELEK v1.0',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(width: 8),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
