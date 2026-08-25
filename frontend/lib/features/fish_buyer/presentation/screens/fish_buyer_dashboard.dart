import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../fish/presentation/providers/fish_provider.dart';
import '../providers/fish_buyer_bill_provider.dart';

class FishBuyerDashboard extends ConsumerStatefulWidget {
  const FishBuyerDashboard({super.key});

  @override
  ConsumerState<FishBuyerDashboard> createState() => _FishBuyerDashboardState();
}

class _FishBuyerDashboardState extends ConsumerState<FishBuyerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fishBuyerBillProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final billState = ref.watch(fishBuyerBillProvider);
    final user = authState.user;

    final dateStr =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    // Group bills by agent
    final agentBillMap = <String, Map<String, dynamic>>{};
    for (final bill in billState.bills) {
      final agentId = bill['agentId'] is Map
          ? (bill['agentId'] as Map)['_id'] ?? ''
          : (bill['agentId'] ?? '');
      final agentName = bill['agentId'] is Map
          ? (bill['agentId'] as Map)['name'] ?? 'Unknown Agent'
          : 'Unknown Agent';

      if (!agentBillMap.containsKey(agentId)) {
        agentBillMap[agentId] = {
          'name': agentName,
          'total': 0.0,
          'count': 0,
          'bills': <Map<String, dynamic>>[],
        };
      }
      agentBillMap[agentId]!['total'] =
          (agentBillMap[agentId]!['total'] as double) +
          ((bill['totalAmount'] ?? 0).toDouble());
      agentBillMap[agentId]!['count'] =
          (agentBillMap[agentId]!['count'] as int) + 1;
      (agentBillMap[agentId]!['bills'] as List).add(bill);
    }

    final totalSpent = billState.bills.fold<double>(
      0.0,
      (sum, b) => sum + ((b['totalAmount'] ?? 0).toDouble()),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC62828), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buyer Dashboard',
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
            onPressed: () => context.push('/buyer/profile'),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: billState.isLoading,
        child: RefreshIndicator(
          color: AppColors.roleBuyer,
          onRefresh: () async {
            await ref.read(fishBuyerBillProvider.notifier).load();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        title: 'Total Spent',
                        value: '₹${totalSpent.toStringAsFixed(0)}',
                        icon: Icons.shopping_cart,
                        color: AppColors.roleBuyer,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: AppMetricCard(
                        title: 'Total Purchases',
                        value: '${billState.bills.length}',
                        icon: Icons.receipt_long,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p16),

                // Quick Actions
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
                        title: 'New Bill',
                        subtitle: 'Create purchase bill',
                        icon: Icons.add_shopping_cart,
                        color: AppColors.roleBuyer,
                        onTap: () => context.push('/buyer/bills/new'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Expanded(
                      child: _ActionCard(
                        title: 'My Bills',
                        subtitle: 'View all bills',
                        icon: Icons.receipt_long,
                        color: AppColors.info,
                        onTap: () => context.push('/buyer/bills'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p20),

                // Agent-wise Bill Summary
                Text(
                  'Agent-wise Purchases',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.p12),

                if (agentBillMap.isEmpty)
                  const AppEmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'No Purchases Yet',
                    subtitle: 'Start buying fish from agents!',
                  )
                else
                  ...agentBillMap.entries.map((entry) {
                    final agentData = entry.value;
                    final agentName = agentData['name'] as String;
                    final total = agentData['total'] as double;
                    final count = agentData['count'] as int;

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSizes.p8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p16,
                        vertical: AppSizes.p12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.roleBuyer.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius8,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppColors.roleBuyer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSizes.p12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agentName,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$count bill${count > 1 ? 's' : ''}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.roleBuyer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: AppSizes.p20),

                // Recent Purchases
                Text(
                  'Recent Purchases',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.p12),
                billState.bills.isEmpty
                    ? const SizedBox()
                    : Column(
                        children: billState.bills.take(5).map((bill) {
                          final billNumber = bill['billNumber'] ?? 'FBB-????';
                          final agentName = bill['agentId'] is Map
                              ? (bill['agentId'] as Map)['name'] ?? ''
                              : '';
                          final total = (bill['totalAmount'] ?? 0).toDouble();
                          final fishName = bill['fishName'] ?? '';
                          final status = bill['status'] ?? 'CONFIRMED';

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
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.roleBuyer.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radius8,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag,
                                    color: AppColors.roleBuyer,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.p12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        billNumber,
                                        style: AppTextStyles.labelMedium,
                                      ),
                                      if (agentName.isNotEmpty)
                                        Text(
                                          'Agent: $agentName',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      if (fishName.isNotEmpty)
                                        Text(
                                          'Fish: $fishName',
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
                                      '₹${total.toStringAsFixed(0)}',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.roleBuyer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    AppStatusBadge.fromString(status),
                                  ],
                                ),
                              ],
                            ),
                          );
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
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: AppSizes.p12),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
