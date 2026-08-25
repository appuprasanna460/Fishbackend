import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

class AppLocationPicker extends StatelessWidget {
  final String label;
  final String? selectedValue;
  final List<String> options;
  final void Function(String?) onChanged;
  final bool isLoading;
  final String? Function(String?)? validator;
  final IconData icon;

  const AppLocationPicker({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    this.isLoading = false,
    this.validator,
    this.icon = Icons.location_on_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      validator: validator,
      onChanged: isLoading ? null : onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.surface,
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
      ),
      items: options.isEmpty
          ? [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'No options available',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                ),
              )
            ]
          : options
              .map((opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text(opt, style: AppTextStyles.bodyMedium),
                  ))
              .toList(),
      style: AppTextStyles.bodyMedium,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
      dropdownColor: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radius12),
    );
  }
}
