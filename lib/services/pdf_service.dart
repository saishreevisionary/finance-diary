import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/party.dart';
import '../models/payment.dart';

class PdfService {
  static Future<void> generatePartyReport(Party party, List<Payment> payments) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final dateFormat = DateFormat.yMMMd();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Finance Dairy', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                  pw.Text('Party Report', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Party Details Section
            pw.Text('Party Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _infoRow('Party Name', party.name),
                      _infoRow('Collection Type', party.collectionType.name.toUpperCase()),
                      _infoRow('Payment Type', party.paymentType.name.toUpperCase()),
                      _infoRow('Start Date', dateFormat.format(party.startDate)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _infoRow('Principal', currencyFormat.format(party.principal)),
                      _infoRow('Interest %', '${party.interestPercent}%'),
                      if (party.paymentType == PaymentType.due)
                        _infoRow('No of Dues', party.numberOfDues?.toString() ?? 'N/A'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Financial Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  _summaryRow('Total Payable', currencyFormat.format(party.totalPayable), isBold: true),
                  _summaryRow('Total Paid', currencyFormat.format(payments.fold(0.0, (sum, p) => sum + p.amountPaid)), color: PdfColors.green),
                  _summaryRow('Outstanding Balance', currencyFormat.format(party.totalPayable - payments.fold(0.0, (sum, p) => sum + p.amountPaid)), isBold: true, color: PdfColors.red),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Payment History Table
            pw.Text('Payment History', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableCell('Date', isHeader: true),
                    _tableCell('Amount Paid', isHeader: true, align: pw.Alignment.centerRight),
                  ],
                ),
                // Table Rows
                ...payments.map((p) => pw.TableRow(
                  children: [
                    _tableCell(dateFormat.format(p.date)),
                    _tableCell(currencyFormat.format(p.amountPaid), align: pw.Alignment.centerRight),
                  ],
                )),
              ],
            ),
          ];
        },
      ),
    );

    // Share or Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Report_${party.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> generateFilteredHistoryReport(
    List<Party> parties, 
    List<Payment> payments, 
    DateTime start, 
    DateTime end,
    List<CollectionType> types
  ) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final dateFormat = DateFormat.yMMMd();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Finance Dairy', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                  pw.Text('Collection Report', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Period: ${dateFormat.format(start)} - ${dateFormat.format(end)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Types: ${types.map((t) => t.name.toUpperCase()).join(', ')}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableCell('Date', isHeader: true),
                    _tableCell('Party Name', isHeader: true),
                    _tableCell('Type', isHeader: true),
                    _tableCell('Amount', isHeader: true, align: pw.Alignment.centerRight),
                  ],
                ),
                ...payments.map((p) {
                  final party = parties.firstWhere((pt) => pt.id == p.partyId, orElse: () => Party.create(name: 'Unknown', principal: 0, interestPercent: 0, collectionType: CollectionType.daily, paymentType: PaymentType.due));
                  return pw.TableRow(
                    children: [
                      _tableCell(dateFormat.format(p.date)),
                      _tableCell(party.name),
                      _tableCell(party.collectionType.name.toUpperCase()),
                      _tableCell(currencyFormat.format(p.amountPaid), align: pw.Alignment.centerRight),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Collected: ${currencyFormat.format(payments.fold(0.0, (sum, p) => sum + p.amountPaid))}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Collection_Report_${DateFormat('yyyyMMdd').format(start)}.pdf',
    );
  }

  static Future<void> generateUnpaidDuesReport(List<Party> parties, Map<String, double> paidAmounts) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    
    final unpaidParties = parties.where((p) {
      final paid = paidAmounts[p.id] ?? 0.0;
      return (p.totalPayable - paid) > 0.01;
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Urgent: Unpaid Dues Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableCell('Party Name', isHeader: true),
                    _tableCell('Type', isHeader: true),
                    _tableCell('Total Payable', isHeader: true, align: pw.Alignment.centerRight),
                    _tableCell('Outstanding', isHeader: true, align: pw.Alignment.centerRight),
                  ],
                ),
                ...unpaidParties.map((p) {
                  final outstanding = p.totalPayable - (paidAmounts[p.id] ?? 0.0);
                  return pw.TableRow(
                    children: [
                      _tableCell(p.name),
                      _tableCell(p.collectionType.name.toUpperCase()),
                      _tableCell(p.totalPayable.toStringAsFixed(2), align: pw.Alignment.centerRight),
                      _tableCell(currencyFormat.format(outstanding), align: pw.Alignment.centerRight, color: PdfColors.red),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Unpaid_Dues_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false, pw.Alignment align = pw.Alignment.centerLeft, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ),
    );
  }
}
