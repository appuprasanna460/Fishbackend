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
import '../../../../core/widgets/app_searchable_dropdown.dart';
import '../providers/price_analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FishPriceAnalyticsScreen extends ConsumerStatefulWidget {
  const FishPriceAnalyticsScreen({super.key});

  @override
  ConsumerState<FishPriceAnalyticsScreen> createState() =>
      _FishPriceAnalyticsScreenState();
}

class _FishPriceAnalyticsScreenState
    extends ConsumerState<FishPriceAnalyticsScreen> {
  int _navIndex = 3;

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(priceAnalyticsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final filtered = analyticsState.filtered;

    String _roleRoute(String role, int idx, {String? fallback}) {
      final base = role == 'SUPER_ADMIN'
          ? 'admin'
          : role == 'COMMISSION_AGENT'
          ? 'agent'
          : role == 'BOAT_OWNER'
          ? 'owner'
          : role == 'FISH_BUYER'
          ? 'buyer'
          : 'staff';
      final routes = [
        '/$base/dashboard',
        '/agent/boats',
        '/$base/bills/new',
        '/$base/tracking',
        '/$base/profile',
      ];
      return routes[idx] ?? fallback ?? '/$base/dashboard';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Fish Price Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                ref.read(priceAnalyticsProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              final role = user?.role ?? 'COMMISSION_AGENT';
              final base = role == 'SUPER_ADMIN'
                  ? 'admin'
                  : role == 'COMMISSION_AGENT'
                  ? 'agent'
                  : role == 'BOAT_OWNER'
                  ? 'owner'
                  : role == 'FISH_BUYER'
                  ? 'buyer'
                  : 'staff';
              context.push('/$base/profile');
            },
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: analyticsState.isLoading,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(priceAnalyticsProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.p16),
            children: [
              const SizedBox(height: AppSizes.p8),

              _MarketSummaryCard(prices: filtered),
              const SizedBox(height: AppSizes.p20),

              if (analyticsState.categories.isNotEmpty)
                Row(
                  children: [
                    Text('Filter by Category', style: AppTextStyles.labelLarge),
                    const Spacer(),
                    AppSearchableDropdown<String>(
                      label: 'Category',
                      items: analyticsState.categories,
                      value: analyticsState.selectedCategory,
                      onChanged: (v) => ref
                          .read(priceAnalyticsProvider.notifier)
                          .filterByCategory(v),
                      itemLabel: (c) => c,
                      hint: 'All Categories',
                    ),
                  ],
                ),
              const SizedBox(height: AppSizes.p16),

              Text(
                '${filtered.length} Fish Varieties',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p12),

              ...filtered.map((entry) => _FishPriceCard(entry: entry)).toList(),
              const SizedBox(height: AppSizes.p32),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketSummaryCard extends StatelessWidget {
  final List<FishPriceEntry> prices;
  const _MarketSummaryCard({required this.prices});

  @override
  Widget build(BuildContext context) {
    final topFish = prices.isEmpty
        ? null
        : prices.reduce((a, b) => a.averagePrice > b.averagePrice ? a : b);
    final avgAll = prices.isEmpty
        ? 0.0
        : prices.map((p) => p.averagePrice).reduce((a, b) => a + b) /
              prices.length;
    final upTrend = prices.where((p) => p.trend == 'up').length;
    final downTrend = prices.where((p) => p.trend == 'down').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Overview',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.p12),
        Row(
          children: [
            Expanded(
              child: _SummaryChip(
                label: 'Top Variety',
                value: topFish?.fishName ?? '-',
                sub:
                    '\u20B9${topFish?.averagePrice.toStringAsFixed(0) ?? 0}/kg',
                icon: Icons.emoji_events,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: _SummaryChip(
                label: 'Avg Market',
                value: '\u20B9${avgAll.toStringAsFixed(0)}',
                sub: 'per kg average',
                icon: Icons.trending_up,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: _SummaryChip(
                label: 'Trending',
                value: '$upTrend Up / $downTrend Down',
                sub: 'price movements',
                icon: Icons.show_chart,
                color: upTrend > downTrend
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSizes.p4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _FishPriceCard extends StatelessWidget {
  final FishPriceEntry entry;
  const _FishPriceCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final change = entry.averagePrice - entry.previousAverage;
    final pctChange = entry.previousAverage > 0
        ? ((change / entry.previousAverage) * 100)
        : 0.0;
    final isUp = change > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSizes.radius8),
                    ),
                    child: Icon(
                      Icons.set_meal,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSizes.p12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.fishName,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        entry.category,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppStatusBadge(
                label: entry.trend == 'up'
                    ? 'Rising'
                    : entry.trend == 'down'
                    ? 'Falling'
                    : 'Stable',
                type: entry.trend == 'up'
                    ? AppBadgeType.success
                    : entry.trend == 'down'
                    ? AppBadgeType.danger
                    : AppBadgeType.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p16),
          Row(
            children: [
              Expanded(
                child: _PricePoint(
                  label: 'Lowest',
                  value: '\u20B9${entry.lowestPrice}',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _PricePoint(
                  label: 'Average',
                  value: '\u20B9${entry.averagePrice.toStringAsFixed(0)}',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _PricePoint(
                  label: 'Highest',
                  value: '\u20B9${entry.highestPrice}',
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                isUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isUp ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                '${isUp ? '+' : ''}${pctChange.toStringAsFixed(1)}%',
                style: AppTextStyles.caption.copyWith(
                  color: isUp ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricePoint extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PricePoint({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.p8,
        horizontal: AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radius8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
