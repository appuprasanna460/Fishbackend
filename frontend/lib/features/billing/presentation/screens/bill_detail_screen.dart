// lib/features/billing/presentation/screens/bill_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/billing_provider.dart';
import '../../domain/entities/bill_entity.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/bill_pdf_generator.dart';
import '../../../invoice_template/presentation/providers/invoice_template_provider.dart';
import '../../../invoice_template/domain/entities/invoice_template_entity.dart';

class BillDetailScreen extends ConsumerStatefulWidget {
  final String billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  ConsumerState<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends ConsumerState<BillDetailScreen> {
  final _fmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingProvider.notifier).loadById(widget.billId);
      ref.read(invoiceTemplateProvider.notifier).loadActiveTemplate();
    });
  }

  Future<void> _downloadPdf(BillEntity bill) async {
    // Get the current template
    final templateState = ref.read(invoiceTemplateProvider);
    final bytes = await BillPdfGenerator.generate(
      bill,
      template: templateState.template,
    );
    await Printing.sharePdf(bytes: bytes, filename: '${bill.billNumber}.pdf');
  }

  void _openPdfPreview(BillEntity bill, InvoiceTemplateEntity? template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BillPdfPreviewScreen(bill: bill, template: template),
      ),
    );
  }

  Future<void> _updateStatus(BillEntity bill, String status) async {
    try {
      final ok = await ref
          .read(billingProvider.notifier)
          .updateStatus(bill.id, status);
      if (ok && mounted) {
        // ✅ FIXED: Use ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(billingProvider.notifier).loadById(widget.billId);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingProvider);
    final templateState = ref.watch(invoiceTemplateProvider);
    final bill = state.selected;
    final template = templateState.template;

    return Scaffold(
      appBar: AppBar(
        title: Text(bill?.billNumber ?? 'Bill Detail'),
        actions: [],
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading || templateState.isLoading,
        child: bill == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Template Header (Title + Subtitle)
                    if (template != null) _buildTemplateHeader(template),
                    const SizedBox(height: AppSizes.p16),

                    _buildHeader(bill),
                    const SizedBox(height: AppSizes.p16),
                    _buildBoatInfo(bill),
                    const SizedBox(height: AppSizes.p16),
                    _buildFishEntries(bill),
                    const SizedBox(height: AppSizes.p16),
                    _buildSummary(bill),
                    const SizedBox(height: AppSizes.p16),

                    // ✅ Template Footer (Terms & Conditions)
                    if (template != null) _buildTemplateFooter(template),
                    const SizedBox(height: AppSizes.p24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _openPdfPreview(bill, template),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Preview & Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p24),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── Template Header ────────────────────────────────────────────────────────

  Widget _buildTemplateHeader(InvoiceTemplateEntity template) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            template.title,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p4),

          // Subtitle
          Text(
            template.subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: AppSizes.p16),

          // Contact Details Row
          Wrap(
            spacing: AppSizes.p16,
            runSpacing: AppSizes.p4,
            children: [
              _buildInfoChip(Icons.phone, template.contactDetails.phone),
              if (template.contactDetails.email.isNotEmpty)
                _buildInfoChip(Icons.email, template.contactDetails.email),
              if (template.contactDetails.website.isNotEmpty)
                _buildInfoChip(Icons.language, template.contactDetails.website),
            ],
          ),
          const SizedBox(height: AppSizes.p8),

          // Address
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSizes.p4),
              Expanded(
                child: Text(
                  template.address.formatted,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Template Footer ────────────────────────────────────────────────────────

  Widget _buildTemplateFooter(InvoiceTemplateEntity template) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms & Conditions',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          Container(
            padding: const EdgeInsets.all(AppSizes.p12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
            ),
            child: Text(
              template.termsConditions,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const Divider(height: AppSizes.p20),
          Center(
            child: Text(
              template.footer,
              style: AppTextStyles.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bill Header ────────────────────────────────────────────────────────────

  Widget _buildHeader(BillEntity bill) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.primaryGradient),
        borderRadius: BorderRadius.circular(AppSizes.radius20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bill.billNumber,
                style: AppTextStyles.h3.copyWith(color: Colors.white),
              ),
              AppStatusBadge.fromString(bill.status),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            _fmt.format(bill.billDate),
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ─── Boat Info ──────────────────────────────────────────────────────────────

  Widget _buildBoatInfo(BillEntity bill) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Boat Information',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            _infoRow(
              Icons.directions_boat_outlined,
              'Boat',
              '${bill.boatName} (${bill.boatNumber})',
            ),
            const SizedBox(height: AppSizes.p8),
            _infoRow(Icons.person_outline, 'Agent', bill.agentName),
          ],
        ),
      ),
    );
  }

  // ─── Fish Entries ──────────────────────────────────────────────────────────

  Widget _buildFishEntries(BillEntity bill) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fish Entries (${bill.fishEntries.length})',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            ...bill.fishEntries.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: AppSizes.p8),
                padding: const EdgeInsets.all(AppSizes.p12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.fishName, style: AppTextStyles.labelLarge),
                          Text(
                            '${entry.weight} kg × ₹${entry.rate}/kg',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹ ${entry.amount.toStringAsFixed(2)}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Summary ────────────────────────────────────────────────────────────────

  Widget _buildSummary(BillEntity bill) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          children: [
            _summaryRow(
              'Commission (5%)',
              '- ₹ ${bill.commissionAmount.toStringAsFixed(2)}',
              color: AppColors.error,
            ),
            const Divider(height: AppSizes.p16),
            _summaryRow(
              'Net Payable',
              '₹ ${bill.netAmount.toStringAsFixed(2)}',
              style: AppTextStyles.h4.copyWith(color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.p8),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? color,
    TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: style ?? AppTextStyles.labelLarge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Full-screen PDF preview with built-in print / share actions ────────────

class _BillPdfPreviewScreen extends StatefulWidget {
  final BillEntity bill;
  final InvoiceTemplateEntity? template;

  const _BillPdfPreviewScreen({required this.bill, required this.template});

  @override
  State<_BillPdfPreviewScreen> createState() => _BillPdfPreviewScreenState();
}

class _BillPdfPreviewScreenState extends State<_BillPdfPreviewScreen> {
  bool _isDownloading = false;
  bool _isSharing = false;

  Future<void> _downloadDirectly(BuildContext context) async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isDownloading = true);
    try {
      final bytes = await BillPdfGenerator.generate(
        widget.bill,
        template: widget.template,
      );

      Directory? directory;
      if (Platform.isAndroid) {
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        } catch (_) {
          directory = null;
        }
      }

      if (directory == null) {
        directory = await getDownloadsDirectory();
      }
      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }

      final String filePath = '${directory.path}/${widget.bill.billNumber}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF saved successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to download: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isSharing = true);
    try {
      final bytes = await BillPdfGenerator.generate(
        widget.bill,
        template: widget.template,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${widget.bill.billNumber}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview • ${widget.bill.billNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _isDownloading || _isSharing
                ? null
                : () => _sharePdf(context),
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _isDownloading || _isSharing
                ? null
                : () => _downloadDirectly(context),
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: _isDownloading || _isSharing,
        child: PdfPreview(
          build: (format) =>
              BillPdfGenerator.generate(widget.bill, template: widget.template),
          allowPrinting: false,
          allowSharing: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          useActions: false, // Disables default printing toolbar completely
          pdfFileName: '${widget.bill.billNumber}.pdf',
        ),
      ),
    );
  }
}
