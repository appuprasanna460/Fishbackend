import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authProvider.notifier)
        .changePassword(_currentCtrl.text, _newCtrl.text, _confirmCtrl.text);
    if (success && mounted) {
      AppErrorBanner.showSuccess(context, 'Password changed successfully!');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.p16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      AppColors.secondary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radius16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.p12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset,
                          color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: AppSizes.p16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Update Password', style: AppTextStyles.h4),
                          const SizedBox(height: AppSizes.p4),
                          Text(
                            'Choose a strong password with at least 8 characters.',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p24),
              if (authState.errorMessage != null) ...[
                AppErrorBanner(
                  message: authState.errorMessage!,
                  onDismiss: () =>
                      ref.read(authProvider.notifier).clearError(),
                ),
                const SizedBox(height: AppSizes.p16),
              ],
              AppTextField(
                label: 'Current Password',
                controller: _currentCtrl,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSizes.p16),
              AppTextField(
                label: 'New Password',
                controller: _newCtrl,
                obscureText: true,
                prefixIcon: Icons.lock_open_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'Minimum 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p16),
              AppTextField(
                label: 'Confirm New Password',
                controller: _confirmCtrl,
                obscureText: true,
                prefixIcon: Icons.check_circle_outline,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onSubmit(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != _newCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p32),
              AppButton(
                text: 'Update Password',
                onPressed: authState.isLoading ? null : _onSubmit,
                isLoading: authState.isLoading,
                leadingIcon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
