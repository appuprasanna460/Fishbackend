import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/document_providers.dart';
import '../../domain/entities/document_entity.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentDetailScreen({
    super.key,
    required this.documentId,
  });

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  DocumentEntity? _document;
  bool _isLoading = true;
  String? _error;
  bool _isGeneratingPdf = false;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _fetchDocumentDetails();
  }

  Future<void> _fetchDocumentDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notifier = ref.read(documentProvider.notifier);
      final docMap = await notifier.apiService.getDocumentById(widget.documentId);
      final doc = DocumentEntity.fromJson(docMap);
      
      setState(() {
        _document = doc;
        _isLoading = false;
      });
      
      // Proactively prepare PDF bytes in background
      _preparePdfBytes(doc);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _preparePdfBytes(DocumentEntity doc) async {
    if (doc.files.isEmpty) return;

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final isPdf = doc.files.first.mimeType?.toLowerCase().contains('pdf') == true ||
          doc.files.first.url.toLowerCase().endsWith('.pdf');

      if (isPdf) {
        // Download S3 PDF bytes directly
        final dio = Dio();
        final response = await dio.get<List<int>>(
          doc.files.first.url,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          setState(() {
            _pdfBytes = Uint8List.fromList(response.data!);
          });
        }
      } else {
        // Generate PDF from 1 or 2 images
        final pdfDoc = pw.Document();
        final dio = Dio();

        for (final file in doc.files) {
          final response = await dio.get<List<int>>(
            file.url,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.data != null) {
            final image = pw.MemoryImage(Uint8List.fromList(response.data!));
            pdfDoc.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                margin: const pw.EdgeInsets.all(20),
                build: (pw.Context context) {
                  return pw.Center(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  );
                },
              ),
            );
          }
        }
        final generatedBytes = await pdfDoc.save();
        setState(() {
          _pdfBytes = generatedBytes;
        });
      }
    } catch (e) {
      debugPrint('Error preparing PDF bytes: $e');
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document files are still downloading... Please wait.')),
      );
      return;
    }

    try {
      final cleanName = _document!.documentName.replaceAll(RegExp(r'[^\w\s\-]'), '_');
      final filename = '${cleanName}_${_document!.documentNumber}.pdf';
      
      // Open native system print/save dialog which lets user "Save as PDF" easily without permission issues
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => _pdfBytes!,
        name: filename,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download PDF: $e')),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document files are still downloading... Please wait.')),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final cleanName = _document!.documentName.replaceAll(RegExp(r'[^\w\s\-]'), '_');
      final path = '${tempDir.path}/${cleanName}_${_document!.documentNumber}.pdf';
      
      final file = File(path);
      await file.writeAsBytes(_pdfBytes!);

      await Share.shareXFiles([XFile(path)], text: 'Document: ${_document!.documentName}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load document details',
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: 8),
                Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchDocumentDetails,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final doc = _document!;
    final status = doc.status;

    // Status styling
    Color statusColor = AppColors.success;
    Color statusBgColor = AppColors.successLight;
    if (status == 'Expiring Soon') {
      statusColor = AppColors.warning;
      statusBgColor = AppColors.warningLight;
    } else if (status == 'Expired') {
      statusColor = AppColors.error;
      statusBgColor = AppColors.errorLight;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Document Details', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          doc.documentName,
                          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No: ${doc.documentNumber}',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  _buildMetaRow(Icons.calendar_today_outlined, 'Issue Date', _formatDate(doc.issueDate)),
                  _buildMetaRow(Icons.date_range_outlined, 'Expiry Date', _formatDate(doc.expiryDate)),
                  _buildMetaRow(Icons.verified_outlined, 'Issued By', doc.issuedBy),
                  _buildMetaRow(
                    Icons.hourglass_bottom_rounded,
                    'Validity Remaining',
                    doc.remainingDays <= 0 ? 'Expired' : '${doc.remainingDays} Days',
                    valueColor: doc.remainingDays <= 0 
                        ? AppColors.error 
                        : doc.remainingDays <= 30 
                            ? AppColors.warning 
                            : AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p20),

            // Document Preview section
            Text(
              'DOCUMENT PREVIEW',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSizes.p10),
            Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: doc.files.isEmpty
                    ? const Center(child: Text('No files uploaded for this document.'))
                    : _isGeneratingPdf
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Loading preview...'),
                              ],
                            ),
                          )
                        : _pdfBytes != null
                            ? PdfPreview(
                                build: (format) => _pdfBytes!,
                                useActions: false,
                                allowPrinting: false,
                                allowSharing: false,
                                maxPageWidth: 300,
                              )
                            : _buildImagesListPreview(doc),
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // Actions Grid
            Row(
              children: [
                 Expanded(
                   child: AppButton(
                     text: 'Share',
                     variant: AppButtonVariant.secondary,
                     leadingIcon: Icons.share_rounded,
                     onPressed: _sharePdf,
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: AppButton(
                     text: 'Download PDF',
                     variant: AppButtonVariant.primary,
                     leadingIcon: Icons.download_rounded,
                     onPressed: _downloadPdf,
                   ),
                 ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/owner/documents/add?renewId=${doc.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningLight,
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.autorenew_rounded),
                label: const Text('Renew Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: AppSizes.p32),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesListPreview(DocumentEntity doc) {
    return PageView.builder(
      itemCount: doc.files.length,
      itemBuilder: (context, index) {
        final file = doc.files[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: Image.network(
                file.url,
                fit: BoxFit.contain,
                errorBuilder: (context, err, stack) => const Center(
                  child: Icon(Icons.broken_image_rounded, size: 50, color: AppColors.textHint),
                ),
              ),
            ),
            if (doc.files.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}/${doc.files.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
  }
}
