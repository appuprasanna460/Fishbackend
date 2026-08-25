import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../domain/entities/crew_entity.dart';

class CrewCard extends StatelessWidget {
  final CrewEntity crew;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CrewCard({
    super.key,
    required this.crew,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCaptain = crew.role.toUpperCase() == 'CAPTAIN';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCaptain ? AppColors.roleOwner.withOpacity(0.1) : AppColors.roleStaff.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCaptain ? 'CAPTAIN' : 'CREW',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isCaptain ? AppColors.roleOwner : AppColors.roleStaff,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Expanded(
                      child: Text(
                        crew.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Availability Indicator
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: crew.isAvailable ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    crew.isAvailable ? 'Available' : 'On Voyage',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: crew.isAvailable ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          Text(
            'Age: ${crew.age} | Phone: ${crew.phone}',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Location: ${crew.location}',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          if (crew.experience != null && crew.experience! > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Experience: ${crew.experience} years',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (!crew.isAvailable && crew.assignedTo != null) ...[
            const SizedBox(height: AppSizes.p8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assigned to Voyage',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: AppSizes.p24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                label: Text(
                  'Edit',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              TextButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                label: Text(
                  'Delete',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
