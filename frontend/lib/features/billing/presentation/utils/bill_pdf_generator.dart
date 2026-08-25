// lib/features/billing/utils/bill_pdf_generator.dart
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../domain/entities/bill_entity.dart';
import '../../../invoice_template/domain/entities/invoice_template_entity.dart';

/// Generates a polished, branded invoice PDF for a bill.
///
/// Visual language (kept in one place so it's easy to re-theme):
/// - Deep purple ribbons for section labels
/// - Light-lavender surfaces for grouped info
/// - A solid purple "NET PAYABLE" bar to anchor the eye on the total
class BillPdfGenerator {
  static final PdfColor _purple = PdfColor.fromInt(0xFF4B2E96);
  static final PdfColor _purpleLight = PdfColor.fromInt(0xFFF3EFFC);
  static final PdfColor _purpleBorder = PdfColor.fromInt(0xFFDCD2F5);

  static Future<Uint8List> generate(
    BillEntity bill, {
    InvoiceTemplateEntity? template,
  }) async {
    final doc = pw.Document();
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    final t = template ?? _getDefaultTemplate();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 20),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(bill, t, fmt),
            pw.SizedBox(height: 14),
            pw.Divider(thickness: 1, color: _purpleBorder),
            pw.SizedBox(height: 18),

            _ribbon('Boat Information'),
            pw.SizedBox(height: 8),
            _buildBoatInfoBox(bill),
            pw.SizedBox(height: 20),

            _ribbon('Fish Entries'),
            pw.SizedBox(height: 8),
            _buildFishTable(bill),
            pw.SizedBox(height: 16),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(width: 260, child: _buildSummaryBox(bill)),
            ),
            pw.SizedBox(height: 24),
            pw.Divider(thickness: 0.5, color: _purpleBorder),
            pw.SizedBox(height: 14),

            _buildTermsAndAuth(t),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                t.footer,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ─── Header (brand + invoice meta) ───────────────────────────────────────

  static pw.Widget _buildHeaderSection(
    BillEntity bill,
    InvoiceTemplateEntity t,
    DateFormat fmt,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                t.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: _purple,
                ),
              ),
              pw.Text(
                t.subtitle.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(width: 42, height: 2.5, color: _purple),
              pw.SizedBox(height: 12),
              _contactLine('Address', t.address.formatted),
              pw.SizedBox(height: 3),
              _contactLine('Phone', t.contactDetails.phone),
              if (t.contactDetails.email.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                _contactLine('Email', t.contactDetails.email),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: _purple,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  bill.billNumber,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Date  : ', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    fmt.format(bill.billDate),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Status: ', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    bill.status,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _statusColor(bill.status),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _contactLine(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 42,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
        ),
      ],
    );
  }

  // ─── Section ribbon label ────────────────────────────────────────────────

  static pw.Widget _ribbon(String text) {
    const width = 210.0;
    const height = 26.0;
    const notch = 14.0;
    return pw.Stack(
      children: [
        pw.CustomPaint(
          size: const PdfPoint(width, height),
          painter: (canvas, size) {
            canvas
              ..setColor(_purple)
              ..moveTo(0, 0)
              ..lineTo(size.x - notch, 0)
              ..lineTo(size.x, size.y / 2)
              ..lineTo(size.x - notch, size.y)
              ..lineTo(0, size.y)
              ..lineTo(0, 0)
              ..fillPath();
          },
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 14, top: 7),
          child: pw.Text(
            text.toUpperCase(),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Boat info ────────────────────────────────────────────────────────────

  static pw.Widget _buildBoatInfoBox(BillEntity bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _purpleLight,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _infoBlock('Boat', '${bill.boatName} (${bill.boatNumber})'),
          ),
          pw.Container(
            width: 1,
            height: 34,
            color: _purpleBorder,
            margin: const pw.EdgeInsets.symmetric(horizontal: 14),
          ),
          pw.Expanded(child: _infoBlock('Agent', bill.agentName)),
        ],
      ),
    );
  }

  static pw.Widget _infoBlock(String label, String value) {
    return pw.Row(
      children: [
        pw.Container(
          width: 30,
          height: 30,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            color: PdfColors.white,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text(
            label.substring(0, 1),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _purple,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Fish entries table ──────────────────────────────────────────────────

  static pw.Widget _buildFishTable(BillEntity bill) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1.8),
        3: pw.FlexColumnWidth(1.8),
        4: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _purple),
          children: [
            _cell('#', bold: true, color: PdfColors.white),
            _cell('Fish', bold: true, color: PdfColors.white),
            _cell('Weight (kg)', bold: true, color: PdfColors.white),
            _cell('Rate/kg', bold: true, color: PdfColors.white),
            _cell('Amount', bold: true, color: PdfColors.white),
          ],
        ),
        ...List.generate(bill.fishEntries.length, (i) {
          final e = bill.fishEntries[i];
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : _purpleLight,
            ),
            children: [
              _cell('${i + 1}'),
              _cell(e.fishName, bold: true),
              _cell(e.weight.toString()),
              _cell('Rs ${e.rate}'),
              _cell('Rs ${e.amount.toStringAsFixed(2)}'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 9.5,
          color: color,
        ),
      ),
    );
  }

  // ─── Summary ──────────────────────────────────────────────────────────────

  // ─── Summary ──────────────────────────────────────────────────────────────

  static pw.Widget _buildSummaryBox(BillEntity bill) {
    // ✅ Calculate subtotal from fish entries
    final subtotal = bill.fishEntries.fold<double>(
      0.0,
      (sum, entry) => sum + entry.amount,
    );

    // Calculate commission (5% of subtotal)
    final commissionRate = 0.05;
    final commissionAmount = subtotal * commissionRate;
    final netAmount = subtotal - commissionAmount;

    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: _purpleLight,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Column(
            children: [
              _summaryRow('Subtotal', 'Rs ${subtotal.toStringAsFixed(2)}'),
              pw.SizedBox(height: 8),
              _summaryRow(
                'Commission (5%)',
                '- Rs ${commissionAmount.toStringAsFixed(2)}',
                color: PdfColors.red700,
              ),
            ],
          ),
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: pw.BoxDecoration(
            color: _purple,
            borderRadius: const pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(8),
              bottomRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'NET PAYABLE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              pw.Text(
                'Rs ${netAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _summaryRow(String label, String value, {PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Terms & authorized-by ───────────────────────────────────────────────

  static pw.Widget _buildTermsAndAuth(InvoiceTemplateEntity template) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 3, child: _buildTermsList(template.termsConditions)),
        pw.SizedBox(width: 16),
        pw.Expanded(flex: 2, child: _buildAuthorizedBox(template)),
      ],
    );
  }

  static pw.Widget _buildTermsList(String terms) {
    final lines = terms
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TERMS & CONDITIONS',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _purple,
          ),
        ),
        pw.SizedBox(height: 8),
        ...List.generate(lines.length, (i) {
          final text = lines[i].replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 14,
                  height: 14,
                  margin: const pw.EdgeInsets.only(top: 1, right: 6),
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: _purpleLight,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Text(
                    '${i + 1}',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: _purple,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildAuthorizedBox(InvoiceTemplateEntity template) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _purpleLight,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _purpleBorder, width: 0.75),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'AUTHORIZED BY',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _purple,
            ),
          ),
          pw.SizedBox(height: 26),
          pw.Text(
            '........................',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey500),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'For ${template.title}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static PdfColor _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'CONFIRMED':
        return PdfColors.green700;
      case 'PENDING':
        return PdfColors.orange700;
      case 'OVERDUE':
        return PdfColors.red700;
      default:
        return _purple;
    }
  }

  // ─── Default template ────────────────────────────────────────────────────

  static InvoiceTemplateEntity _getDefaultTemplate() {
    return InvoiceTemplateEntity(
      title: 'INVOICE',
      subtitle: 'Fish Market - Official Receipt',
      termsConditions:
          '1. This invoice is computer generated and does not require a signature.\n'
          '2. All payments are to be made in Indian Rupees (INR) only.\n'
          '3. Please make the payment within 7 days from the invoice date.\n'
          '4. Goods once sold will not be taken back or exchanged.\n'
          '5. For any queries, please contact the above mentioned address or phone number.',
      contactDetails: ContactDetails(
        phone: '+91 9876543210',
        email: 'contact@fishmarket.com',
        website: 'www.fishmarket.com',
      ),
      address: Address(
        street: '123, Fish Market Road',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400001',
        country: 'India',
      ),
      footer: 'Thank you for your business!',
      isActive: true,
    );
  }
}
