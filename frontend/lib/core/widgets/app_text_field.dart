import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffix,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isObscured = true;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText && _isObscured,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      readOnly: widget.readOnly,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      style: AppTextStyles.bodyMedium.copyWith(
        color: widget.enabled ? AppColors.textPrimary : AppColors.textDisabled,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        counterText: '',
        prefixIcon: widget.prefixIcon != null
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.prefixIcon,
                  size: AppSizes.iconMd,
                  color: _isFocused ? AppColors.primary : AppColors.textSecondary,
                ),
              )
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: AppSizes.iconMd,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              )
            : widget.suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSizes.p8),
                    child: widget.suffix,
                  )
                : null,
        fillColor: widget.enabled
            ? (widget.readOnly ? AppColors.background : AppColors.surface)
            : AppColors.background,
        filled: true,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: _isFocused ? AppColors.primary : AppColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}
