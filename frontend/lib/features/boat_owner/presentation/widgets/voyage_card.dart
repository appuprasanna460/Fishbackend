import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../domain/entities/voyage_entity.dart';
import 'voyage_status_badge.dart';

class VoyageCard extends StatelessWidget {
  final VoyageEntity voyage;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VoyageCard({
    super.key,
    required this.voyage,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd-MMM-yyyy').format(voyage.departureDate);
    final voyageTypeLabel = voyage.voyageType == 'DEEP_SEA' ? 'Deep Sea' : 'Underdeep';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                      Icon(
                        Icons.directions_boat,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.p8),
                      Expanded(
                        child: Text(
                          voyage.boatName ?? 'Unknown Boat',
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
                VoyageStatusBadge(status: voyage.status),
              ],
            ),
            if (voyage.boatNumber != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 28.0),
                child: Text(
                  voyage.boatNumber!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            const Divider(height: AppSizes.p24),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textHint),
                const SizedBox(width: AppSizes.p8),
                Text(
                  'Departure: $formattedDate | ${voyage.departureTime}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: AppColors.textHint),
                const SizedBox(width: AppSizes.p8),
                Text(
                  '${voyage.departureHarbourName ?? "Harbour"} → $voyageTypeLabel',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p8),
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: AppColors.textHint),
                const SizedBox(width: AppSizes.p8),
                Expanded(
                  child: Text(
                    'Captain: ${voyage.captainName ?? "Unassigned"} | Crew: ${voyage.crewMembers.length} members',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (onEdit != null || onDelete != null) ...[
              const Divider(height: AppSizes.p24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onEdit != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onEdit!,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 6),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    ),
                  if (onEdit != null && onDelete != null) const SizedBox(width: AppSizes.p12),
                  if (onDelete != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDelete!,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outlined, size: 18),
                            SizedBox(width: 6),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}