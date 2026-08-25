import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_fish_market_nav_bar.dart';
import '../providers/dashboard_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).load();
      ref.read(billingProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final billingState = ref.watch(billingProvider);
    final user = authState.user;

    final sum = state.summary;
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
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
              'Good morning, ${user?.name ?? "Admin"}',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.surface,
              ),
            ),
            Text(
              dateStr,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.surface.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.surface,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.surface),
            onPressed: () => context.push('/admin/profile'),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary grid cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.p12,
                mainAxisSpacing: AppSizes.p12,
                childAspectRatio: 1.5,
                children: [
                  AppMetricCard(
                    title: 'Total Revenue',
                    value: '₹${sum.totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee,
                    color: AppColors.primary,
                  ),
                  AppMetricCard(
                    title: 'Total Bills Count',
                    value: '${sum.totalBills}',
                    icon: Icons.receipt_long,
                    color: AppColors.info,
                  ),
                  AppMetricCard(
                    title: 'Active Boats',
                    value: '${sum.activeBoats}',
                    icon: Icons.directions_boat,
                    color: AppColors.success,
                  ),
                  AppMetricCard(
                    title: 'Total Weight',
                    value: '${sum.totalWeight.toStringAsFixed(0)} kg',
                    icon: Icons.scale,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p16),

              // Line Chart Trend Card
              Text(
                'Revenue Trend (7 Days)',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              AppCard(
                child: SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: sum.weeklyRevenue
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 4,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withOpacity(0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // Top Fish Varieties by Revenue
              Text(
                'Top Fish Varieties',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sum.revenueByFish.length,
                  itemBuilder: (_, i) {
                    final item = sum.revenueByFish.entries.toList()[i];
                    return Card(
                      margin: const EdgeInsets.only(right: AppSizes.p8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.p12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.key, style: AppTextStyles.labelLarge),
                            const SizedBox(height: 2),
                            Text(
                              '₹${item.value.toStringAsFixed(0)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // Location Revenue Table/Bars
              Text(
                'Revenue by Port',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              AppCard(
                child: Column(
                  children: sum.revenueByLocation.entries.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.p12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.key, style: AppTextStyles.bodyMedium),
                              Text(
                                '₹${item.value.toStringAsFixed(0)}',
                                style: AppTextStyles.labelLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value:
                                item.value /
                                200000.0, // normalized max estimate
                            color: AppColors.primary,
                            backgroundColor: AppColors.border,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // Recent Bills List
              Text(
                'Recent Billing Records',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              billingState.bills.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSizes.p16),
                        child: Text('No bills created yet'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: billingState.bills.take(4).length,
                      itemBuilder: (_, idx) {
                        final bill = billingState.bills[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.p8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius12,
                            ),
                          ),
                          child: ListTile(
                            title: Text(bill.billNumber),
                            subtitle: Text('Boat: ${bill.boatName}'),
                            trailing: Text(
                              '₹${bill.totalAmount.toStringAsFixed(0)}',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () =>
                                context.push('/agent/bills/${bill.id}'),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpeedDial() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Operations',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.person_add_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Add User'),
              onTap: () {
                context.pop();
                context.push('/admin/users/new');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.directions_boat_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Register Boat'),
              onTap: () {
                context.pop();
                context.push('/agent/boats/new');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.add_location_alt_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Add Port Location'),
              onTap: () {
                context.pop();
                context.push('/admin/locations');
              },
            ),
          ],
        ),
      ),
    );
  }
}
