import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDangerous;
  final IconData? icon;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.isDangerous = false,
    this.icon,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
        onCancel: () => Navigator.of(context, rootNavigator: true).pop(false),
        isDangerous: isDangerous,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = isDangerous ? AppColors.error : AppColors.primary;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? (isDangerous ? Icons.delete_outline : Icons.help_outline),
                size: 32,
                color: actionColor,
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.p8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel ?? () => Navigator.of(context, rootNavigator: true).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                      ),
                    ),
                    child: Text(cancelLabel, style: AppTextStyles.button.copyWith(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
                      elevation: 3,
                      shadowColor: actionColor.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                      ),
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
