import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_fish_market_nav_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';

class StaffDashboard extends ConsumerStatefulWidget {
  const StaffDashboard({super.key});

  @override
  ConsumerState<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends ConsumerState<StaffDashboard> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingProvider.notifier).load();
    });
  }

  String _getRoute(int idx) {
    switch (idx) {
      case 0:
        return '/staff/dashboard';
      case 1:
        return '/staff/boats';
      case 2:
        return '/staff/bills/new';
      case 3:
        return '/staff/tracking';
      case 4:
        return '/staff/profile';
      default:
        return '/staff/dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final billingState = ref.watch(billingProvider);
    final user = authState.user;

    final dateStr =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    final myBills = billingState.bills
        .where((b) => b.agentId == user?.id)
        .toList();
    final todayBills = myBills.where((b) {
      final d = b.billDate;
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    final todayAmount = todayBills.fold<double>(
      0.0,
      (s, b) => s + b.totalAmount,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.roleStaff, Color(0xFF00897B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Staff Panel',
              style: AppTextStyles.h4.copyWith(color: Colors.white),
            ),
            Text(
              dateStr,
              style: AppTextStyles.caption.copyWith(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.push('/staff/profile'),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: billingState.isLoading,
        child: RefreshIndicator(
          color: AppColors.roleStaff,
          onRefresh: () => ref.read(billingProvider.notifier).load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        title: 'Today\'s Bills',
                        value: '${todayBills.length}',
                        icon: Icons.receipt_long,
                        color: AppColors.roleStaff,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: AppMetricCard(
                        title: 'Today\'s Revenue',
                        value: '₹${todayAmount.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p16),
                Row(
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        title: 'My Total Bills',
                        value: '${myBills.length}',
                        icon: Icons.assignment,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: AppMetricCard(
                        title: 'Total Revenue',
                        value:
                            '₹${myBills.fold(0.0, (s, b) => s + b.totalAmount).toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p20),

                Text(
                  'My Bills',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.p12),
                myBills.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(AppSizes.p20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius12,
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            'No bills assigned to you',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myBills.length,
                        itemBuilder: (_, i) {
                          final bill = myBills[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSizes.p8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.p16,
                              vertical: AppSizes.p12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius12,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.roleStaff.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radius8,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.receipt,
                                    color: AppColors.roleStaff,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.p12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bill.billNumber ?? 'Bill',
                                        style: AppTextStyles.labelLarge,
                                      ),
                                      Text(
                                        'Boat: ${bill.boatName ?? ''}',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${(bill.totalAmount ?? bill.totalAmount ?? 0).toStringAsFixed(0)}',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.roleStaff,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    AppStatusBadge(
                                      label: bill.status ?? 'DRAFT',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                const SizedBox(height: AppSizes.p32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
