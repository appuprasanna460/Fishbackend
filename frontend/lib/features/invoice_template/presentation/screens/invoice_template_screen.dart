// lib/features/invoice_template/presentation/screens/invoice_template_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../providers/invoice_template_provider.dart';
import '../widgets/invoice_template_form.dart';
import '../../domain/entities/invoice_template_entity.dart';

class InvoiceTemplateScreen extends ConsumerStatefulWidget {
  const InvoiceTemplateScreen({super.key});

  @override
  ConsumerState<InvoiceTemplateScreen> createState() =>
      _InvoiceTemplateScreenState();
}

class _InvoiceTemplateScreenState extends ConsumerState<InvoiceTemplateScreen> {
  bool _showForm = false;
  InvoiceTemplateEntity? _editingTemplate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceTemplateProvider.notifier).loadAllTemplates();
      ref.read(invoiceTemplateProvider.notifier).loadActiveTemplate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceTemplateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Templates'),
        actions: [
          if (!_showForm)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _editingTemplate = null;
                setState(() => _showForm = true);
              },
              tooltip: 'Create New Template',
            ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: _showForm
            ? InvoiceTemplateForm(
                template: _editingTemplate,
                onCancel: () => setState(() => _showForm = false),
                onSaved: () {
                  setState(() => _showForm = false);
                  _editingTemplate = null;
                  ref.read(invoiceTemplateProvider.notifier).loadAllTemplates();
                  ref
                      .read(invoiceTemplateProvider.notifier)
                      .loadActiveTemplate();
                },
              )
            : _buildTemplateList(context, state),
      ),
    );
  }

  Widget _buildTemplateList(BuildContext context, InvoiceTemplateState state) {
    if (state.error != null) {
      return Center(
        child: AppErrorBanner(
          message: state.error!,
          onRetry: () {
            ref.read(invoiceTemplateProvider.notifier).loadAllTemplates();
            ref.read(invoiceTemplateProvider.notifier).loadActiveTemplate();
          },
        ),
      );
    }

    if (state.allTemplates == null || state.allTemplates!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No Invoice Templates',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first invoice template',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            // ✅ FIX: Use 'text' instead of 'label'
            AppButton(
              text: 'Create Template', // ✅ CHANGED: text instead of label
              onPressed: () {
                _editingTemplate = null;
                setState(() => _showForm = true);
              },
              leadingIcon: Icons.add, // ✅ CHANGED: leadingIcon instead of icon
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Active template indicator
        if (state.template != null)
          Container(
            margin: const EdgeInsets.all(AppSizes.p16),
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Template: ${state.template!.title}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        state.template!.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSizes.p16),
            itemCount: state.allTemplates!.length,
            itemBuilder: (_, index) {
              final template = state.allTemplates![index];
              final isActive = template.isActive;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.p12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                  side: BorderSide(
                    color: isActive ? AppColors.success : AppColors.border,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSizes.p16),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSizes.radius8),
                    ),
                    child: Icon(
                      isActive ? Icons.check_circle : Icons.description,
                      color: isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      Text(
                        template.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        template.contactDetails.phone,
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        template.address.city,
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.textHint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: AppTextStyles.caption.copyWith(
                            color: isActive
                                ? AppColors.success
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editingTemplate = template;
                          setState(() => _showForm = true);
                          break;
                        case 'toggle':
                          ref
                              .read(invoiceTemplateProvider.notifier)
                              .toggleTemplateStatus(template.id!);
                          break;
                        case 'delete':
                          _confirmDelete(context, template.id!);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.pause : Icons.play_arrow,
                              size: 18,
                              color: isActive
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _showPreviewDialog(context, template);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Template'),
        content: const Text('Are you sure you want to delete this template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(invoiceTemplateProvider.notifier).deleteTemplate(id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog(
    BuildContext context,
    InvoiceTemplateEntity template,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.title, style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              template.subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Contact:', style: AppTextStyles.labelLarge),
              Text(
                template.contactDetails.formatted,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Text('Address:', style: AppTextStyles.labelLarge),
              Text(template.address.formatted, style: AppTextStyles.bodySmall),
              const SizedBox(height: 8),
              Text('Terms & Conditions:', style: AppTextStyles.labelLarge),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  template.termsConditions,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
