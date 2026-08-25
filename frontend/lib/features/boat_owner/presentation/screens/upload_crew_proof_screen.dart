import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/crew_provider.dart';
import '../providers/document_providers.dart';
import '../../domain/entities/crew_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UploadCrewProofScreen extends ConsumerStatefulWidget {
  final String crewMemberId;

  const UploadCrewProofScreen({
    super.key,
    required this.crewMemberId,
  });

  @override
  ConsumerState<UploadCrewProofScreen> createState() => _UploadCrewProofScreenState();
}

class _UploadCrewProofScreenState extends ConsumerState<UploadCrewProofScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _issuedByController = TextEditingController();
  final _customNameController = TextEditingController();

  String _proofName = 'ID Proof';
  DateTime? _issueDate;
  DateTime? _expiryDate;
  CrewEntity? _crewMember;
  bool _isLoadingCrew = true;

  List<File> _selectedFiles = [];
  bool _isPdfSelected = false;

  final List<String> _proofNameOptions = [
    'ID Proof',
    'Crew Proof',
    'Captain Proof',
    'Other relevant proof'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCrewMember();
    });
  }

  Future<void> _loadCrewMember() async {
    setState(() {
      _isLoadingCrew = true;
    });
    try {
      final crewNotifier = ref.read(crewProvider.notifier);
      final user = ref.read(authProvider).user;
      final member = await crewNotifier.apiService.getCrewById(widget.crewMemberId);
      setState(() {
        _crewMember = CrewEntity.fromJson(member);
        _isLoadingCrew = false;
        
        // Auto select role-based proofs
        if (_crewMember?.role == 'CAPTAIN') {
          _proofName = 'Captain Proof';
        } else {
          _proofName = 'Crew Proof';
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCrew = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load crew member: $e')),
      );
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _issuedByController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );

      if (result == null) return;

      List<File> files = result.paths.where((p) => p != null).map((p) => File(p!)).toList();
      if (files.isEmpty) return;

      bool hasPdf = files.any((f) => f.path.toLowerCase().endsWith('.pdf'));

      if (hasPdf) {
        final pdfFile = files.firstWhere((f) => f.path.toLowerCase().endsWith('.pdf'));
        setState(() {
          _selectedFiles = [pdfFile];
          _isPdfSelected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF selected. Only 1 PDF is allowed.')),
        );
      } else {
        if (files.length > 2) {
          files = files.sublist(0, 2);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A maximum of 2 images can be selected.')),
          );
        }
        setState(() {
          _selectedFiles = files;
          _isPdfSelected = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  Future<void> _replaceFile(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _isPdfSelected ? ['pdf'] : ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _selectedFiles[index] = File(result.files.single.path!);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error replacing file: $e')),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      if (_selectedFiles.isEmpty) {
        _isPdfSelected = false;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _saveProof() async {
    if (!_formKey.currentState!.validate()) return;

    if (_issueDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Issue Date and Expiry Date.')),
      );
      return;
    }

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one PDF or Image file.')),
      );
      return;
    }

    final finalProofName = _proofName == 'Other relevant proof' && _customNameController.text.isNotEmpty
        ? _customNameController.text
        : _proofName;

    // Build Form Data
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('documentName', finalProofName),
      MapEntry('documentNumber', _numberController.text),
      MapEntry('crewMemberId', widget.crewMemberId),
      // Automatically associate with the crew member's boat if assigned
      if (_crewMember?.assignedTo?.boatId != null) 
        MapEntry('boatId', _crewMember!.assignedTo!.boatId),
      MapEntry('issueDate', _issueDate!.toIso8601String()),
      MapEntry('expiryDate', _expiryDate!.toIso8601String()),
      MapEntry('issuedBy', _issuedByController.text),
    ]);

    for (var file in _selectedFiles) {
      final filename = file.path.split('/').last;
      formData.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(
            file.path,
            filename: filename,
          ),
        ),
      );
    }

    try {
      final prov = ref.read(documentProvider.notifier);
      await prov.createCrewDocument(widget.crewMemberId, formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crew proof document uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // Go back to crew list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Crew Proof', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingCrew
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Crew Info Header Card
                        _buildCrewHeaderCard(),
                        const SizedBox(height: 20),

                        // Proof Name Selection
                        _buildLabel('PROOF NAME'),
                        DropdownButtonFormField<String>(
                          value: _proofName,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          items: _proofNameOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(opt),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _proofName = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Custom Name textfield (if "Other" is selected)
                        if (_proofName == 'Other relevant proof') ...[
                          _buildLabel('SPECIFY PROOF NAME'),
                          TextFormField(
                            controller: _customNameController,
                            decoration: _buildInputDecoration('e.g. Identity Certificate, Local Verification'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Please specify the proof name' : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Proof Number
                        _buildLabel('PROOF / DOCUMENT NUMBER'),
                        TextFormField(
                          controller: _numberController,
                          decoration: _buildInputDecoration('e.g. PASS-01928391'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Document number is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Date Pickers Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('ISSUE DATE'),
                                  InkWell(
                                    onTap: () => _selectDate(context, true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _issueDate == null
                                                ? 'Select Date'
                                                : _formatDateShort(_issueDate!),
                                            style: TextStyle(
                                              color: _issueDate == null ? AppColors.textHint : AppColors.textPrimary,
                                            ),
                                          ),
                                          const Icon(Icons.calendar_today, size: 16, color: AppColors.textHint),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('EXPIRY DATE'),
                                  InkWell(
                                    onTap: () => _selectDate(context, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _expiryDate == null
                                                ? 'Select Date'
                                                : _formatDateShort(_expiryDate!),
                                            style: TextStyle(
                                              color: _expiryDate == null ? AppColors.textHint : AppColors.textPrimary,
                                            ),
                                          ),
                                          const Icon(Icons.calendar_today, size: 16, color: AppColors.textHint),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Issued By
                        _buildLabel('ISSUED BY AUTHORITY'),
                        TextFormField(
                          controller: _issuedByController,
                          decoration: _buildInputDecoration('e.g. Ministry of Interior, Police Dept'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Issued by authority is required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Upload Proof Box
                        _buildLabel('UPLOAD PROOF FILE'),
                        _buildUploadBox(),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: 'Upload & Save Proof',
                            onPressed: _saveProof,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                if (state.isUploading)
                  _buildUploadOverlay(),
              ],
            ),
    );
  }

  Widget _buildCrewHeaderCard() {
    if (_crewMember == null) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primarySurface,
            radius: 20,
            child: Text(
              _crewMember!.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _crewMember!.name,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Associated Role: ${_crewMember!.role}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Associated Member',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox() {
    if (_selectedFiles.isEmpty) {
      return InkWell(
        onTap: _pickFiles,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                'Upload PDF or Image(s)',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 2),
              Text(
                'Supported: JPG, JPEG, PNG, PDF (Max 2 images / 1 PDF)',
                style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index) {
              final file = _selectedFiles[index];
              final isPdf = file.path.toLowerCase().endsWith('.pdf');
              final filename = file.path.split('/').last;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                      color: isPdf ? AppColors.error : AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            filename,
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, color: AppColors.primary, size: 20),
                      onPressed: () => _replaceFile(index),
                      tooltip: 'Replace File',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      onPressed: () => _removeFile(index),
                      tooltip: 'Remove File',
                    ),
                  ],
                ),
              );
            },
          ),
          if (!_isPdfSelected && _selectedFiles.length < 2) ...[
            const Divider(),
            TextButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add second image'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(AppSizes.p24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 4),
              SizedBox(height: 16),
              Text(
                'Uploading S3 Secure...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Associating with Crew Member',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 4.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
  }
}
