import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../providers/billing_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';

class BillListScreen extends ConsumerStatefulWidget {
  const BillListScreen({super.key});

  @override
  ConsumerState<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends ConsumerState<BillListScreen> {
  String? _selectedStatus;
  String? _selectedBoatId;
  final _fmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingProvider.notifier).load();
      ref.read(boatProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final state = ref.watch(billingProvider);
    final bills = state.bills.where((b) {
      final statusMatch = _selectedStatus == null || b.status == _selectedStatus;
      final boatMatch = _selectedBoatId == null || b.boatId == _selectedBoatId;
      return statusMatch && boatMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(billingProvider.notifier).load()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/agent/bills/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: Column(
          children: [
            // Filter chips
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', null),
                    const SizedBox(width: AppSizes.p8),
                    _filterChip('Pending', 'PENDING'),
                    const SizedBox(width: AppSizes.p8),
                    _filterChip('Paid', 'PAID'),
                    const SizedBox(width: AppSizes.p8),
                    _filterChip('Overdue', 'OVERDUE'),
                  ],
                ),
              ),
            ),
            // Boat filter dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
              child: DropdownButtonFormField<String?>(
                value: _selectedBoatId,
                decoration: InputDecoration(
                  labelText: 'Filter by Boat',
                  prefixIcon: const Icon(Icons.directions_boat_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radius12)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Boats')),
                  ...boatState.boats.where((b) => b.isActive).map((boat) => DropdownMenuItem(
                    value: boat.id,
                    child: Text('${boat.boatName} (${boat.boatNumber})'),
                  )),
                ],
                onChanged: (v) => setState(() => _selectedBoatId = v),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: bills.isEmpty
                  ? const AppEmptyState(title: 'No Bills Found', subtitle: 'Create your first billing record', icon: Icons.receipt_long_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      itemCount: bills.length,
                      itemBuilder: (_, i) {
                        final bill = bills[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.p12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppSizes.radius16),
                            onTap: () => context.push('/agent/bills/${bill.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.p16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(bill.billNumber, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                                      AppStatusBadge.fromString(bill.status),
                                    ],
                                  ),
                                  const SizedBox(height: AppSizes.p8),
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_boat_outlined, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(bill.boatName.isNotEmpty ? '${bill.boatName} (${bill.boatNumber})' : bill.boatNumber, style: AppTextStyles.bodyMedium),
                                    ],
                                  ),
                                  const SizedBox(height: AppSizes.p4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_fmt.format(bill.billDate), style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                      Text('₹ ${bill.netAmount.toStringAsFixed(2)}', style: AppTextStyles.h4.copyWith(color: AppColors.success)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatus = value),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: AppTextStyles.labelSmall.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusCircular)),
    );
  }
}
