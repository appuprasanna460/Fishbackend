import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';

class WizardStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepNames;

  const WizardStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 6,
    required this.stepNames,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isActive = index == currentStep;

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.primary
                          : isActive
                              ? AppColors.primary
                              : Colors.white,
                      border: Border.all(
                        color: isCompleted || isActive
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : Text(
                              '${index + 1}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (index < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? AppColors.primary : AppColors.border,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: AppSizes.p8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              stepNames[currentStep],
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
