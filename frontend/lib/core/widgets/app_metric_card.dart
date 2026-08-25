import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';
import 'app_card.dart';

class AppMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? trend;
  final VoidCallback? onTap;
  final bool isLoading;

  const AppMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSizes.p16),
      child: isLoading
          ? _buildSkeleton()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.p10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                      ),
                      child: Icon(icon, color: color, size: AppSizes.iconLg),
                    ),
                    if (trend != null) _buildTrendBadge(),
                  ],
                ),
                const SizedBox(height: AppSizes.p12),
                Text(
                  value,
                  style: AppTextStyles.metricValue.copyWith(color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.p4),
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSizes.p4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildTrendBadge() {
    final isPositive = trend! >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSizes.radius24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: isPositive ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 2),
          Text(
            '${trend!.abs().toStringAsFixed(1)}%',
            style: AppTextStyles.caption.copyWith(
              color: isPositive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SkeletonBox(width: 48, height: 48, radius: AppSizes.radius12),
            _SkeletonBox(width: 60, height: 22, radius: AppSizes.radius24),
          ],
        ),
        const SizedBox(height: AppSizes.p12),
        const _SkeletonBox(width: 80, height: 28),
        const SizedBox(height: AppSizes.p8),
        const _SkeletonBox(width: 120, height: 14),
      ],
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
