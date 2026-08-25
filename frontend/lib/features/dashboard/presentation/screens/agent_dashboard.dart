import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class AgentDashboard extends ConsumerStatefulWidget {
  const AgentDashboard({super.key});

  @override
  ConsumerState<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends ConsumerState<AgentDashboard> {
  int _navIndex = 0;

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
    final dateStr = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    // Today's bills
    final today = DateTime.now();
    final todayBills = billingState.bills.where((b) {
      final d = b.billDate;
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();

    final todayRevenue = todayBills.fold<double>(
      0.0,
      (sum, b) => sum + b.totalAmount,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF006064), Color(0xFF00838F), Color(0xFF26C6DA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good day, ${user?.name ?? "Agent"}',
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
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.push('/agent/profile'),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () async {
            await ref.read(dashboardProvider.notifier).load();
            await ref.read(billingProvider.notifier).load();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Today's Summary banner ──────────────────────────────────
                _TodaySummaryBanner(
                  billCount: todayBills.length,
                  revenue: todayRevenue,
                ),
                const SizedBox(height: AppSizes.p16),

                // ── Metric grid ─────────────────────────────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSizes.p12,
                  mainAxisSpacing: AppSizes.p12,
                  childAspectRatio: 1.6,
                  children: [
                    AppMetricCard(
                      title: 'Total Revenue',
                      value: '₹${_formatNum(sum.totalRevenue)}',
                      icon: Icons.currency_rupee,
                      color: AppColors.secondary,
                    ),
                    AppMetricCard(
                      title: 'Total Bills',
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
                      value: '${sum.totalWeight.toStringAsFixed(1)} kg',
                      icon: Icons.scale,
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p20),

                // ── Recent Bills ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Bills', style: AppTextStyles.h4),
                    TextButton(
                      onPressed: () => context.go('/agent/bills'),
                      child: Text(
                        'View All',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p8),
                billingState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : billingState.bills.isEmpty
                    ? _EmptyBillsCard()
                    : Column(
                        children: billingState.bills.take(5).map((bill) {
                          return _BillTile(
                            bill: bill,
                            onTap: () =>
                                context.push('/agent/bills/${bill.id}'),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: AppSizes.p20),

                // ── Boat Balances ───────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boat Balances',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p8),
                    AppCard(
                      child: Column(
                        children: sum.revenueByLocation.entries
                            .take(4)
                            .map(
                              (e) =>
                                  _BalanceTile(label: e.key, amount: e.value),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p20),

                // ── Revenue by Fish ─────────────────────────────────────────
                Text('Fish Revenue Breakdown', style: AppTextStyles.h4),
                const SizedBox(height: AppSizes.p8),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sum.revenueByFish.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSizes.p8),
                    itemBuilder: (_, i) {
                      final item = sum.revenueByFish.entries.toList()[i];
                      return _FishRevenueChip(
                        name: item.key,
                        amount: item.value,
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSizes.p32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNum(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Today Summary Banner ─────────────────────────────────────────────────────

class _TodaySummaryBanner extends StatelessWidget {
  final int billCount;
  final double revenue;

  const _TodaySummaryBanner({required this.billCount, required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006064), Color(0xFF00838F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Activity",
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSizes.p8),
          Row(
            children: [
              Expanded(
                child: _BannerStat(
                  label: 'Bills Today',
                  value: '$billCount',
                  icon: Icons.receipt_long,
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: _BannerStat(
                  label: 'Revenue',
                  value: '₹${revenue.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BannerStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: AppSizes.p8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bill Tile ────────────────────────────────────────────────────────────────

class _BillTile extends StatelessWidget {
  final dynamic bill;
  final VoidCallback onTap;

  const _BillTile({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        side: BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
                child: const Icon(
                  Icons.receipt,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billNumber ?? 'Bill',
                      style: AppTextStyles.labelLarge,
                    ),
                    Text(bill.boatName ?? '', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${(bill.totalAmount as double).toStringAsFixed(0)}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  AppStatusBadge.fromString(bill.status ?? 'DRAFT'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Balance Tile ─────────────────────────────────────────────────────────────

class _BalanceTile extends StatelessWidget {
  final String label;
  final double amount;

  const _BalanceTile({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            '₹${amount.abs().toStringAsFixed(0)}',
            style: AppTextStyles.labelLarge.copyWith(
              color: isPositive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSizes.p8),
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: isPositive ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }
}

// ─── Fish Revenue Chip ────────────────────────────────────────────────────────

class _FishRevenueChip extends StatelessWidget {
  final String name;
  final double amount;

  const _FishRevenueChip({required this.name, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.set_meal, size: 20, color: AppColors.accent),
          const SizedBox(height: AppSizes.p4),
          Text(
            name,
            style: AppTextStyles.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Bills Card ─────────────────────────────────────────────────────────

class _EmptyBillsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            'No bills yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
