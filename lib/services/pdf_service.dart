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

  static Future<void> generateLoanStatementGridReport(
    List<Party> parties,
    List<Payment> payments,
    Map<String, double> paidAmounts,
  ) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    final totalPrincipal = parties.fold(0.0, (sum, p) => sum + p.principal);
    final totalPayable = parties.fold(0.0, (sum, p) => sum + p.totalPayable);
    final totalCollected = parties.fold(0.0, (sum, p) => sum + (paidAmounts[p.id] ?? 0.0));
    final restAmount = totalPayable - totalCollected;

    final debtUParties = parties.where((p) => p.isDebtU).toList();
    final debtUSum = debtUParties.fold(0.0, (sum, p) => sum + p.principal);
    final completedCount = parties.where((p) => (p.totalPayable - (paidAmounts[p.id] ?? 0.0)) <= 0.01).length;
    final completePct = parties.isNotEmpty ? ((completedCount / parties.length) * 100).toInt() : 0;
    final debtPct = parties.isNotEmpty ? ((debtUParties.length / parties.length) * 100).toInt() : 0;

    // Top Creditors (sorted by principal desc)
    final topCreditors = List<Party>.from(parties)
      ..sort((a, b) => b.principal.compareTo(a.principal));
    final topCreditorsList = topCreditors.take(15).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ---------------- TOP HEADER SECTION (EXCEL EXACT) ----------------
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT SUMMARY BOXES (Yellow Theme)
                  pw.Container(
                    width: 240,
                    decoration: pw.BoxDecoration(
                      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                      color: PdfColors.yellow300,
                    ),
                    child: pw.Column(
                      children: [
                        _headerSummaryRow('MAIN BALANCE', currencyFormat.format(totalPrincipal), isTop: true),
                        _headerSummaryRow('ROLLING LOAN AMOUNT', currencyFormat.format(totalPayable)),
                        _headerSummaryRow('REST OF AMOUNT', '${currencyFormat.format(restAmount)}   -${currencyFormat.format(debtUSum)}'),
                      ],
                    ),
                  ),

                  // CENTER TITLE BANNER & DEU COUNT
                  pw.Column(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF001F54), // Dark Navy
                        ),
                        child: pw.Text(
                          'P.D LOAN STATEMENT',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.red,
                        ),
                        child: pw.Text(
                          'Deu -${debtUParties.length}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // RIGHT TOP CREDITORS BREAKDOWN (Excel Top Right Box)
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      children: [
                        // Stats summary bar
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          color: PdfColors.green100,
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('TOTAL: ${currencyFormat.format(totalCollected)}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.Text('COMPLETE: $completePct%', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                              pw.Text('DEBT: $debtPct%', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        // Mini Creditor Table
                        pw.Table(
                          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(color: PdfColors.orange200),
                              children: [
                                _cell('PARTY NAME', isHeader: true, fontSize: 6),
                                _cell('AMOUNT', isHeader: true, align: pw.Alignment.centerRight, fontSize: 6),
                                _cell('INST+BIMA', isHeader: true, align: pw.Alignment.centerRight, fontSize: 6),
                                _cell('GT', isHeader: true, align: pw.Alignment.centerRight, fontSize: 6),
                              ],
                            ),
                            ...topCreditorsList.take(4).map((c) => pw.TableRow(
                              decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                              children: [
                                _cell(c.name, fontSize: 6),
                                _cell(c.principal.toInt().toString(), align: pw.Alignment.centerRight, fontSize: 6),
                                _cell('${c.duePerPeriod.toInt()}+${c.bima.toInt()}', align: pw.Alignment.centerRight, fontSize: 6),
                                _cell(c.gtPerPeriod.toInt().toString(), align: pw.Alignment.centerRight, fontSize: 6, isBold: true),
                              ],
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // ---------------- MAIN EXCEL MATRIX GRID TABLE ----------------
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(22),  // SL NO
                    1: pw.FixedColumnWidth(48),  // DATE
                    2: pw.FixedColumnWidth(85),  // NAME
                    3: pw.FixedColumnWidth(45),  // WEEKLY PAYMENT
                    4: pw.FixedColumnWidth(50),  // MOBILE NO
                    5: pw.FixedColumnWidth(42),  // AMOUNT
                    6: pw.FixedColumnWidth(30),  // BIMA
                    7: pw.FixedColumnWidth(32),  // 1st W
                    8: pw.FixedColumnWidth(32),  // 2nd W
                    9: pw.FixedColumnWidth(32),  // 3rd W
                    10: pw.FixedColumnWidth(32), // 4th W
                    11: pw.FixedColumnWidth(32), // 5th W
                    12: pw.FixedColumnWidth(32), // 6th W
                    13: pw.FixedColumnWidth(32), // 7th W
                    14: pw.FixedColumnWidth(32), // 8th W
                    15: pw.FixedColumnWidth(32), // 9th W
                    16: pw.FixedColumnWidth(32), // 10th W
                    17: pw.FixedColumnWidth(32), // 11th W
                    18: pw.FixedColumnWidth(32), // 12th W
                    19: pw.FixedColumnWidth(45), // TOTAL AMOUNT
                  },
                  children: [
                    // Column Headers (Excel Yellow / Grey Header)
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.yellow400),
                      children: [
                        _cell('SL NO', isHeader: true),
                        _cell('DATE', isHeader: true),
                        _cell('NAME', isHeader: true),
                        _cell('WEEKLY PAYMENT', isHeader: true, align: pw.Alignment.center),
                        _cell('MOBILE NO', isHeader: true),
                        _cell('AMOUNT', isHeader: true, align: pw.Alignment.centerRight),
                        _cell('BIMA', isHeader: true, align: pw.Alignment.centerRight),
                        _cell('1st WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('2nd WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('3rd WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('4th WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('5th WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('6th WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('7th WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('8th WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('9th WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('10th WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('11th WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('12th WEEK', isHeader: true, align: pw.Alignment.center),
                        _cell('TOTAL AMOUNT', isHeader: true, align: pw.Alignment.centerRight),
                      ],
                    ),

                    // Party Data Rows
                    ...List.generate(parties.length, (idx) {
                      final p = parties[idx];
                      final totalPaid = paidAmounts[p.id] ?? 0.0;
                      final isComplete = (p.totalPayable - totalPaid) <= 0.01;

                      // Map payments per week
                      final weekMap = <int, double>{};
                      final partyPayments = payments.where((pm) => pm.partyId == p.id).toList();
                      for (var pm in partyPayments) {
                        final days = pm.date.difference(p.startDate).inDays;
                        final wIdx = days < 0 ? 1 : (days ~/ 7) + 1;
                        if (wIdx >= 1 && wIdx <= 12) {
                          weekMap[wIdx] = (weekMap[wIdx] ?? 0.0) + pm.amountPaid;
                        }
                      }

                      // Fallback fill based on total paid if individual week payments aren't explicitly dated
                      double remPaid = totalPaid;
                      final due = p.duePerPeriod;
                      for (int w = 1; w <= 12; w++) {
                        if (!weekMap.containsKey(w) && remPaid > 0 && due > 0) {
                          double wVal = remPaid >= due ? due : remPaid;
                          weekMap[w] = wVal;
                          remPaid -= wVal;
                        }
                      }

                      // Calculate row total sum of weeks
                      final rowTotal = weekMap.values.fold(0.0, (sum, v) => sum + v);

                      // Row background color matching Excel:
                      // Debt-U -> Yellow, Complete -> Soft Green, Normal -> Alternating white/grey
                      PdfColor rowBg = PdfColors.white;
                      if (p.isDebtU) {
                        rowBg = PdfColors.yellow100;
                      } else if (isComplete) {
                        rowBg = PdfColors.green100;
                      } else if (idx % 2 == 1) {
                        rowBg = PdfColors.grey100;
                      }

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: rowBg),
                        children: [
                          _cell('${idx + 1}', align: pw.Alignment.center),
                          _cell(dateFormat.format(p.startDate)),
                          _cell(p.name, textColor: p.isDebtU ? PdfColors.purple900 : PdfColors.black, isBold: p.isDebtU),
                          _cell(p.duePerPeriod.toInt().toString(), align: pw.Alignment.centerRight, textColor: PdfColors.purple700),
                          _cell(p.mobileNo ?? '', textColor: PdfColors.purple700),
                          _cell(p.principal.toInt().toString(), align: pw.Alignment.centerRight, textColor: PdfColors.purple700),
                          _cell(p.bima > 0 ? p.bima.toInt().toString() : '', align: pw.Alignment.centerRight),
                          for (int w = 1; w <= 12; w++) ...[
                            _cell(
                              weekMap[w] != null && weekMap[w]! > 0 ? weekMap[w]!.toInt().toString() : '',
                              align: pw.Alignment.center,
                              textColor: PdfColors.blue900,
                            ),
                          ],
                          _cell(
                            rowTotal > 0 ? rowTotal.toInt().toString() : '0',
                            align: pw.Alignment.centerRight,
                            isBold: true,
                            textColor: isComplete ? PdfColors.green900 : PdfColors.black,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'P_D_Loan_Statement_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _headerSummaryRow(String label, String value, {bool isTop = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        border: isTop ? null : const pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          pw.Text(value, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        ],
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    pw.Alignment align = pw.Alignment.centerLeft,
    PdfColor? textColor,
    bool isBold = false,
    double fontSize = 6.5,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          maxLines: 1,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: textColor ?? (isHeader ? PdfColors.black : PdfColors.grey900),
          ),
        ),
      ),
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
