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
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../providers/crew_provider.dart';
import '../providers/document_providers.dart';
import '../../domain/entities/document_entity.dart';

class AddDocumentScreen extends ConsumerStatefulWidget {
  final String? crewId;
  final String? renewId; // Pre-populate for renewal flow

  const AddDocumentScreen({
    super.key,
    this.crewId,
    this.renewId,
  });

  @override
  ConsumerState<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends ConsumerState<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _issuedByController = TextEditingController();

  bool _isCrewDocument = false;
  String? _selectedBoatId;
  String? _selectedCrewId;
  DateTime? _issueDate;
  DateTime? _expiryDate;

  List<File> _selectedFiles = [];
  bool _isPdfSelected = false;
  bool _isPrepopulating = false;

  @override
  void initState() {
    super.initState();
    // Default initializations
    if (widget.crewId != null && widget.crewId!.isNotEmpty) {
      _selectedCrewId = widget.crewId;
      _isCrewDocument = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      ref.read(boatProvider.notifier).load(ownerId: user?.id);
      ref.read(crewProvider.notifier).fetchCrew();
      
      if (widget.renewId != null) {
        _prepopulateForRenewal();
      }
    });
  }

  Future<void> _prepopulateForRenewal() async {
    setState(() {
      _isPrepopulating = true;
    });
    try {
      final notifier = ref.read(documentProvider.notifier);
      final docMap = await notifier.apiService.getDocumentById(widget.renewId!);
      final doc = DocumentEntity.fromJson(docMap);
      
      setState(() {
        _nameController.text = doc.documentName;
        _numberController.text = doc.documentNumber;
        _issuedByController.text = doc.issuedBy;
        _isCrewDocument = doc.crewMemberId != null;
        _selectedBoatId = doc.boatId;
        _selectedCrewId = doc.crewMemberId;
        
        // Renewal requires new issue/expiry dates, so we leave them blank
        // but pre-select boat or crew.
        _isPrepopulating = false;
      });
    } catch (e) {
      setState(() {
        _isPrepopulating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pre-populate details: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _issuedByController.dispose();
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
        // PDF constraints: 1 PDF only
        final pdfFile = files.firstWhere((f) => f.path.toLowerCase().endsWith('.pdf'));
        setState(() {
          _selectedFiles = [pdfFile];
          _isPdfSelected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF selected. Only 1 PDF is allowed per document.')),
        );
      } else {
        // Image constraints: Max 2 images
        if (files.length > 2) {
          files = files.sublist(0, 2);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A maximum of 2 images can be uploaded.')),
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

  Future<void> _saveDocument() async {
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

    // Build Form Data for upload
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('documentName', _nameController.text),
      MapEntry('documentNumber', _numberController.text),
      if (_selectedBoatId != null) MapEntry('boatId', _selectedBoatId!),
      if (_selectedCrewId != null) MapEntry('crewMemberId', _selectedCrewId!),
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
      if (widget.renewId != null) {
        // Update document (Renewal flow)
        await prov.updateDocument(widget.renewId!, formData);
      } else {
        // Create new document
        if (_isCrewDocument && _selectedCrewId != null) {
          await prov.createCrewDocument(_selectedCrewId!, formData);
        } else {
          await prov.createDocument(formData);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.renewId != null 
                ? 'Document renewed successfully!' 
                : 'Document uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
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
    final boatsState = ref.watch(boatProvider);
    final crewState = ref.watch(crewProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.renewId != null ? 'Renew Document' : 'Add Document',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isPrepopulating
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
                        // Association Selection (Boat vs Crew)
                        _buildLabel('ASSOCIATE WITH'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAssociationRadio(false, 'Boat'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildAssociationRadio(true, 'Crew / Captain'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Conditional: Boat Selection Dropdown
                        if (!_isCrewDocument) ...[
                          _buildLabel('SELECT BOAT'),
                          DropdownButtonFormField<String>(
                            value: _selectedBoatId,
                            hint: const Text('Select Boat'),
                            decoration: InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            items: boatsState.boats.map((boat) {
                              return DropdownMenuItem<String>(
                                value: boat.id,
                                child: Text('${boat.boatName} (${boat.boatNumber})'),
                              );
                            }).toList(),
                            validator: (v) => v == null ? 'Please select a boat' : null,
                            onChanged: (val) {
                              setState(() {
                                _selectedBoatId = val;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Conditional: Crew Member Dropdown
                        if (_isCrewDocument) ...[
                          _buildLabel('SELECT CREW MEMBER'),
                          DropdownButtonFormField<String>(
                            value: _selectedCrewId,
                            hint: const Text('Select Crew Member'),
                            decoration: InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            items: crewState.crewMembers.map((member) {
                              return DropdownMenuItem<String>(
                                value: member.id,
                                child: Text('${member.name} (${member.role})'),
                              );
                            }).toList(),
                            validator: (v) => v == null ? 'Please select a crew member' : null,
                            onChanged: widget.crewId != null && widget.crewId!.isNotEmpty
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedCrewId = val;
                                    });
                                  },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Document Name & Number
                        _buildLabel('DOCUMENT NAME'),
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration('e.g. Fishing License, ID Proof'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Document name is required' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('DOCUMENT NUMBER'),
                        TextFormField(
                          controller: _numberController,
                          decoration: _buildInputDecoration('e.g. REG-102948-Z'),
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
                        _buildLabel('ISSUED BY'),
                        TextFormField(
                          controller: _issuedByController,
                          decoration: _buildInputDecoration('e.g. Fisheries Ministry, Gov Authority'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Issued by authority is required' : null,
                        ),
                        const SizedBox(height: 24),

                        // Files Picker & Preview Card
                        _buildLabel('UPLOAD DOCUMENT'),
                        _buildUploadBox(),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: widget.renewId != null ? 'Renew & Save Document' : 'Save Document',
                            onPressed: _saveDocument,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                if (state.isUploading)
                  _buildUploadOverlay(state),
              ],
            ),
    );
  }

  Widget _buildAssociationRadio(bool isCrew, String label) {
    final isSelected = _isCrewDocument == isCrew;
    return InkWell(
      onTap: widget.crewId != null && widget.crewId!.isNotEmpty
          ? null
          : () {
              setState(() {
                _isCrewDocument = isCrew;
                if (isCrew) {
                  _selectedBoatId = null;
                } else {
                  _selectedCrewId = null;
                }
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: isCrew,
              groupValue: _isCrewDocument,
              activeColor: AppColors.primary,
              onChanged: widget.crewId != null && widget.crewId!.isNotEmpty
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _isCrewDocument = val;
                          if (val) {
                            _selectedBoatId = null;
                          } else {
                            _selectedCrewId = null;
                          }
                        });
                      }
                    },
            ),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
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

  Widget _buildUploadOverlay(DocumentState state) {
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
                'This may take a moment',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
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
