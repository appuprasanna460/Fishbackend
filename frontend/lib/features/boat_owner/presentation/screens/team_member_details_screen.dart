import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/crew_provider.dart';
import '../../domain/entities/crew_entity.dart';

class TeamMemberDetailsScreen extends ConsumerWidget {
  final String memberId;

  const TeamMemberDetailsScreen({super.key, required this.memberId});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crewState = ref.watch(crewProvider);
    final member = crewState.crewMembers.firstWhere(
      (m) => m.id == memberId,
      orElse: () => CrewEntity(
        id: memberId,
        ownerId: '',
        name: 'Crew Member',
        age: 30,
        phone: '',
        location: '',
        role: 'CREW',
        isActive: false,
        isAvailable: false,
      ),
    );

    final initials = member.name.isNotEmpty
        ? member.name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join()
        : '?';

    final displayRole = member.role.toUpperCase() == 'CAPTAIN' ? 'Captain' : 'Crew Member';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Member Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Card ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    member.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayRole,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Profile Sections ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Section: Personal Info
                  _buildSectionCard(
                    title: 'PERSONAL INFORMATION',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _buildRow('Phone Number', member.phone),
                      _buildRow('Age', '${member.age} Years Old'),
                      _buildRow('Home Location', member.location),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section: Work Details
                  _buildSectionCard(
                    title: 'WORK DETAILS',
                    icon: Icons.work_outline_rounded,
                    children: [
                      _buildRow('App Role', displayRole),
                      _buildRow('Experience', member.experience != null ? '${member.experience} Years' : 'Not set'),
                      _buildRow('Availability Status', member.isAvailable ? 'Available for Voyage' : 'On Voyage', valueColor: member.isAvailable ? const Color(0xFF2ECC71) : Colors.amber),
                      _buildRow('Voyage Info', member.assignedTo != null ? 'Assigned to Voyage: ${member.assignedTo!.voyageId}' : 'Unassigned'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section: Account Logs
                  _buildSectionCard(
                    title: 'ACCOUNT STATUS',
                    icon: Icons.receipt_long_outlined,
                    children: [
                      if (member.createdAt != null) _buildRow('Registered Date', _formatDate(member.createdAt)),
                      _buildRow('Activation Status', member.isActive ? 'Active' : 'Inactive', valueColor: member.isActive ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C)),
                      if (member.notes != null && member.notes!.isNotEmpty) _buildRow('Notes / Remarks', member.notes!),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children.map((child) {
            final isLast = children.last == child;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child,
                if (!isLast) const Divider(height: 20),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
