import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../providers/crew_provider.dart';
import '../providers/document_providers.dart';
import '../../domain/entities/crew_entity.dart';
import '../../domain/entities/document_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CrewDocumentsScreen extends ConsumerStatefulWidget {
  const CrewDocumentsScreen({super.key});

  @override
  ConsumerState<CrewDocumentsScreen> createState() => _CrewDocumentsScreenState();
}

class _CrewDocumentsScreenState extends ConsumerState<CrewDocumentsScreen> {
  String? _selectedBoatId;
  CrewEntity? _selectedCrewMember;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      ref.read(boatProvider.notifier).load(ownerId: user?.id).then((_) {
        // Auto select first boat if available
        final boats = ref.read(boatProvider).boats;
        if (boats.isNotEmpty) {
          setState(() {
            _selectedBoatId = boats.first.id;
          });
        }
      });
      ref.read(crewProvider.notifier).fetchCrew();
    });
  }

  @override
  Widget build(BuildContext context) {
    final boatsState = ref.watch(boatProvider);
    final crewState = ref.watch(crewProvider);
    final docState = ref.watch(documentProvider);

    // Filter crew members assigned to the selected boat
    final filteredCrew = crewState.crewMembers.where((member) {
      if (_selectedBoatId == null) return false;
      return member.assignedTo?.boatId == _selectedBoatId;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crew Documents', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Boat Selection Dropdown
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECT BOAT',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedBoatId,
                  hint: const Text('Select Boat'),
                  decoration: InputDecoration(
                    fillColor: AppColors.background,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: boatsState.boats.map((boat) {
                    return DropdownMenuItem<String>(
                      value: boat.id,
                      child: Text('${boat.boatName} (${boat.boatNumber})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBoatId = val;
                      _selectedCrewMember = null;
                    });
                  },
                ),
              ],
            ),
          ),

          // Crew List
          Expanded(
            child: crewState.isLoading || boatsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedBoatId == null
                    ? _buildSelectionPrompt('Please select a boat to view its crew.')
                    : filteredCrew.isEmpty
                        ? _buildSelectionPrompt('No crew members assigned to this boat.')
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSizes.p16),
                            itemCount: filteredCrew.length,
                            itemBuilder: (context, index) {
                              final member = filteredCrew[index];
                              return _buildCrewCard(member);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPrompt(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textHint.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrewCard(CrewEntity member) {
    final shortId = member.id != null && member.id!.length > 6
        ? member.id!.substring(member.id!.length - 6).toUpperCase()
        : member.id ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _showCrewDocumentsSheet(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  member.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSizes.p16),

              // Crew Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('ID: $shortId', style: AppTextStyles.caption),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: member.role == 'CAPTAIN' ? Colors.amber.withOpacity(0.1) : AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.role,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: member.role == 'CAPTAIN' ? Colors.orange[800] : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge & Arrow
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'View Proofs',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCrewDocumentsSheet(CrewEntity member) {
    // Load documents for this member
    ref.read(documentProvider.notifier).fetchCrewDocuments(member.id!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(documentProvider);
                final crewDocs = state.crewDocuments;

                // Filter out Medical Certificate
                final filteredDocs = crewDocs.where((doc) {
                  return doc.documentName.toLowerCase() != 'medical certificate';
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.name, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
                              Text('${member.role} proofs & verifications', style: AppTextStyles.caption),
                            ],
                          ),
                          AppButton(
                            text: 'Upload Proof',
                            height: 36,
                            width: 120,
                            onPressed: () {
                              Navigator.pop(context); // Close sheet
                              context.push('/owner/documents/crew/${member.id}/upload');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Document List
                      Expanded(
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filteredDocs.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.folder_off_rounded, size: 48, color: AppColors.textHint.withOpacity(0.3)),
                                        const SizedBox(height: 8),
                                        Text('No verification proofs uploaded.', style: AppTextStyles.bodyMedium),
                                        Text('Tap "Upload Proof" to add verification files.', style: AppTextStyles.caption),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: filteredDocs.length,
                                    itemBuilder: (context, index) {
                                      final doc = filteredDocs[index];
                                      return _buildProofListTile(doc, member.id!);
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProofListTile(DocumentEntity doc, String memberId) {
    final status = doc.status;
    Color statusColor = AppColors.success;
    if (status == 'Expiring Soon') {
      statusColor = AppColors.warning;
    } else if (status == 'Expired') {
      statusColor = AppColors.error;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          doc.files.isNotEmpty && doc.files.first.mimeType?.toLowerCase().contains('pdf') == true
              ? Icons.picture_as_pdf_rounded
              : Icons.image_rounded,
          color: AppColors.primary,
        ),
        title: Text(doc.documentName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('No: ${doc.documentNumber} | Expires: ${_formatDate(doc.expiryDate)}', style: AppTextStyles.caption),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
            ),
            const SizedBox(width: 6),
            Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              onPressed: () => _confirmDelete(doc.id!, memberId),
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context); // Close sheet
          context.push('/owner/documents/details/${doc.id}');
        },
      ),
    );
  }

  Future<void> _confirmDelete(String docId, String memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Proof'),
        content: const Text('Are you sure you want to delete this crew proof document?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(documentProvider.notifier).deleteDocument(docId, crewMemberId: memberId);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
  }
}
