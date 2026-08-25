import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/haul_entity.dart';

class HaulCard extends StatelessWidget {
  final HaulEntity haul;
  final VoidCallback onTap;

  const HaulCard({
    super.key,
    required this.haul,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = haul.status == 'ACTIVE';
    final isStopped = haul.status == 'STOPPED';
    final color = isActive ? Colors.blue : (isStopped ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.shade200, width: isActive ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: color.shade50,
                        child: Icon(Icons.set_meal, color: color, size: 18),
                      ),
                      const SizedBox(width: AppSizes.p12),
                      Text(
                        'Haul #${haul.haulNumber}',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      haul.status,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Text(
                    haul.fishingGround,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Text(
                    'Started: ${DateFormat('MMM d, HH:mm').format(haul.startedAt)}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
