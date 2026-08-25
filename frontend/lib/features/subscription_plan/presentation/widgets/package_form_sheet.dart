// lib/features/subscription_plan/presentation/widgets/package_form_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../providers/subscription_plan_provider.dart';
import '../../domain/entities/subscription_plan_entity.dart';

class PackageFormSheet extends ConsumerStatefulWidget {
  final SubscriptionPlanEntity? plan;

  const PackageFormSheet({super.key, this.plan});

  @override
  ConsumerState<PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends ConsumerState<PackageFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _featuresCtrl;
  late final TextEditingController _durationDaysCtrl;
  late bool _isActive;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _nameCtrl = TextEditingController(text: plan?.name ?? '');
    _priceCtrl = TextEditingController(
      text: plan != null ? plan.price.toStringAsFixed(0) : '',
    );
    _featuresCtrl = TextEditingController(
      text: plan?.features.join(', ') ?? '',
    );
    // Use existing durationDays or default to empty
    _durationDaysCtrl = TextEditingController(
      text: plan != null && plan.durationDays > 0
          ? plan.durationDays.toString()
          : '',
    );
    _isActive = plan?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _featuresCtrl.dispose();
    _durationDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final plan = SubscriptionPlanEntity(
      id: widget.plan?.id,
      name: _nameCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      durationDays: int.tryParse(_durationDaysCtrl.text.trim()) ?? 0,
      isActive: _isActive,
      features: _featuresCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

    final state = ref.read(subscriptionPlanProvider.notifier);
    final ok = _isEditing
        ? await state.updatePlan(plan)
        : await state.createPlan(plan);

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? _isEditing
                  ? 'Package updated successfully'
                  : 'Package created successfully'
              : 'Failed to save package'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionPlanProvider);
    final isSaving = state.isSaving;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p20),
              Text(
                _isEditing ? 'Edit Package' : 'Create New Package',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSizes.p4),
              Text(
                _isEditing
                    ? 'Update the subscription package details'
                    : 'Add a new subscription package for users',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.p24),

              // Name
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: _inputDeco('Package Name', Icons.card_giftcard_rounded),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Package name is required'
                    : null,
              ),
              const SizedBox(height: AppSizes.p16),

              // Price
              TextFormField(
                controller: _priceCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                keyboardType: TextInputType.number,
                decoration: _inputDeco('Price (₹)', Icons.currency_rupee_rounded),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  final price = double.tryParse(v.trim());
                  if (price == null || price < 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p16),

              // Duration in Days
              TextFormField(
                controller: _durationDaysCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                keyboardType: TextInputType.number,
                decoration: _inputDeco(
                  'Duration (Days)',
                  Icons.calendar_today_rounded,
                  hintText: 'e.g. 90 for 3 months, 365 for a year',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Duration is required';
                  }
                  final days = int.tryParse(v.trim());
                  if (days == null || days < 1) {
                    return 'Enter a valid number of days (minimum 1)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p16),

              // Features
              TextFormField(
                controller: _featuresCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                maxLines: 3,
                decoration: _inputDeco(
                  'Features (comma separated)',
                  Icons.list_alt_rounded,
                  hintText: 'e.g. Unlimited bills, Boat tracking, Reports',
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // Active toggle
              Container(
                padding: const EdgeInsets.all(AppSizes.p12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isActive ? Icons.check_circle : Icons.cancel,
                      color: _isActive ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Text(
                        _isActive ? 'Active' : 'Inactive',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: _isActive ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Package' : 'Create Package',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.p8),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FF),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p14,
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p8,
            vertical: AppSizes.p10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}