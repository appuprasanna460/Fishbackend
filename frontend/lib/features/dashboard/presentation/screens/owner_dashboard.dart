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
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../boats/domain/entities/boat_entity.dart';

class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatProvider.notifier).load();
      ref.read(billingProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final boatState = ref.watch(boatProvider);
    final billingState = ref.watch(billingProvider);
    final user = authState.user;
    final dateStr = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    // Filter to only this owner's active boats
    final myBoats = boatState.boats
        .where((b) => b.ownerId == user?.id)
        .toList();

    // Bills belonging to owner's boats
    final myBoatIds = myBoats.map((b) => b.id).toSet();
    final myBills = billingState.bills
        .where((b) => myBoatIds.contains(b.boatId))
        .toList();
    final myRevenue = myBills.fold<double>(0.0, (s, b) => s + b.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name ?? "Owner"}',
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
            onPressed: () => context.push('/owner/profile'),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: boatState.isLoading || billingState.isLoading,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(boatProvider.notifier).load();
            await ref.read(billingProvider.notifier).load();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Metric Cards ─────────────────────────────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSizes.p12,
                  mainAxisSpacing: AppSizes.p12,
                  childAspectRatio: 1.6,
                  children: [
                    AppMetricCard(
                      title: 'My Revenue',
                      value: '₹${_fmt(myRevenue)}',
                      icon: Icons.currency_rupee,
                      color: AppColors.primary,
                    ),
                    AppMetricCard(
                      title: 'My Boats',
                      value: '${myBoats.length}',
                      icon: Icons.directions_boat,
                      color: AppColors.info,
                    ),
                    AppMetricCard(
                      title: 'Total Bills',
                      value: '${myBills.length}',
                      icon: Icons.receipt_long,
                      color: AppColors.accent,
                    ),
                    AppMetricCard(
                      title: 'Avg per Boat',
                      value: myBoats.isNotEmpty
                          ? '₹${_fmt(myRevenue / myBoats.length)}'
                          : '₹0',
                      icon: Icons.analytics,
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p20),

                // ── My Boats ─────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Boats', style: AppTextStyles.h4),
                    TextButton(
                      onPressed: () => context.go('/owner/tracking'),
                      child: Text(
                        'Track All',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p8),
                myBoats.isEmpty
                    ? _EmptyCard(
                        icon: Icons.directions_boat_outlined,
                        message: 'No boats registered yet',
                      )
                    : SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: myBoats.take(6).length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSizes.p12),
                          itemBuilder: (_, i) => _BoatCard(boat: myBoats[i]),
                        ),
                      ),
                const SizedBox(height: AppSizes.p20),

                // ── Recent Invoices ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Invoices', style: AppTextStyles.h4),
                    TextButton(
                      onPressed: () => context.go('/owner/bills'),
                      child: Text(
                        'View All',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p8),
                myBills.isEmpty
                    ? _EmptyCard(
                        icon: Icons.receipt_long_outlined,
                        message: 'No invoices yet',
                      )
                    : Column(
                        children: myBills.take(5).map((bill) {
                          return _InvoiceTile(
                            bill: bill,
                            onTap: () =>
                                context.push('/owner/bills/${bill.id}'),
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

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Boat Card (uses typed BoatEntity) ───────────────────────────────────────

class _BoatCard extends StatelessWidget {
  final BoatEntity boat;

  const _BoatCard({required this.boat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
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
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_boat,
                size: 18,
                color: AppColors.primary,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: boat.isActive
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                ),
                child: Text(
                  boat.isActive ? 'Active' : 'Inactive',
                  style: AppTextStyles.overline.copyWith(
                    color: boat.isActive ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            boat.boatName,
            style: AppTextStyles.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(boat.boatNumber, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ─── Invoice Tile ─────────────────────────────────────────────────────────────

class _InvoiceTile extends StatelessWidget {
  final dynamic bill;
  final VoidCallback onTap;

  const _InvoiceTile({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        side: const BorderSide(color: AppColors.border, width: 0.8),
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
                      color: AppColors.primary,
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

// ─── Empty Card ───────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

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
