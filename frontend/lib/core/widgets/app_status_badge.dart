import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppBadgeType type;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.info,
  });

  factory AppStatusBadge.fromString(String status) {
    final lower = status.toUpperCase();

    // ✅ Updated: Handle CONFIRMED and CANCELLED
    final type = switch (lower) {
      // Success types
      'ACTIVE' ||
      'PAID' ||
      'SUCCESS' ||
      'COMPLETED' ||
      'CONFIRMED' => AppBadgeType.success,

      // Error types
      'INACTIVE' ||
      'CANCELLED' ||
      'FAILED' ||
      'DELETED' ||
      'REJECTED' => AppBadgeType.error,

      // Warning types
      'PENDING' || 'PROCESSING' || 'DRAFT' => AppBadgeType.warning,

      // Role types
      'SUPER_ADMIN' => AppBadgeType.superAdmin,
      'COMMISSION_AGENT' || 'AGENT' => AppBadgeType.agent,
      'STAFF' => AppBadgeType.staff,
      'BOAT_OWNER' || 'OWNER' => AppBadgeType.owner,

      // Default
      _ => AppBadgeType.info,
    };
    return AppStatusBadge(label: status, type: type);
  }

  Color get _bgColor => switch (type) {
    AppBadgeType.success => AppColors.successLight,
    AppBadgeType.error => AppColors.errorLight,
    AppBadgeType.warning => AppColors.warningLight,
    AppBadgeType.danger => AppColors.errorLight,
    AppBadgeType.info => AppColors.infoLight,
    AppBadgeType.superAdmin => const Color(0xFFF3E5F5),
    AppBadgeType.agent => const Color(0xFFFFF3E0),
    AppBadgeType.staff => const Color(0xFFE0F2F1),
    AppBadgeType.owner => AppColors.primarySurface,
  };

  Color get _textColor => switch (type) {
    AppBadgeType.success => AppColors.success,
    AppBadgeType.error => AppColors.error,
    AppBadgeType.warning => AppColors.warning,
    AppBadgeType.danger => AppColors.error,
    AppBadgeType.info => AppColors.info,
    AppBadgeType.superAdmin => AppColors.roleSuperAdmin,
    AppBadgeType.agent => AppColors.roleAgent,
    AppBadgeType.staff => AppColors.roleStaff,
    AppBadgeType.owner => AppColors.roleOwner,
  };

  @override
  Widget build(BuildContext context) {
    // ✅ Format label for display
    String displayLabel = label.replaceAll('_', ' ');

    // Capitalize properly
    if (displayLabel.length > 2) {
      displayLabel =
          displayLabel[0].toUpperCase() +
          displayLabel.substring(1).toLowerCase();
    }

    // ✅ Special formatting for specific statuses
    if (label.toUpperCase() == 'CONFIRMED') {
      displayLabel = 'Confirmed';
    } else if (label.toUpperCase() == 'CANCELLED') {
      displayLabel = 'Cancelled';
    } else if (label.toUpperCase() == 'DRAFT') {
      displayLabel = 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
        border: Border.all(color: _textColor.withOpacity(0.2)),
      ),
      child: Text(
        displayLabel,
        style: AppTextStyles.labelSmall.copyWith(
          color: _textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum AppBadgeType {
  success,
  error,
  warning,
  danger,
  info,
  superAdmin,
  agent,
  staff,
  owner,
}
