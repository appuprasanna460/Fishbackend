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
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../../../fish_buyer/presentation/providers/fish_buyer_bill_provider.dart';

class CommissionAgentDashboard extends ConsumerStatefulWidget {
  const CommissionAgentDashboard({super.key});

  @override
  ConsumerState<CommissionAgentDashboard> createState() =>
      _CommissionAgentDashboardState();
}

class _CommissionAgentDashboardState
    extends ConsumerState<CommissionAgentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatProvider.notifier).load();
      ref.read(billingProvider.notifier).load();
      ref.read(fishBuyerBillProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final boatState = ref.watch(boatProvider);
    final billingState = ref.watch(billingProvider);
    final fishBuyerBillState = ref.watch(fishBuyerBillProvider);
    final user = authState.user;

    final dateStr =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    // ✅ Get today's date range
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // ✅ Today's CONFIRMED bills
    final todayBills = billingState.bills.where((b) {
      final billDate = b.billDate;
      final isToday =
          billDate.isAfter(todayStart) && billDate.isBefore(todayEnd);
      final isConfirmed = b.status == 'CONFIRMED';
      return isToday && isConfirmed;
    }).toList();

    // ✅ All CONFIRMED bills
    final allConfirmedBills = billingState.bills.where((b) {
      return b.status == 'CONFIRMED';
    }).toList();

    // ✅ Calculate revenues
    final todayRevenue = todayBills.fold<double>(
      0.0,
      (sum, b) => sum + (b.netAmount ?? 0),
    );
    final totalRevenue = allConfirmedBills.fold<double>(
      0.0,
      (sum, b) => sum + (b.netAmount ?? 0),
    );

    // ✅ My boats
    final myBoats = boatState.boats
        .where((b) => b.agentId == user?.id && b.isActive)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agent Dashboard',
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
            onPressed: () => context.push('/agent/profile'),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: boatState.isLoading || billingState.isLoading,
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () async {
            await ref.read(boatProvider.notifier).load();
            await ref.read(billingProvider.notifier).load();
            await ref.read(fishBuyerBillProvider.notifier).load();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Row 1: Today Revenue + Today Bills
                Row(
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        title: 'Today Revenue',
                        value: '₹${todayRevenue.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: AppMetricCard(
                        title: 'Today Bills',
                        value: '${todayBills.length}',
                        icon: Icons.receipt_long,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p16),

                // ✅ Row 2: My Boats + Total Revenue
                Row(
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        title: 'My Boats',
                        value: '${myBoats.length}',
                        icon: Icons.directions_boat,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: AppMetricCard(
                        title: 'Total Revenue',
                        value: '₹${totalRevenue.toStringAsFixed(0)}',
                        icon: Icons.bar_chart,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p20),

                // ✅ Quick Actions - 3 cards in a row (smaller width)
                Text(
                  'Quick Actions',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.p12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: 'Book Boat',
                        subtitle: 'Book a boat',
                        icon: Icons.directions_boat,
                        color: AppColors.primary,
                        onTap: () => context.push('/agent/boats'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Expanded(
                      child: _ActionCard(
                        title: 'New Bill',
                        subtitle: 'Create billing',
                        icon: Icons.receipt_long,
                        color: AppColors.secondary,
                        onTap: () => context.push('/agent/bills/new'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Expanded(
                      child: _ActionCard(
                        title: 'View Bills',
                        subtitle: 'All bills',
                        icon: Icons.list_alt,
                        color: AppColors.accent,
                        onTap: () => context.push('/agent/bills'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Expanded(
                      child: _ActionCard(
                        title: 'View Staffs',
                        subtitle: 'Assigned staff',
                        icon: Icons.people_outline,
                        color: AppColors.roleStaff,
                        onTap: () => context.push('/agent/staff'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p20),

                // Fish Buyer Bills Section
                // Fish Buyer Bills Section — tap to view full list on a separate page
                GestureDetector(
                  onTap: () => context.push('/agent/fish-buyer-bills'),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.p16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radius16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.roleBuyer.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius12,
                            ),
                          ),
                          child: Icon(
                            Icons.shopping_cart,
                            color: AppColors.roleBuyer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSizes.p12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fish Buyer Bills',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fishBuyerBillState.bills.isEmpty
                                    ? 'No bills yet'
                                    : '${fishBuyerBillState.bills.length} bill${fishBuyerBillState.bills.length == 1 ? '' : 's'} total',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.p20),

                // Recent Bills
                Text(
                  'Recent Bills',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.p12),
                billingState.bills.isEmpty
                    ? _EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'No bills yet',
                      )
                    : Column(
                        children: billingState.bills.take(5).map((bill) {
                          return _BillRow(bill: bill);
                        }).toList(),
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

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: AppSizes.p8),
            Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final dynamic bill;
  const _BillRow({required this.bill});

  @override
  Widget build(BuildContext context) {
    final amount = bill.netAmount ?? bill.totalAmount ?? 0;
    final boatName = bill.boatName ?? bill.boatNumber ?? 'Unknown Boat';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(
          color: bill.status == 'CANCELLED'
              ? AppColors.errorLight
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bill.status == 'CANCELLED'
                  ? AppColors.errorLight
                  : AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
            ),
            child: Icon(
              bill.status == 'CANCELLED'
                  ? Icons.cancel_outlined
                  : Icons.receipt,
              color: bill.status == 'CANCELLED'
                  ? AppColors.error
                  : AppColors.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.billNumber ?? 'Bill',
                  style: AppTextStyles.labelMedium,
                ),
                Text(
                  'Boat: $boatName',
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
                '₹${amount.toStringAsFixed(0)}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: bill.status == 'CANCELLED'
                      ? AppColors.error
                      : AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppStatusBadge.fromString(bill.status ?? 'DRAFT'),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: AppSizes.p8),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
