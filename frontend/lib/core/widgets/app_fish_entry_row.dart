import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';
import 'app_text_field.dart';

class AppFishEntryRow<T> extends StatelessWidget {
  final T? selectedFish;
  final List<T> fishList;
  final String Function(T) fishLabel;
  final void Function(T) onFishSelected;
  final TextEditingController weightController;
  final TextEditingController rateController;
  final VoidCallback onRemove;
  final double totalAmount;
  final int index;

  const AppFishEntryRow({
    super.key,
    required this.selectedFish,
    required this.fishList,
    required this.fishLabel,
    required this.onFishSelected,
    required this.weightController,
    required this.rateController,
    required this.onRemove,
    required this.totalAmount,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                Expanded(
                  child: Text(
                    'Fish Entry ${index + 1}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Remove entry',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              child: DropdownButton<T>(
                value: selectedFish,
                hint: Text(
                  'Select a fish...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                items: fishList.isEmpty
                    ? [
                        DropdownMenuItem<T>(
                          value: null,
                          enabled: false,
                          child: Text(
                            'No fish available',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ]
                    : fishList.map((fish) {
                        final label = fishLabel(fish);
                        return DropdownMenuItem<T>(
                          value: fish,
                          child: Text(
                            label,
                            style: AppTextStyles.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onFishSelected(value);
                  }
                },
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
                dropdownColor: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius12),
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Weight (kg)',
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,3}'),
                      ),
                    ],
                    prefixIcon: Icons.monitor_weight_outlined,
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: AppTextField(
                    label: 'Rate (₹/kg)',
                    controller: rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    prefixIcon: Icons.currency_rupee_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p10,
              ),
              decoration: BoxDecoration(
                color: totalAmount > 0
                    ? AppColors.successLight
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₹ ${totalAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.h4.copyWith(
                      color: totalAmount > 0
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
