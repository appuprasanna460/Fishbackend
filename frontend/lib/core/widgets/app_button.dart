import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

enum AppButtonVariant { primary, secondary, outlined, ghost, danger }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = AppSizes.buttonHeight,
    this.borderRadius = AppSizes.radius12,
    this.backgroundColor,
  });

  const AppButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = AppSizes.buttonHeight,
    this.borderRadius = AppSizes.radius12,
    this.backgroundColor,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = AppSizes.buttonHeight,
    this.borderRadius = AppSizes.radius12,
    this.backgroundColor,
  }) : variant = AppButtonVariant.danger;

  const AppButton.ghost({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = AppSizes.buttonHeight,
    this.borderRadius = AppSizes.radius12,
    this.backgroundColor,
  }) : variant = AppButtonVariant.ghost;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  Color get _backgroundColor {
    if (_isDisabled) return AppColors.border;
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    return switch (widget.variant) {
      AppButtonVariant.primary => AppColors.primary,
      AppButtonVariant.secondary => AppColors.secondary,
      AppButtonVariant.outlined => Colors.transparent,
      AppButtonVariant.ghost => Colors.transparent,
      AppButtonVariant.danger => AppColors.error,
    };
  }

  Color get _foregroundColor {
    if (_isDisabled) return AppColors.textDisabled;
    return switch (widget.variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary => Colors.white,
      AppButtonVariant.outlined => AppColors.primary,
      AppButtonVariant.ghost => AppColors.primary,
      AppButtonVariant.danger => Colors.white,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = _isDisabled
        ? _buildContent()
        : GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (_, c) => Transform.scale(scale: _scaleAnimation.value, child: c),
              child: _buildContent(),
            ),
          );

    final bool isOutlined = widget.variant == AppButtonVariant.outlined;
    final bool isGhost = widget.variant == AppButtonVariant.ghost;

    if (isOutlined) {
      return SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: OutlinedButton(
          onPressed: _isDisabled ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _foregroundColor,
            side: BorderSide(color: _isDisabled ? AppColors.border : AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
          child: child,
        ),
      );
    }

    if (isGhost) {
      return SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: TextButton(
          onPressed: _isDisabled ? null : widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: _foregroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: ElevatedButton(
        onPressed: _isDisabled ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _backgroundColor,
          foregroundColor: _foregroundColor,
          elevation: _isDisabled ? 0 : 3,
          shadowColor: _backgroundColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
        ),
      );
    }

    final List<Widget> children = [];
    if (widget.leadingIcon != null) {
      children.addAll([
        Icon(widget.leadingIcon, size: 18, color: _foregroundColor),
        const SizedBox(width: 8),
      ]);
    }
    children.add(
      Flexible(
        child: Text(
          widget.text,
          style: AppTextStyles.button.copyWith(color: _foregroundColor),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
    if (widget.trailingIcon != null) {
      children.addAll([
        const SizedBox(width: 8),
        Icon(widget.trailingIcon, size: 18, color: _foregroundColor),
      ]);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
