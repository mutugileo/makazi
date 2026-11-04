import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../billing/billing_engine.dart';
import '../billing/billing_models.dart';
import '../models/payment_receipt.dart';
import '../../features/billing/presentation/state/tenant_account_state.dart';

typedef PdfSharer =
    Future<bool> Function({required Uint8List bytes, required String filename});

abstract final class PdfDocumentService {
  static PdfSharer sharePdf = Printing.sharePdf;
  static bool useGoogleFonts = true;

  /// Generates a professional PDF receipt for a payment.
  static Future<Uint8List> generateReceiptPdf({
    required PaymentReceipt receipt,
    Company? company,
  }) async {
    final doc = pw.Document(
      title: 'Receipt ${receipt.receiptNumber}',
      author: company?.name ?? 'Makazi',
    );

    final brandPrimary = company != null
        ? PdfColor.fromInt(company.settings.theme.primaryColor.toARGB32())
        : const PdfColor.fromInt(0xFF0D382B);

    pw.Font fontRegular = pw.Font.helvetica();
    pw.Font fontBold = pw.Font.helveticaBold();
    if (useGoogleFonts) {
      try {
        fontRegular = await PdfGoogleFonts.lexendRegular();
        fontBold = await PdfGoogleFonts.lexendBold();
      } catch (_) {
        fontRegular = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: brandPrimary,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          company?.name ?? 'Makazi Property Management',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'OFFICIAL PAYMENT RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: const PdfColor(1, 1, 1, 0.8),
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor(1, 1, 1, 0.15),
                        borderRadius: pw.BorderRadius.circular(20),
                        border: pw.Border.all(
                          color: const PdfColor(1, 1, 1, 0.3),
                        ),
                      ),
                      child: pw.Text(
                        'PAID',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Receipt number and Date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RECEIPT NUMBER',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        receipt.receiptNumber,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'DATE & TIME',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        receipt.dateTimeLabel,
                        style: pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Tenant & Unit Information
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RECEIVED FROM',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          receipt.tenantName,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'UNIT / PROPERTY',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          receipt.unit,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Payment Details Table
              pw.Text(
                'PAYMENT PARTICULARS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.1,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder(
                  bottom: const pw.BorderSide(color: PdfColors.grey300),
                  horizontalInside: const pw.BorderSide(
                    color: PdfColors.grey200,
                  ),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _th('Description'),
                      _th('Payment Method'),
                      _th('Reference'),
                      _th('Amount (KES)', alignRight: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _td(receipt.forDescription),
                      _td(receipt.methodLabel),
                      _td(receipt.reference),
                      _td(
                        formatKes(receipt.amount),
                        alignRight: true,
                        bold: true,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Total Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Paid:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.Text(
                          formatKes(receipt.amount),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Verification Footer
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Computer-generated receipt - Issued via Makazi Property Management',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Official electronic record for tenant account verification.',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey500,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'STATUS: VERIFIED',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Generates a professional statement PDF.
  static Future<Uint8List> generateStatementPdf({
    required TenantAccountState account,
  }) async {
    final doc = pw.Document(
      title: 'Statement - ${account.tenant.name}',
      author: account.company.name,
    );

    final brandPrimary = PdfColor.fromInt(
      account.company.settings.theme.primaryColor.toARGB32(),
    );

    pw.Font fontRegular = pw.Font.helvetica();
    pw.Font fontBold = pw.Font.helveticaBold();
    if (useGoogleFonts) {
      try {
        fontRegular = await PdfGoogleFonts.lexendRegular();
        fontBold = await PdfGoogleFonts.lexendBold();
      } catch (_) {
        fontRegular = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: brandPrimary,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      account.company.name,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'TENANT ACCOUNT STATEMENT',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor(1, 1, 1, 0.8),
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'As of ${account.seed.asOf}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final totalBilled = account.bills.fold(
            0,
            (sum, b) => sum + b.totalDue,
          );
          final totalPaid = account.bills.fold(
            0,
            (sum, b) => sum + b.amountPaid,
          );
          final currentBalance = account.balance;

          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Tenant: ${account.tenant.name}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Unit: ${account.unitTitle}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Balance: ${formatKes(currentBalance)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: currentBalance > 0
                            ? PdfColors.red700
                            : PdfColors.green700,
                      ),
                    ),
                    pw.Text(
                      currentBalance <= 0 ? 'All settled' : 'Outstanding',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              children: [
                _summaryBox('Total Billed', formatKes(totalBilled)),
                pw.SizedBox(width: 12),
                _summaryBox('Total Paid', formatKes(totalPaid)),
                pw.SizedBox(width: 12),
                _summaryBox(
                  'Outstanding',
                  formatKes(currentBalance > 0 ? currentBalance : 0),
                  textColor: currentBalance > 0
                      ? PdfColors.red700
                      : PdfColors.green700,
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'PAYMENT HISTORY',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: const pw.BorderSide(color: PdfColors.grey200),
                bottom: const pw.BorderSide(color: PdfColors.grey300),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('Date'),
                    _th('Receipt #'),
                    _th('Method'),
                    _th('Amount', alignRight: true),
                  ],
                ),
                ...account.receipts.map(
                  (r) => pw.TableRow(
                    children: [
                      _td(r.dateTimeLabel),
                      _td(r.receiptNumber),
                      _td(r.methodLabel),
                      _td(formatKes(r.amount), alignRight: true, bold: true),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _summaryBox(
    String title,
    String value, {
    PdfColor? textColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: textColor ?? PdfColors.grey900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _th(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _td(
    String text, {
    bool alignRight = false,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
      ),
    );
  }

  static Future<bool> downloadReceipt({
    required PaymentReceipt receipt,
    Company? company,
  }) async {
    final bytes = await generateReceiptPdf(receipt: receipt, company: company);
    return await sharePdf(
      bytes: bytes,
      filename: 'Receipt-${receipt.receiptNumber}.pdf',
    );
  }

  static Future<bool> downloadStatement({
    required TenantAccountState account,
  }) async {
    final bytes = await generateStatementPdf(account: account);
    return await sharePdf(
      bytes: bytes,
      filename: 'Statement-${account.tenant.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
