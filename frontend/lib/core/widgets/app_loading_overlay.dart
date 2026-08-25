import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.35),
          ),
        if (isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p32,
                vertical: AppSizes.p24,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AppSizes.p16),
                    Text(
                      message!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
