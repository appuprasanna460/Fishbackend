import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? actionButton;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.actionButton,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        // ✅ Add SingleChildScrollView
        padding: const EdgeInsets.all(AppSizes.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // ✅ Use min instead of max
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: (iconColor ?? AppColors.primary).withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (_, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.p8),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionButton != null) ...[
              const SizedBox(height: AppSizes.p24),
              actionButton!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.p24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p24,
                    vertical: AppSizes.p12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
