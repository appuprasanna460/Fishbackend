import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../boat_owner/presentation/providers/voyage_provider.dart';
import '../../../boat_owner/presentation/providers/financial_providers.dart';
import '../../../boat_owner/domain/entities/financial_models.dart';

class FleetInsightsScreen extends ConsumerStatefulWidget {
  const FleetInsightsScreen({super.key});

  @override
  ConsumerState<FleetInsightsScreen> createState() => _FleetInsightsScreenState();
}

class _FleetInsightsScreenState extends ConsumerState<FleetInsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(boatProvider.notifier).load(ownerId: user.id);
        ref.read(voyageProvider.notifier).loadVoyages();
        ref.read(financialDashboardProvider.notifier).fetchDashboard();
        ref.read(financialVoyagesProvider.notifier).fetchVoyages();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getMonthName(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final boats = boatState.boats;
    final voyageState = ref.watch(voyageProvider);
    final voyages = voyageState.voyages;
    final financialState = ref.watch(financialDashboardProvider);
    final finData = financialState.data;

    final double totalRevenue = finData != null ? finData.totalIncome : 0.0;
    final double totalProfit = finData != null ? finData.netProfit : 0.0;
    final int totalBoats = boats.isNotEmpty ? boats.length : 1;
    final int totalVoyages = voyages.isNotEmpty ? voyages.length : 1;

    // Averages Calculations
    final double avgTripsVal = voyages.length / totalBoats;
    final double avgProfitBoatVal = totalProfit / totalBoats;
    final double avgProfitTripVal = totalProfit / totalVoyages;
    final double totalCatch = totalRevenue / 150000.0; // Estimate 1 Ton per 1.5L revenue
    final double avgCatchTripVal = totalCatch / totalVoyages;

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Trends Data Extraction
    final chartData = finData?.chartData ?? [];
    final List<String> trendMonths = chartData.isNotEmpty
        ? chartData.map((e) => e.date).toList()
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

    final List<double> revenueValues = chartData.isNotEmpty
        ? chartData.map((e) => e.income / 100000.0).toList()
        : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    final List<double> profitValues = chartData.isNotEmpty
        ? chartData.map((e) => e.profit / 100000.0).toList()
        : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    final List<double> tripsValues = chartData.isNotEmpty
        ? chartData.map((e) {
            final count = voyages.where((v) {
              final String vMonth = _getMonthName(v.departureDate);
              return vMonth.toLowerCase().startsWith(e.date.toLowerCase()) || 
                     e.date.toLowerCase().contains(vMonth.toLowerCase());
            }).length;
            return count.toDouble();
          }).toList()
        : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    final List<double> catchValues = chartData.isNotEmpty
        ? chartData.map((e) => e.income / 150000.0).toList()
        : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fleet Performance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Revenue'),
            Tab(text: 'Profit'),
            Tab(text: 'Trips'),
            Tab(text: 'Catches'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── KPI Summary Cards ──
            Text(
              'AVERAGE METRICS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildKPICard('Avg. Trips / Boat', avgTripsVal.toStringAsFixed(1), Icons.trending_up, Colors.blue),
                _buildKPICard('Avg. Profit / Boat', currencyFormatter.format(avgProfitBoatVal), Icons.monetization_on, Colors.teal),
                _buildKPICard('Avg. Profit / Trip', currencyFormatter.format(avgProfitTripVal), Icons.account_balance_wallet, Colors.purple),
                _buildKPICard('Avg. Catch / Trip', '${avgCatchTripVal.toStringAsFixed(1)}T', Icons.scale, Colors.orange),
              ],
            ),
            const SizedBox(height: AppSizes.p24),

            // ── Trend Chart Area ──
            Text(
              'HISTORICAL TRENDS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: SizedBox(
                  height: 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTrendChart(revenueValues, trendMonths, 'Lakhs'),
                      _buildTrendChart(profitValues, trendMonths, 'Lakhs'),
                      _buildTrendChart(tripsValues, trendMonths, 'Trips'),
                      _buildTrendChart(catchValues, trendMonths, 'Tons'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // ── Performance Insights List ──
            Text(
              'PERFORMANCE INSIGHTS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            _buildInsightCard(
              title: 'Revenue growth trend',
              description: totalRevenue > 0
                  ? 'Total fleet revenue reached ${currencyFormatter.format(totalRevenue)} driven by active voyage logs.'
                  : 'Welcome to Fleet Performance! Insights will populate once voyages are completed.',
              icon: Icons.trending_up,
              color: AppColors.success,
            ),
            _buildInsightCard(
              title: 'Trip efficiency rating',
              description: 'Vessel allocation averages ${avgTripsVal.toStringAsFixed(1)} trips per boat this season.',
              icon: Icons.star_outline_rounded,
              color: Colors.amber,
            ),
            _buildInsightCard(
              title: 'Total fleet catches',
              description: 'Estimated fleet landings total ${totalCatch.toStringAsFixed(1)} Tons of product.',
              icon: Icons.local_gas_station_outlined,
              color: Colors.blue,
            ),
            const SizedBox(height: AppSizes.p32),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.textHint),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<double> values, List<String> months, String unit) {
    final double maxVal = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 1.0;
    final double limitMaxVal = maxVal > 0 ? maxVal : 1.0;

    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (idx) {
              final double val = values[idx];
              final double ratio = val / limitMaxVal;
              final String monthLabel = idx < months.length ? months[idx] : '';

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${val.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 120 * ratio.clamp(0.05, 1.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(months.length, (idx) {
            return SizedBox(
              width: 32,
              child: Text(
                months[idx],
                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}