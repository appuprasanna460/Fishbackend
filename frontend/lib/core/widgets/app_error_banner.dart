import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

class AppErrorBanner extends StatefulWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool isDismissible;

  const AppErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.isDismissible = true,
  });

  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
        margin: const EdgeInsets.all(AppSizes.p16),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
        margin: const EdgeInsets.all(AppSizes.p16),
      ),
    );
  }

  @override
  State<AppErrorBanner> createState() => _AppErrorBannerState();
}

class _AppErrorBannerState extends State<AppErrorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      setState(() => _dismissed = true);
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(AppSizes.p16),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p12,
        ),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: Text(
                widget.message,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(width: AppSizes.p8),
              TextButton(
                onPressed: widget.onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Retry', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
              ),
            ],
            if (widget.isDismissible) ...[
              const SizedBox(width: AppSizes.p4),
              GestureDetector(
                onTap: _dismiss,
                child: const Icon(Icons.close, color: AppColors.error, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
