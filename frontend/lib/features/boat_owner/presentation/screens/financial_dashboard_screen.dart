import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../providers/financial_providers.dart';
import '../../domain/entities/financial_models.dart';

class FinancialDashboardScreen extends ConsumerStatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  ConsumerState<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends ConsumerState<FinancialDashboardScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(financialDashboardProvider.notifier).fetchDashboard();
    });
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(financialDashboardProvider.notifier).updatePeriod('Custom', range: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialDashboardProvider);
    final data = state.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Financial Dashbaord',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(financialDashboardProvider.notifier).fetchDashboard();
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error loading dashboard: ${state.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.read(financialDashboardProvider.notifier).fetchDashboard(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : data == null
                  ? const Center(child: Text('No data found'))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(financialDashboardProvider.notifier).fetchDashboard(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header & Harbour Status
                            _buildHarbourHeader(),
                            const SizedBox(height: 16),

                            // Date Range Picker row
                            _buildPeriodSelector(context, state),
                            const SizedBox(height: 16),

                            // Financial Summary cards
                            _buildFinancialCards(data),
                            const SizedBox(height: 20),

                            // Voyage Statistics overview
                            _buildVoyageStats(data),
                            const SizedBox(height: 20),

                            // Performance Chart
                            _buildPLChart(data),
                            const SizedBox(height: 20),

                            // Highlights Row (Top Profit & Top Expense)
                            _buildHighlightsSection(data),
                            const SizedBox(height: 20),

                            // Recent Voyages Table
                            _buildRecentVoyagesTable(data),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHarbourHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Performance',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'St. Anthony Harbour',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Online',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, FinancialDashboardState state) {
    final periods = ['This Month', 'This Year', 'Custom'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filter Period',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        PopupMenuButton<String>(
          initialValue: state.selectedPeriod,
          onSelected: (val) {
            if (val == 'Custom') {
              _selectCustomDateRange(context);
            } else {
              ref.read(financialDashboardProvider.notifier).updatePeriod(val);
            }
          },
          itemBuilder: (context) => periods.map((p) {
            return PopupMenuItem<String>(
              value: p,
              child: Text(
                p == 'Custom' && state.selectedPeriod == 'Custom' && state.dateRange != null
                    ? '${DateFormat('d MMM').format(state.dateRange!.start)} - ${DateFormat('d MMM').format(state.dateRange!.end)}'
                    : p,
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  state.selectedPeriod == 'Custom' && state.dateRange != null
                      ? '${DateFormat('d MMM').format(state.dateRange!.start)} - ${DateFormat('d MMM').format(state.dateRange!.end)}'
                      : state.selectedPeriod,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCards(FinancialDashboardData data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Total Income',
          value: currencyFormatter.format(data.totalIncome),
          icon: Icons.trending_up,
          iconColor: Colors.green,
          bgColor: Colors.green.withOpacity(0.06),
        ),
        _buildStatCard(
          title: 'Total Expenses',
          value: currencyFormatter.format(data.totalExpenses),
          icon: Icons.trending_down,
          iconColor: Colors.red,
          bgColor: Colors.red.withOpacity(0.06),
        ),
        _buildStatCard(
          title: 'Net Profit',
          value: currencyFormatter.format(data.netProfit),
          icon: Icons.account_balance_wallet_outlined,
          iconColor: data.netProfit >= 0 ? AppColors.primary : Colors.red,
          bgColor: AppColors.primary.withOpacity(0.06),
        ),
        _buildStatCard(
          title: 'Profit Margin',
          value: '${data.profitMargin.toStringAsFixed(1)}%',
          icon: Icons.pie_chart_outline,
          iconColor: Colors.orange,
          bgColor: Colors.orange.withOpacity(0.06),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoyageStats(FinancialDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voyage Statistics',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCounter('${data.totalVoyages}', 'Total', Colors.blue),
              _buildStatCounter('${data.completed}', 'Completed', Colors.green),
              _buildStatCounter('${data.active}', 'In Progress', Colors.orange),
              _buildStatCounter('${data.cancelled}', 'Cancelled', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCounter(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

Widget _buildPLChart(FinancialDashboardData data) {
  if (data.chartData.isEmpty) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: const Text('No chart data available'),
    );
  }

  final int n = data.chartData.length;

  // --- Repair broken/duplicate date labels if detected ---
  List<String> displayDates = data.chartData.map((d) => d.date).toList();
  final uniqueDates = displayDates.toSet();
  final looksBroken = n > 2 && uniqueDates.length < n - 1;

  if (looksBroken) {
    try {
      final currentYear = DateTime.now().year;
      DateTime parseLabel(String label) {
        final parsed = DateFormat('d MMM').parse(label);
        return DateTime(currentYear, parsed.month, parsed.day);
      }

      final firstDate = parseLabel(displayDates.first);
      final lastDate = parseLabel(displayDates.last);
      final totalSpanDays = lastDate.difference(firstDate).inDays;

      if (totalSpanDays > 0) {
        displayDates = List.generate(n, (i) {
          final dayOffset = (totalSpanDays * i / (n - 1)).round();
          return DateFormat('d MMM').format(firstDate.add(Duration(days: dayOffset)));
        });
      }
    } catch (_) {
      // fall back to original labels if parsing fails
    }
  }
  // --- end repair ---

  double maxVal = 0.0;
  double minVal = 0.0;
  for (var d in data.chartData) {
    if (d.income > maxVal) maxVal = d.income;
    if (d.expenses > maxVal) maxVal = d.expenses;
    if (d.profit > maxVal) maxVal = d.profit;
    if (d.profit < minVal) minVal = d.profit;
  }
  final double maxYVal = maxVal == 0 ? 10000.0 : maxVal * 1.25;
  final double minYVal = minVal < 0 ? minVal * 1.25 : 0.0;

  final double minX = 0;
  final double maxX = n == 1 ? 1.0 : (n - 1).toDouble();

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border.withOpacity(0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'P&L Overview',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minYVal,
              maxY: maxYVal,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (spots) {
                    final labels = ['Income', 'Expenses', 'Profit'];
                    return spots.map((s) {
                      final label = s.barIndex < labels.length ? labels[s.barIndex] : '';
                      return LineTooltipItem(
                        '$label: ₹${s.y.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= displayDates.length) {
                        return const SizedBox.shrink();
                      }
                      final int step = n <= 5 ? 1 : (n / 4).ceil();
                      if (idx % step != 0 && idx != n - 1) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          displayDates[idx],
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('₹0', style: TextStyle(fontSize: 9));
                      final absVal = value.abs();
                      final prefix = value < 0 ? '-' : '';
                      if (absVal >= 100000) {
                        return Text('$prefix₹${(absVal / 100000).toStringAsFixed(1)}L',
                            style: const TextStyle(fontSize: 9));
                      }
                      if (absVal >= 1000) {
                        if (absVal < 10000) {
                          return Text('$prefix₹${(absVal / 1000).toStringAsFixed(1)}K',
                              style: const TextStyle(fontSize: 9));
                        }
                        return Text('$prefix₹${(absVal / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(fontSize: 9));
                      }
                      return Text('$prefix₹${absVal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 9));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Income
                LineChartBarData(
                  spots: data.chartData.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.income);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: Colors.green,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 3,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Colors.green,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.06),
                  ),
                ),
                // Expenses
                LineChartBarData(
                  spots: data.chartData.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.expenses);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: Colors.red,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 3,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Colors.red,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withOpacity(0.06),
                  ),
                ),
                // Profit
                LineChartBarData(
                  spots: data.chartData.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.profit);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: Colors.blue,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 3,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Colors.blue,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.06),
                  ),
                ),
              ],
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: Colors.grey[400]!,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendDot(Colors.green, 'Revenue'),
            const SizedBox(width: 16),
            _buildLegendDot(Colors.red, 'Expenses'),
            const SizedBox(width: 16),
            _buildLegendDot(Colors.blue, 'Profit'),
          ],
        ),
      ],
    ),
  );
}
  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightsSection(FinancialDashboardData data) {
    return Column(
      children: [
        if (data.topProfitVoyage != null) ...[
          _buildHighlightCard(
            title: 'Top Profit Voyage',
            primaryText: data.topProfitVoyage!.voyageNo,
            secondaryText: currencyFormatter.format(data.topProfitVoyage!.profit),
            icon: Icons.workspace_premium_outlined,
            iconColor: Colors.amber,
            onViewTap: () => context.push('/owner/financial/voyages/${data.topProfitVoyage!.id}?tab=0'),
          ),
          const SizedBox(height: 12),
        ],
        if (data.topExpenseCategory != null) ...[
          _buildHighlightCard(
            title: 'Top Expense Category',
            primaryText: data.topExpenseCategory!.category,
            secondaryText: currencyFormatter.format(data.topExpenseCategory!.amount),
            icon: Icons.pie_chart,
            iconColor: Colors.redAccent,
            onViewTap: () {
              // Highlight only, standard view
            },
          ),
        ],
      ],
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String primaryText,
    required String secondaryText,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onViewTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  primaryText,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                secondaryText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onViewTap,
                child: Text(
                  'View →',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentVoyagesTable(FinancialDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Voyages',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/owner/financial/voyages'),
                child: Text(
                  'View All Voyages →',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.recentVoyages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No recent voyages found')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.recentVoyages.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final v = data.recentVoyages[index];
                return InkWell(
                  onTap: () => context.push('/owner/financial/voyages/${v.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.voyageNo,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              v.date,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Profit: ${currencyFormatter.format(v.profit)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: v.profit >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Inc: ${currencyFormatter.format(v.income)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Exp: ${currencyFormatter.format(v.expenses)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}