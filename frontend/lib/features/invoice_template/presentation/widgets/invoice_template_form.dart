// lib/features/invoice_template/presentation/widgets/invoice_template_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/invoice_template_provider.dart';
import '../../domain/entities/invoice_template_entity.dart';

class InvoiceTemplateForm extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSaved;
  final InvoiceTemplateEntity? template;

  const InvoiceTemplateForm({
    super.key,
    required this.onCancel,
    required this.onSaved,
    this.template,
  });

  @override
  ConsumerState<InvoiceTemplateForm> createState() =>
      _InvoiceTemplateFormState();
}

class _InvoiceTemplateFormState extends ConsumerState<InvoiceTemplateForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _termsController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _countryController;
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    _titleController = TextEditingController(
      text: template?.title ?? 'INVOICE',
    );
    _subtitleController = TextEditingController(
      text: template?.subtitle ?? 'Fish Market - Official Receipt',
    );
    _termsController = TextEditingController(
      text:
          template?.termsConditions ??
          '1. Goods once sold will not be taken back.\n2. Payment must be made within 7 days.\n3. All disputes subject to local jurisdiction.',
    );
    _phoneController = TextEditingController(
      text: template?.contactDetails.phone ?? '+91 9876543210',
    );
    _emailController = TextEditingController(
      text: template?.contactDetails.email ?? 'contact@fishmarket.com',
    );
    _websiteController = TextEditingController(
      text: template?.contactDetails.website ?? 'www.fishmarket.com',
    );
    _streetController = TextEditingController(
      text: template?.address.street ?? '123, Fish Market Road',
    );
    _cityController = TextEditingController(
      text: template?.address.city ?? 'Mumbai',
    );
    _stateController = TextEditingController(
      text: template?.address.state ?? 'Maharashtra',
    );
    _pincodeController = TextEditingController(
      text: template?.address.pincode ?? '400001',
    );
    _countryController = TextEditingController(
      text: template?.address.country ?? 'India',
    );
    _footerController = TextEditingController(
      text: template?.footer ?? 'Thank you for your business!',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _termsController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final template = InvoiceTemplateEntity(
      id: widget.template?.id,
      title: _titleController.text,
      subtitle: _subtitleController.text,
      termsConditions: _termsController.text,
      contactDetails: ContactDetails(
        phone: _phoneController.text,
        email: _emailController.text,
        website: _websiteController.text,
      ),
      address: Address(
        street: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        country: _countryController.text,
      ),
      footer: _footerController.text,
      isActive: widget.template?.isActive ?? true,
    );

    final success = await ref
        .read(invoiceTemplateProvider.notifier)
        .saveTemplate(template);
    if (success && mounted) {
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceTemplateProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.template == null ? 'Create Template' : 'Edit Template',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppSizes.p24),

            // Title
            AppTextField(
              controller: _titleController,
              label: 'Invoice Title',
              hint: 'Enter invoice title (e.g., INVOICE)',
              validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: AppSizes.p12),

            // Subtitle
            AppTextField(
              controller: _subtitleController,
              label: 'Subtitle',
              hint: 'Enter subtitle (e.g., Fish Market - Official Receipt)',
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Subtitle is required' : null,
            ),
            const SizedBox(height: AppSizes.p12),

            // Terms & Conditions
            AppTextField(
              controller: _termsController,
              label: 'Terms & Conditions',
              hint: 'Enter terms and conditions',
              maxLines: 4,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Terms are required' : null,
            ),
            const SizedBox(height: AppSizes.p16),

            const Divider(),
            const SizedBox(height: AppSizes.p8),
            Text(
              'Contact Details',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.p12),

            AppTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter contact phone number',
              validator: (v) => v?.isEmpty ?? true ? 'Phone is required' : null,
            ),
            const SizedBox(height: AppSizes.p12),

            AppTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter contact email',
            ),
            const SizedBox(height: AppSizes.p12),

            AppTextField(
              controller: _websiteController,
              label: 'Website',
              hint: 'Enter website URL',
            ),
            const SizedBox(height: AppSizes.p16),

            const Divider(),
            const SizedBox(height: AppSizes.p8),
            Text(
              'Address',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.p12),

            AppTextField(
              controller: _streetController,
              label: 'Street Address',
              hint: 'Enter street address',
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Street is required' : null,
            ),
            const SizedBox(height: AppSizes.p12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Enter city',
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'City is required' : null,
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: AppTextField(
                    controller: _stateController,
                    label: 'State',
                    hint: 'Enter state',
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'State is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _pincodeController,
                    label: 'Pincode',
                    hint: 'Enter pincode',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Pincode is required' : null,
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: AppTextField(
                    controller: _countryController,
                    label: 'Country',
                    hint: 'Enter country',
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Country is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p16),

            const Divider(),
            const SizedBox(height: AppSizes.p8),
            Text(
              'Footer',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.p12),

            AppTextField(
              controller: _footerController,
              label: 'Footer Text',
              hint: 'Enter footer message',
              maxLines: 2,
            ),
            const SizedBox(height: AppSizes.p24),

            // ✅ FIXED: AppButton with correct parameters
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel', // ✅ CHANGED: label → text
                    onPressed: widget.onCancel,
                    variant: AppButtonVariant
                        .secondary, // ✅ CHANGED: ButtonVariant → AppButtonVariant
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: AppButton(
                    text: state.isSaving
                        ? 'Saving...'
                        : 'Save Template', // ✅ CHANGED: label → text
                    onPressed: state.isSaving ? null : _save,
                    isLoading: state.isSaving,
                  ),
                ),
              ],
            ),

            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.p12),
                child: Text(
                  state.error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
