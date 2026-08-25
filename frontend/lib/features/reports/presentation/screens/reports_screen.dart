import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_error_banner.dart';

import '../providers/report_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterType = 'range'; // 'single' or 'range'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final state = ref.read(reportProvider);

    // ✅ Show dialog with filter type selection
    final filterType = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Date Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Single Date'),
              subtitle: const Text('View data for a specific day'),
              onTap: () => Navigator.pop(ctx, 'single'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              subtitle: const Text('View data between two dates'),
              onTap: () => Navigator.pop(ctx, 'range'),
            ),
          ],
        ),
      ),
    );

    if (filterType == null) return;

    if (filterType == 'single') {
      // ✅ Single Date Picker
      final date = await showDatePicker(
        context: context,
        initialDate: state.toDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) => Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        ),
      );
      if (date != null) {
        // Set both from and to to the same date
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
        await ref
            .read(reportProvider.notifier)
            .setDateRange(startOfDay, endOfDay);
        setState(() => _filterType = 'single');
      }
    } else {
      // ✅ Date Range Picker
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(
          start: state.fromDate,
          end: state.toDate,
        ),
        builder: (context, child) => Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        ),
      );
      if (range != null) {
        await ref
            .read(reportProvider.notifier)
            .setDateRange(range.start, range.end);
        setState(() => _filterType = 'range');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);
    final user = ref.watch(authProvider).user;

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
        title: Text(
          'Reports & Analytics',
          style: AppTextStyles.h4.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            tooltip: 'Set Date Filter',
            onPressed: () => _pickDate(context),
          ),
          if (user?.role == 'SUPER_ADMIN')
            IconButton(
              icon: const Icon(
                Icons.receipt_long_outlined,
                color: Colors.white,
              ),
              tooltip: 'Audit Logs',
              onPressed: () => context.push('/admin/audit-log'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: AppTextStyles.labelMedium,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Revenue'),
            Tab(text: 'By Fish'),
            Tab(text: 'By Location'),
            Tab(text: 'Bills'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ✅ Date Range Chip with Filter Type Indicator
          _DateRangeChip(
            from: state.fromDate,
            to: state.toDate,
            filterType: _filterType,
            onTap: () => _pickDate(context),
          ),
          if (state.error != null)
            AppErrorBanner(
              message: state.error!,
              onRetry: () => ref.read(reportProvider.notifier).loadAll(),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _RevenueTab(state: state),
                      _FishTab(state: state),
                      _LocationTab(state: state),
                      _BillsSummaryTab(state: state),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Range Chip with Filter Type ────────────────────────────────────────

class _DateRangeChip extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final String filterType;
  final VoidCallback onTap;

  const _DateRangeChip({
    required this.from,
    required this.to,
    required this.filterType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yy');
    final isSingleDate = filterType == 'single';
    final isSameDay =
        from.year == to.year && from.month == to.month && from.day == to.day;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p10,
        ),
        child: Row(
          children: [
            Icon(
              isSingleDate ? Icons.calendar_today : Icons.date_range,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSizes.p6),
            Text(
              isSingleDate || isSameDay
                  ? '${fmt.format(from)}'
                  : '${fmt.format(from)} – ${fmt.format(to)}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSizes.p4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isSingleDate ? 'Single' : 'Range',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.p4),
            const Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Revenue ───────────────────────────────────────────────────────────

// ─── Tab 1: Revenue ───────────────────────────────────────────────────────────

class _RevenueTab extends StatelessWidget {
  final ReportState state;

  const _RevenueTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final totalRev = state.revenueTrend.fold(0.0, (s, p) => s + p.revenue);
    final avgRev = state.revenueTrend.isEmpty
        ? 0.0
        : totalRev / state.revenueTrend.length;
    final maxRev = state.revenueTrend.isEmpty
        ? 0.0
        : state.revenueTrend
              .map((p) => p.revenue)
              .reduce((a, b) => a > b ? a : b);

    final isSingleDay = state.revenueTrend.length == 1;

    return ListView(
      padding: const EdgeInsets.all(AppSizes.p16),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total Revenue',
                value: '₹${_fmt(totalRev)}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: _KpiCard(
                label: 'Daily Avg',
                value: '₹${_fmt(avgRev)}',
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: _KpiCard(
                label: 'Best Day',
                value: '₹${_fmt(maxRev)}',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Revenue Trend',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (state.revenueTrend.length > 7)
              Text(
                'Swipe to scroll →',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.p12),
        AppCard(
          child: state.revenueTrend.isEmpty
              ? _emptyChart()
              : isSingleDay
              ? _SingleDayRevenue(point: state.revenueTrend.first)
              : _RevenueLineChart(points: state.revenueTrend, maxRev: maxRev),
        ),
        const SizedBox(height: AppSizes.p8),
        if (state.revenueTrend.isNotEmpty)
          Text(
            'Showing ${state.revenueTrend.length} day${state.revenueTrend.length > 1 ? 's' : ''}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

// ─── Revenue Line Chart (extracted for clarity) ──────────────────────────────

class _RevenueLineChart extends StatelessWidget {
  final List<RevenuePoint> points;
  final double maxRev;

  const _RevenueLineChart({required this.points, required this.maxRev});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // ✅ Give each day fixed horizontal space so labels/dots never crowd together.
    final chartWidth = (points.length * 52.0).clamp(
      screenWidth - 64,
      double.infinity,
    );

    final safeMaxY = maxRev <= 0 ? 10.0 : maxRev * 1.25;

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 8, bottom: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            child: LineChart(
              LineChartData(
                minX: -0.3,
                maxX: (points.length - 1).toDouble() + 0.3,
                minY: 0,
                maxY: safeMaxY,

                // ── Gridlines: horizontal only, subtle ──────────────────────
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMaxY / 4,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: AppColors.border, strokeWidth: 0.8),
                ),

                // ── Titles: only bottom date labels visible ─────────────────
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, m) {
                        final idx = v.round();
                        if (idx < 0 || idx >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('d/M').format(points[idx].date),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                borderData: FlBorderData(show: false),

                // ── Tooltip: contained, readable ─────────────────────────────
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppColors.primary,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.round();
                        if (idx < 0 || idx >= points.length) return null;
                        final date = points[idx].date;
                        return LineTooltipItem(
                          '₹${_fmt(spot.y)}\n${DateFormat('d MMM yyyy').format(date)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),

                // ── The line itself: straight segments, no overshoot ────────
                lineBarsData: [
                  LineChartBarData(
                    spots: points
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
                        .toList(),
                    isCurved: false, // ✅ no dip-below-zero artifacts
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.primary,
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.20),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Single-day revenue view (replaces line chart when only 1 day selected) ──

class _SingleDayRevenue extends StatelessWidget {
  final RevenuePoint point;

  const _SingleDayRevenue({required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 40, color: AppColors.primary),
          const SizedBox(height: AppSizes.p12),
          Text(
            '₹${_fmt(point.revenue)}',
            style: AppTextStyles.metricValueSmall.copyWith(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            DateFormat('dd MMM yyyy').format(point.date),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            'Select a date range to see the trend over time',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FishTab extends StatelessWidget {
  final ReportState state;

  const _FishTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.fishRevenue.isEmpty) {
      return _emptyChart();
    }
    final maxRev = state.fishRevenue
        .map((f) => f.totalRevenue)
        .reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.p16),
      children: [
        Text(
          'Revenue by Fish Type',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.p12),
        AppCard(
          child: SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxRev * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '₹${_fmt(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, m) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= state.fishRevenue.length)
                          return const SizedBox.shrink();
                        final name = state.fishRevenue[idx].fishName;
                        final shortName = name.length > 8
                            ? '${name.substring(0, 6)}..'
                            : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            shortName,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: state.fishRevenue
                    .asMap()
                    .entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.totalRevenue,
                            color: _barColor(e.key),
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppSizes.radius8),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        Text(
          'Fish Revenue Breakdown',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.p12),
        AppCard(
          child: Column(
            children: [
              _TableHeader(cols: ['#', 'Fish Name', 'Weight (kg)', 'Revenue']),
              const Divider(height: 1),
              ...state.fishRevenue.asMap().entries.map(
                (e) => _TableRow(
                  cells: [
                    '${e.key + 1}',
                    e.value.fishName,
                    e.value.totalWeight > 0
                        ? '${e.value.totalWeight.toStringAsFixed(1)}'
                        : '-',
                    '₹${_fmt(e.value.totalRevenue)}',
                  ],
                ),
              ),
              const Divider(height: 1),
              _TableRow(
                cells: [
                  '',
                  'Total',
                  '${state.fishRevenue.fold(0.0, (s, f) => s + f.totalWeight).toStringAsFixed(1)}',
                  '₹${_fmt(state.fishRevenue.fold(0.0, (s, f) => s + f.totalRevenue))}',
                ],
                isBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        Text(
          'Price Analysis by Fish',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.p12),
        ...state.fishRevenue.map(
          (fish) => Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p12),
            child: _FishPriceCard(fish: fish),
          ),
        ),
      ],
    );
  }

  Color _barColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    return colors[index % colors.length];
  }
}

class _FishPriceCard extends StatelessWidget {
  final FishRevenueItem fish;

  const _FishPriceCard({required this.fish});

  @override
  Widget build(BuildContext context) {
    final hasTrend = fish.priceChangePercent != null && fish.isRising != null;
    final isRising = fish.isRising ?? false;
    final trendColor = isRising ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
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
          // ── Header: name, category, trend badge ──────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
                child: Icon(Icons.set_meal, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSizes.p10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fish.fishName,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      fish.category,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasTrend)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRising ? 'Rising' : 'Falling',
                    style: AppTextStyles.caption.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p14),

          // ── Lowest / Average / Highest ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _PriceBlock(
                  label: 'Lowest',
                  value: fish.lowestPrice,
                  color: AppColors.success,
                  bgColor: AppColors.success.withOpacity(0.08),
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              Expanded(
                child: _PriceBlock(
                  label: 'Average',
                  value: fish.averagePrice,
                  color: AppColors.primary,
                  bgColor: AppColors.primary.withOpacity(0.08),
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              Expanded(
                child: _PriceBlock(
                  label: 'Highest',
                  value: fish.highestPrice,
                  color: AppColors.error,
                  bgColor: AppColors.error.withOpacity(0.08),
                ),
              ),
            ],
          ),

          // ── Trend percentage footer ───────────────────────────────────────
          if (hasTrend) ...[
            const SizedBox(height: AppSizes.p10),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRising ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: trendColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${fish.priceChangePercent!.abs().toStringAsFixed(1)}%',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final Color bgColor;

  const _PriceBlock({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p10),
      decoration: BoxDecoration(
        color: bgColor,
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
            '₹${value.toStringAsFixed(1)}',
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
// ─── Tab 3: By Location ───────────────────────────────────────────────────────

class _LocationTab extends StatelessWidget {
  final ReportState state;

  const _LocationTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.locationRevenue.isEmpty) return _emptyChart();
    final total = state.locationRevenue.fold(0.0, (s, i) => s + i.revenue);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.p16),
      children: [
        Text(
          'Revenue Distribution by Location',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.p12),
        AppCard(
          child: Row(
            children: [
              SizedBox(
                height: 200,
                width: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: state.locationRevenue.asMap().entries.map((e) {
                      final pct = total == 0
                          ? 0.0
                          : (e.value.revenue / total * 100);
                      const colors = [
                        AppColors.primary,
                        AppColors.secondary,
                        AppColors.accent,
                        AppColors.info,
                        AppColors.success,
                      ];
                      return PieChartSectionData(
                        value: e.value.revenue,
                        color: colors[e.key % colors.length],
                        title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: state.locationRevenue.asMap().entries.map((e) {
                    const colors = [
                      AppColors.primary,
                      AppColors.secondary,
                      AppColors.accent,
                      AppColors.info,
                      AppColors.success,
                    ];
                    final pct = total == 0
                        ? 0.0
                        : (e.value.revenue / total * 100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[e.key % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.value.location,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        Text(
          'Location Details',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.p12),
        AppCard(
          child: Column(
            children: [
              _TableHeader(
                cols: ['Location', 'Sub-Location', 'Bills', 'Revenue'],
              ),
              const Divider(height: 1),
              ...state.locationRevenue.map(
                (item) => _TableRow(
                  cells: [
                    item.location,
                    item.subLocation.isNotEmpty ? item.subLocation : '-',
                    '${item.billCount}',
                    '₹${_fmt(item.revenue)}',
                  ],
                ),
              ),
              const Divider(height: 1),
              _TableRow(
                cells: [
                  '',
                  'Total',
                  '${state.locationRevenue.fold(0, (s, i) => s + i.billCount)}',
                  '₹${_fmt(state.locationRevenue.fold(0.0, (s, i) => s + i.revenue))}',
                ],
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab 4: Bills Summary ─────────────────────────────────────────────────────

class _BillsSummaryTab extends StatelessWidget {
  final ReportState state;

  const _BillsSummaryTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.billsSummary;
    return ListView(
      padding: const EdgeInsets.all(AppSizes.p16),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSizes.p12,
          mainAxisSpacing: AppSizes.p12,
          childAspectRatio: 1.5,
          children: [
            _KpiCard(
              label: 'Total Bills',
              value: '${s.total}',
              color: AppColors.primary,
            ),
            _KpiCard(
              label: 'Confirmed',
              value: '${s.confirmed}',
              color: AppColors.info,
            ),

            _KpiCard(
              label: 'Cancelled',
              value: '${s.cancelled}',
              color: AppColors.error,
            ),

            _KpiCard(
              label: 'Total Weight',
              value: s.totalWeight > 0
                  ? '${s.totalWeight.toStringAsFixed(1)} kg'
                  : '0 kg',
              color: AppColors.secondary,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        Text(
          'Financial Summary',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.p12),
        AppCard(
          child: Column(
            children: [
              _SummaryRow(
                label: 'Total Revenue',
                value: '₹${_fmt(s.totalAmount)}',
              ),
              _SummaryRow(
                label: 'Avg per Bill',
                value: s.total == 0 ? '—' : '₹${_fmt(s.totalAmount / s.total)}',
              ),
              _SummaryRow(
                label: 'Total Weight',
                value: '${s.totalWeight.toStringAsFixed(2)} kg',
              ),
              _SummaryRow(
                label: 'Total Commission',
                value: '₹${_fmt(s.totalCommission)}',
              ),
              _SummaryRow(
                label: 'Collection Rate',
                value: s.total == 0
                    ? '0%'
                    : '${((s.paid / s.total) * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: AppSizes.p6),
          Text(
            value,
            style: AppTextStyles.metricValueSmall.copyWith(
              color: color,
              fontSize: 18,
            ),
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> cols;

  const _TableHeader({required this.cols});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Row(
        children: cols
            .map(
              (c) => Expanded(
                child: Text(
                  c,
                  style: AppTextStyles.overline.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final List<String> cells;
  final bool isBold;

  const _TableRow({required this.cells, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
      child: Row(
        children: cells
            .map(
              (c) => Expanded(
                child: Text(
                  c,
                  style: isBold
                      ? AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        )
                      : AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _emptyChart() => const Center(
  child: Padding(
    padding: EdgeInsets.all(AppSizes.p32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bar_chart, size: 64, color: AppColors.textHint),
        SizedBox(height: AppSizes.p12),
        Text(
          'No data available for selected period',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
);

String _fmt(double v) {
  if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
