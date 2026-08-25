import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class VoyageStatusBadge extends StatelessWidget {
  final String status;

  const VoyageStatusBadge({super.key, required this.status});

  Color _getStatusColor() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'COMPLETED':
        return AppColors.info;
      case 'CANCELLED':
        return AppColors.error;
      case 'PLANNED':
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusBgColor() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.successLight;
      case 'COMPLETED':
        return AppColors.infoLight;
      case 'CANCELLED':
        return AppColors.errorLight;
      case 'PLANNED':
      default:
        return AppColors.primarySurface;
    }
  }

  String _getStatusText() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'ACTIVE';
      case 'COMPLETED':
        return 'COMPLETED';
      case 'CANCELLED':
        return 'CANCELLED';
      case 'PLANNED':
      default:
        return 'PLANNED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBgColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withOpacity(0.3), width: 1),
      ),
      child: Text(
        _getStatusText(),
        style: AppTextStyles.labelSmall.copyWith(
          color: _getStatusColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
