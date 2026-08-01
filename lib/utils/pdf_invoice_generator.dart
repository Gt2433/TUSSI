import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/order_model.dart';

/// Professional PDF Generator for TUSSI Orders (Always in French)
class PdfInvoiceGenerator {
  static Future<File> generateOrderPdf(Order order) async {
    final pdf = pw.Document(theme: pw.ThemeData.base());
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final priceFormat = NumberFormat('#,##0.##', 'en_US');

    double grandTotal = 0.0;
    int totalCylinders = 0;
    double totalMeters = 0.0;

    for (final f in order.fabrics) {
      final qty = f.sequence.fold(0.0, (s, v) => s + v);
      grandTotal += qty * f.price;
      totalCylinders += f.sequence.length;
      if (f.unit != 'kg') totalMeters += qty;
    }

    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context pdfCtx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Header Banner ───────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1E1E2C'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TUSSI FABRIC SYSTEM',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#F5C842'),
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'FACTURE OFFICIELLE DE COMMANDE DE TISSUS',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Commande N°: #$shortId',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          dateFormat.format(order.createdAt),
                          style: const pw.TextStyle(
                            color: PdfColors.grey400,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ─── Order Parties Info ───────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Expéditeur (Boutique): ${order.senderName}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Destinataire: ${order.receiverName}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    if (order.customerName != null && order.customerName!.isNotEmpty)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Client:',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            order.customerName!,
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#B8860B')),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ─── Fabrics Table Header ─────────────────────
              pw.Text(
                'DÉTAILS DE LA COMMANDE DE TISSUS',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E1E2C')),
              ),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E1E2C')),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                headers: ['#', 'Type de Tissu', 'Rouleaux', 'Quantité', 'Prix Unitaire', 'Prix Total'],
                data: order.fabrics.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final f = entry.value;
                  final qty = f.sequence.fold(0.0, (s, v) => s + v);
                  final fabricTotal = qty * f.price;
                  final unitText = f.unit == 'kg' ? 'kg' : (f.unit == 'yard' ? 'yd' : 'm');

                  return [
                    '${idx + 1}',
                    f.fabricType,
                    '${f.sequence.length} pcs',
                    '${qty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} $unitText',
                    '${priceFormat.format(f.price)} DA',
                    '${priceFormat.format(fabricTotal)} DA',
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 16),

              // ─── Financial & Quantity Summary Box ────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Payment status & details
                  pw.Container(
                    width: 230,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RÉSUMÉ DU PAIEMENT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Divider(color: PdfColors.grey300),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Statut:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                            pw.Text(
                              order.paymentStatus == 'paid'
                                  ? 'PAYÉ'
                                  : (order.paymentStatus == 'partial' ? 'PARTIEL' : 'NON PAYÉ'),
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: order.paymentStatus == 'paid'
                                    ? PdfColors.green700
                                    : (order.paymentStatus == 'partial' ? PdfColors.orange700 : PdfColors.red700),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Montant Payé:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                            pw.Text('${priceFormat.format(order.paidAmount ?? 0)} DA', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Reste à Payer:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                            pw.Text('${priceFormat.format(order.balanceDue)} DA', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: order.balanceDue > 0 ? PdfColors.red700 : PdfColors.green700)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Grand total box
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#1E1E2C'),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Total Tissus: ${order.fabrics.length} types', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9)),
                        pw.SizedBox(height: 2),
                        pw.Text('Total Rouleaux: $totalCylinders pcs', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9)),
                        if (totalMeters > 0) ...[
                          pw.SizedBox(height: 2),
                          pw.Text('Quantité Totale: ${totalMeters.toStringAsFixed(1)} m', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9)),
                        ],
                        pw.Divider(color: PdfColors.grey700),
                        pw.Text('TOTAL GÉNÉRAL:', style: pw.TextStyle(color: PdfColor.fromHex('#F5C842'), fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${priceFormat.format(order.computedTotal)} DA',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ─── Footer ──────────────────────────────────
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('tussi.web.app - Système de Gestion de Tissus TUSSI', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8)),
                  pw.Text('Généré le ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8)),
                ],
              ),
            ],
          );
        },
      ),
    );

    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/Order_Invoice_$shortId.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
