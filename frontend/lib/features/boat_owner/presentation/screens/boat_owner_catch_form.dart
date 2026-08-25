import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../providers/catch_provider.dart';
import '../providers/haul_provider.dart';

class BoatOwnerCatchForm extends ConsumerStatefulWidget {
  final String haulId;

  const BoatOwnerCatchForm({super.key, required this.haulId});

  @override
  ConsumerState<BoatOwnerCatchForm> createState() => _BoatOwnerCatchFormState();
}

class _BoatOwnerCatchFormState extends ConsumerState<BoatOwnerCatchForm> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _speciesCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _boxesCtrl = TextEditingController();
  final TextEditingController _sharePercentageCtrl = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _speciesCtrl.dispose();
    _weightCtrl.dispose();
    _boxesCtrl.dispose();
    _sharePercentageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    
    // Get the haul from either activeHaul or the hauls list
    final haulState = ref.read(haulProvider);
    final activeHaul = haulState.activeHaul;
    final haulFromList = haulState.hauls.where((h) => h.id == widget.haulId).firstOrNull;
    
    // Use activeHaul if it matches, otherwise use the haul from the list
    final haul = (activeHaul != null && activeHaul.id == widget.haulId) 
        ? activeHaul 
        : haulFromList;
    
    if (haul == null) {
      AppErrorBanner.show(context, 'Haul not found.');
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      await ref.read(catchProvider.notifier).createCatch({
        'haulId': widget.haulId,
        'voyageId': haul.voyageId,
        'species': _speciesCtrl.text.trim(),
        'weight': double.tryParse(_weightCtrl.text.trim()) ?? 0.0,
        'boxes': int.tryParse(_boxesCtrl.text.trim()) ?? 0,
        'sharePercentage': double.tryParse(_sharePercentageCtrl.text.trim()) ?? 0.0,
      });
      
      if (mounted) {
        AppErrorBanner.showSuccess(context, 'Catch recorded successfully');
        // Refresh the hauls list to reflect the COMPLETED status
        await ref.read(haulProvider.notifier).fetchHauls(voyageId: haul.voyageId);
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppErrorBanner.show(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Catch'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('FISH SPECIES'),
              TextFormField(
                controller: _speciesCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g., Tuna, Mackerel',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSizes.p24),

              _buildLabel('WEIGHT (KG)'),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.0',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p24),

              _buildLabel('NUMBER OF BOXES'),
              TextFormField(
                controller: _boxesCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Invalid integer';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p24),

              _buildLabel('SHARE PERCENTAGE (%)'),
              TextFormField(
                controller: _sharePercentageCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0 - 100',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final val = double.tryParse(v);
                  if (val == null) return 'Invalid number';
                  if (val < 0 || val > 100) return 'Must be between 0 and 100';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p32),

              AppButton(
                text: 'Save Catch',
                isLoading: _isSubmitting,
                onPressed: _submit,
                backgroundColor: AppColors.primary,
                leadingIcon: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p8),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
