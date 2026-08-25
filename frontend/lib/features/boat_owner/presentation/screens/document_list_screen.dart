import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../providers/document_providers.dart';
import '../../domain/entities/document_entity.dart';

class DocumentListScreen extends ConsumerStatefulWidget {
  final String? category;
  final String? documentType;
  final String? crewMemberId;

  const DocumentListScreen({
    super.key,
    this.category,
    this.documentType,
    this.crewMemberId,
  });

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All'; // All, Valid, Expiring, Expired
  final List<String> _statusFilters = ['All', 'Valid', 'Expiring', 'Expired'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDocuments();
    });
  }

  void _fetchDocuments() {
    // Map 'Expiring' to backend 'Expiring Soon'
    final mappedStatus = _selectedStatus == 'Expiring' ? 'Expiring Soon' : _selectedStatus;
    
    ref.read(documentProvider.notifier).fetchDocuments(
      crewMemberId: widget.crewMemberId,
      status: mappedStatus,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);
    var documents = state.documents;

    // Filter by type in-memory
    if (widget.documentType == 'BOAT') {
      documents = documents.where((doc) => doc.crewMemberId == null).toList();
    } else if (widget.documentType == 'CREW') {
      documents = documents.where((doc) => doc.crewMemberId != null).toList();
    }

    // Build Screen Title based on inputs
    String screenTitle = 'Documents';
    if (widget.documentType == 'BOAT') {
      screenTitle = 'Boat Documents';
    } else if (widget.documentType == 'CREW') {
      screenTitle = 'Crew Documents';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          screenTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDocuments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _fetchDocuments();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _fetchDocuments(),
                ),
                const SizedBox(height: 12),
                
                // Status Filters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _statusFilters.map<Widget>((status) {
                    final isSelected = _selectedStatus == status;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = status;
                          });
                          _fetchDocuments();
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Document List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : documents.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.p16),
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final doc = documents[index];
                          return _buildDocumentCard(doc);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/owner/documents/add?crewId=${widget.crewMemberId ?? ''}'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 80, color: AppColors.textHint.withOpacity(0.3)),
            const SizedBox(height: AppSizes.p16),
            Text(
              'No Documents Found',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search filters or upload a new document to get started.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(DocumentEntity doc) {
    final status = doc.status; // Valid, Expiring Soon, Expired
    
    // Status color mapping
    Color statusColor = AppColors.success;
    Color statusBgColor = AppColors.successLight;
    IconData statusIcon = Icons.check_circle_outline_rounded;
    
    if (status == 'Expiring Soon') {
      statusColor = AppColors.warning;
      statusBgColor = AppColors.warningLight;
      statusIcon = Icons.timelapse_rounded;
    } else if (status == 'Expired') {
      statusColor = AppColors.error;
      statusBgColor = AppColors.errorLight;
      statusIcon = Icons.error_outline_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/owner/documents/details/${doc.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Document Name and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doc.documentName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Document Number
              Row(
                children: [
                  const Icon(Icons.tag_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    'Doc No: ',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    doc.documentNumber,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Divider
              const Divider(height: 16, color: AppColors.border),

              // Validity & Remaining days row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Text(
                        'Valid until: ${_formatDate(doc.expiryDate)}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    doc.remainingDays <= 0 
                        ? 'Expired' 
                        : '${doc.remainingDays} days left',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: doc.remainingDays <= 0
                          ? AppColors.error
                          : doc.remainingDays <= 30
                              ? AppColors.warning
                              : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
  }
}
