import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class InvoicePDF {
  static Future<Uint8List> generate({
    required Map<String, dynamic> invoice,
    required List<dynamic> items,
  }) async {
    final pdf = pw.Document();

    // Load default font
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    // Format currency
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Format volume
    String formatVolume(dynamic volume) {
      if (volume == null) return '0';
      double vol = 0.0;
      if (volume is String) {
        vol = double.tryParse(volume) ?? 0.0;
      } else if (volume is num) {
        vol = volume.toDouble();
      }
      return (vol / 1000000).toStringAsFixed(2); // Convert to m³
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                height: 80,
                width: 200,
                child: pw.Center(
                  child: pw.Text(
                    'LOGO',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                    ),
                  ),
                  pw.Text(
                    invoice['invoice_number'],
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Invoice Info
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Bill To
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bill To:',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    invoice['supplier_name'] ?? '',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                  pw.Text(
                    invoice['project_location'] ?? '',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
              // Dates
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'Invoice Date: ',
                        style: pw.TextStyle(font: fontBold, fontSize: 12),
                      ),
                      pw.Text(
                        DateFormat('dd MMM yyyy').format(DateTime.parse(invoice['invoice_date'])),
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Due Date: ',
                        style: pw.TextStyle(font: fontBold, fontSize: 12),
                      ),
                      pw.Text(
                        DateFormat('dd MMM yyyy').format(DateTime.parse(invoice['due_date'])),
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Period: ',
                        style: pw.TextStyle(font: fontBold, fontSize: 12),
                      ),
                      pw.Text(
                        '${DateFormat('dd MMM yyyy').format(DateTime.parse(invoice['start_period']))} - '
                        '${DateFormat('dd MMM yyyy').format(DateTime.parse(invoice['end_period']))}',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Items Table
          pw.Table.fromTextArray(
            context: context,
            border: null,
            headerStyle: pw.TextStyle(
              font: fontBold,
              fontSize: 12,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellStyle: pw.TextStyle(
              font: font,
              fontSize: 12,
            ),
            columnWidths: {
              0: pw.FlexColumnWidth(3), // Material
              1: pw.FlexColumnWidth(2), // Volume
              2: pw.FlexColumnWidth(1), // Unit
              3: pw.FlexColumnWidth(2), // Price
              4: pw.FlexColumnWidth(2), // Total
            },
            headers: [
              'Material',
              'Volume',
              'Unit',
              'Price per Unit',
              'Total',
            ],
            data: items.map((item) {
              return [
                item['material_name'] ?? '',
                formatVolume(item['total_volume']),
                'm³',
                formatCurrency.format(num.parse(item['unit_price'].toString())),
                formatCurrency.format(num.parse(item['total_price'].toString())),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),

          // Total
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 200,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      color: PdfColors.grey300,
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total:',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                            ),
                          ),
                          pw.Text(
                            formatCurrency.format(num.parse(invoice['total_amount'].toString())),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 40),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    height: 60,
                    width: 120,
                    child: pw.Center(
                      child: pw.Text(
                        'SIGNATURE',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ),
                  ),
                  pw.Text(
                    'Authorized Signature',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
