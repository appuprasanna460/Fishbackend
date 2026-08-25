import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../providers/ledger_provider.dart';
import 'package:HarbourPro/features/boats/presentation/providers/boat_provider.dart';

class BoatBalanceScreen extends ConsumerStatefulWidget {
  final String boatId;
  const BoatBalanceScreen({super.key, required this.boatId});

  @override
  ConsumerState<BoatBalanceScreen> createState() => _BoatBalanceScreenState();
}

class _BoatBalanceScreenState extends ConsumerState<BoatBalanceScreen> {
  final _fmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatProvider.notifier).loadById(widget.boatId);
      ref.read(ledgerProvider.notifier).load(boatId: widget.boatId);
      ref.read(ledgerProvider.notifier).loadBoatBalance(widget.boatId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerProvider);
    final boatState = ref.watch(boatProvider);
    final boat = boatState.selected;

    final balanceInfo = state.selectedBalance;

    return Scaffold(
      appBar: AppBar(
        title: Text(boat != null ? '${boat.boatName} Ledger' : 'Boat Ledger'),
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: Column(
          children: [
            // Net Balance Banner
            if (balanceInfo != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.p20),
                color: AppColors.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remaining Balance',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${balanceInfo.balance.toStringAsFixed(2)}',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: balanceInfo.balance >= 0
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Credits: ₹${balanceInfo.totalCredit.toStringAsFixed(0)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Debits: ₹${balanceInfo.totalDebit.toStringAsFixed(0)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            // Ledger Entries List
            Expanded(
              child: state.entries.isEmpty
                  ? const AppEmptyState(
                      title: 'No Ledger Entries',
                      subtitle: 'Transactions for this boat will show up here.',
                      icon: Icons.receipt_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      itemCount: state.entries.length,
                      itemBuilder: (_, idx) {
                        final entry = state.entries[idx];
                        final isCredit = entry.isCredit;
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.p12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius12,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.p16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSizes.p8),
                                  decoration: BoxDecoration(
                                    color: isCredit
                                        ? AppColors.successSurface
                                        : AppColors.errorSurface,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radius8,
                                    ),
                                  ),
                                  child: Text(
                                    isCredit ? 'CREDIT' : 'DEBIT',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: isCredit
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.p16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.description,
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _fmt.format(entry.date),
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isCredit ? "+" : "-"} ₹${entry.amount.toStringAsFixed(2)}',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: isCredit
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Bal: ₹${entry.runningBalance.toStringAsFixed(2)}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
}
