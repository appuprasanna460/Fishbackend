import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final double elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.onTap,
    this.boxShadow,
    this.border,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSizes.radius16;
    final cardColor = color ?? AppColors.cardBackground;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: AppColors.border.withOpacity(0.5), width: 0.5),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: elevation * 4,
                offset: Offset(0, elevation),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.primary.withOpacity(0.05),
          highlightColor: AppColors.primary.withOpacity(0.03),
          child: card,
        ),
      );
    }

    return card;
  }
}

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Color glassColor;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.glassColor = AppColors.glassBackground,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSizes.radius16;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
