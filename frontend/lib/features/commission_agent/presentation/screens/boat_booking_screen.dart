import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_searchable_dropdown.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';

class BookBoatScreen extends ConsumerStatefulWidget {
  const BookBoatScreen({super.key});

  @override
  ConsumerState<BookBoatScreen> createState() => _BookBoatScreenState();
}

class _BookBoatScreenState extends ConsumerState<BookBoatScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBoatId;
  DateTime? _bookingDate;
  String _purpose = 'Fishing';
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _purposes = [
    'Fishing',
    'Transport',
    'Maintenance',
    'Other',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBoatId == null) {
      AppErrorBanner.show(context, 'Please select a boat');
      return;
    }

    setState(() => _isSubmitting = true);

    await ref.read(billingProvider.notifier).createBill({
      'boatId': _selectedBoatId,
      'billDate':
          _bookingDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'fishEntries': [],
      'notes': 'BOOKING: ${_notesCtrl.text}',
      'bookingType': _purpose,
    });

    setState(() => _isSubmitting = false);

    if (mounted) {
      AppErrorBanner.showSuccess(context, 'Boat booked successfully!');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        top: AppSizes.p24,
        left: AppSizes.p16,
        right: AppSizes.p16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.p16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Book a Boat',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p16),

            Text('Available Boats', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSizes.p8),
            AppSearchableDropdown<String>(
              label: 'Select Boat',
              items: boatState.boats
                  .where((b) => b.isActive)
                  .map((b) => b.id)
                  .toList(),
              value: _selectedBoatId,
              onChanged: (v) => setState(() => _selectedBoatId = v),
              itemLabel: (id) {
                final boat = boatState.boats.firstWhere(
                  (b) => b.id == id,
                  orElse: () => boatState.boats.first,
                );
                return '${boat.boatName} (${boat.boatNumber})';
              },
              hint: 'Select a boat',
            ),
            const SizedBox(height: AppSizes.p16),

            if (_selectedBoatId != null)
              _BoatInfoCard(boatId: _selectedBoatId!),
            const SizedBox(height: AppSizes.p16),

            Text('Booking Date', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSizes.p8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => _bookingDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(AppSizes.p14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Text(
                      _bookingDate != null
                          ? '${_bookingDate!.day}/${_bookingDate!.month}/${_bookingDate!.year}'
                          : 'Select booking date',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _bookingDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p16),

            Text('Purpose', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSizes.p8),
            ..._purposes.map((p) {
              final isSelected = _purpose == p;
              return GestureDetector(
                onTap: () => setState(() => _purpose = p),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSizes.p8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p14,
                    vertical: AppSizes.p12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primarySurface
                        : AppColors.surface,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSizes.p12),
                      Text(p, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSizes.p16),

            AppTextField(
              label: 'Notes (Optional)',
              controller: _notesCtrl,
              maxLines: 3,
              prefixIcon: Icons.notes_outlined,
            ),
            const SizedBox(height: AppSizes.p24),

            AppButton(
              text: 'Confirm Booking',
              onPressed: _submit,
              isLoading: _isSubmitting,
              leadingIcon: Icons.check_circle_outline,
            ),
            const SizedBox(height: AppSizes.p8),
          ],
        ),
      ),
    );
  }
}

class _BoatInfoCard extends ConsumerWidget {
  final String boatId;
  const _BoatInfoCard({required this.boatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boatState = ref.watch(boatProvider);
    final boat = boatState.boats.firstWhere(
      (b) => b.id == boatId,
      orElse: () => boatState.boats.first,
    );

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSizes.radius12),
            ),
            child: Icon(
              Icons.directions_boat,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boat.boatName,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Reg: ${boat.registrationNumber ?? boat.boatNumber}',
                  style: AppTextStyles.bodySmall,
                ),
                if (boat.ownerName.isNotEmpty)
                  Text(
                    'Owner: ${boat.ownerName}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
            ),
            child: Text(
              'Available',
              style: AppTextStyles.overline.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
