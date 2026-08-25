import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../providers/ledger_provider.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ledgerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerProvider);

    final filteredBalances = state.balances.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.boatName.toLowerCase().contains(q) || b.boatNumber.toLowerCase().contains(q);
    }).toList();

    double totalCredit = 0;
    double totalDebit = 0;
    for (var b in state.balances) {
      totalCredit += b.totalCredit;
      totalDebit += b.totalDebit;
    }
    double netBalance = totalCredit - totalDebit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ledgerProvider.notifier).load(),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: Column(
          children: [
            // Ledger summary header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Outstanding Balance',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${netBalance.toStringAsFixed(2)}',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryDetail('Total Credits', '₹${totalCredit.toStringAsFixed(2)}', AppColors.successLight),
                      _summaryDetail('Total Debits', '₹${totalDebit.toStringAsFixed(2)}', AppColors.errorLight),
                    ],
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search boat balance record...',
                  prefixIcon: const Icon(Icons.search, size: AppSizes.iconMd),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: AppSizes.p16),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredBalances.isEmpty
                  ? const AppEmptyState(
                      title: 'No Ledger Balances',
                      subtitle: 'Register boats and billing transactions to calculate ledger entries.',
                      icon: Icons.account_balance_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      itemCount: filteredBalances.length,
                      itemBuilder: (_, idx) {
                        final record = filteredBalances[idx];
                        final isCredit = record.balance >= 0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.p12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radius12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(AppSizes.p16),
                            leading: Container(
                              padding: const EdgeInsets.all(AppSizes.p8),
                              decoration: BoxDecoration(
                                color: isCredit ? AppColors.successSurface : AppColors.errorSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                                color: isCredit ? AppColors.success : AppColors.error,
                              ),
                            ),
                            title: Text(
                              record.boatName,
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Reg No: ${record.boatNumber}', style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 2),
                                Text(
                                  'C: ₹${record.totalCredit.toStringAsFixed(0)} | D: ₹${record.totalDebit.toStringAsFixed(0)}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '₹${record.balance.toStringAsFixed(2)}',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: isCredit ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => context.push('/agent/ledger/boat/${record.boatId}'),
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

  Widget _summaryDetail(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.surface.withOpacity(0.7))),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
