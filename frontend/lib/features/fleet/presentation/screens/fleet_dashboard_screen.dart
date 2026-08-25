import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../boat_owner/presentation/providers/voyage_provider.dart';
import '../../../boat_owner/presentation/providers/financial_providers.dart';

class FleetDashboardScreen extends ConsumerStatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  ConsumerState<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends ConsumerState<FleetDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(boatProvider.notifier).load(ownerId: user.id);
        ref.read(voyageProvider.notifier).loadVoyages();
        ref.read(financialDashboardProvider.notifier).fetchDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final boatState = ref.watch(boatProvider);
    final voyageState = ref.watch(voyageProvider);
    final financialState = ref.watch(financialDashboardProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final boats = boatState.boats;
    final voyages = voyageState.voyages;
    final finData = financialState.data;

    // Currency Formatter
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Sum fuel used across voyages
    final totalFuel = voyages.fold<double>(0.0, (sum, v) => sum + v.supplies.fuelToCarry);

    final String revenueStr = finData != null ? currencyFormatter.format(finData.totalIncome) : '₹0';
    final String expenseStr = finData != null ? currencyFormatter.format(finData.totalExpenses) : '₹0';
    final String profitStr = finData != null ? currencyFormatter.format(finData.netProfit) : '₹0';
    final String fuelStr = '${totalFuel.toStringAsFixed(0)} L';

    // Derived Status Logic: At Sea vs In Harbour
    final totalBoatsCount = boats.length;
    final atSeaCount = voyages.where((v) => v.status == 'ACTIVE').length;
    final inHarbourCount = totalBoatsCount - atSeaCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fleet Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fleet Overview Title ──
            Text(
              'FLEET OVERVIEW',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSizes.p12),

            // ── KPI Overview Cards Row ──
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    label: 'Total Boats',
                    value: '$totalBoatsCount',
                    icon: Icons.directions_boat_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKPICard(
                    label: 'At Sea',
                    value: '$atSeaCount',
                    icon: Icons.sailing,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKPICard(
                    label: 'In Harbour',
                    value: '$inHarbourCount',
                    icon: Icons.anchor,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p24),

            // ── This Week Summary Section ──
            Text(
              'THIS WEEK SUMMARY',
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryMetric(
                            label: 'Total Revenue',
                            value: revenueStr,
                            icon: Icons.trending_up,
                            color: AppColors.success,
                          ),
                        ),
                        Container(width: 1, height: 50, color: AppColors.border),
                        Expanded(
                          child: _buildSummaryMetric(
                            label: 'Total Expense',
                            value: expenseStr,
                            icon: Icons.trending_down,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryMetric(
                            label: 'Net Profit',
                            value: profitStr,
                            icon: Icons.monetization_on_outlined,
                            color: Colors.blue,
                          ),
                        ),
                        Container(width: 1, height: 50, color: AppColors.border),
                        Expanded(
                          child: _buildSummaryMetric(
                            label: 'Fuel Used',
                            value: fuelStr,
                            icon: Icons.local_gas_station_outlined,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // ── Menu Navigation Grid ──
            Text(
              'FLEET MODULES',
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
              childAspectRatio: 1.4,
              children: [
                _buildModuleCard(
                  title: 'Fleet Comparison',
                  subtitle: 'Compare performance',
                  icon: Icons.compare_arrows_rounded,
                  route: '/owner/fleet/compare',
                  color: Colors.indigo,
                ),
                _buildModuleCard(
                  title: 'Profitability',
                  subtitle: 'Financial insights',
                  icon: Icons.pie_chart_outline_rounded,
                  route: '/owner/fleet/profitability',
                  color: Colors.teal,
                ),
                _buildModuleCard(
                  title: 'Crew Allocation',
                  subtitle: 'Manage duty rosters',
                  icon: Icons.groups_outlined,
                  route: '/owner/fleet/crew-allocation',
                  color: Colors.purple,
                ),
                _buildModuleCard(
                  title: 'Voyage Calendar',
                  subtitle: 'Schedule and plan',
                  icon: Icons.calendar_month_outlined,
                  route: '/owner/fleet/calendar',
                  color: Colors.blueGrey,
                ),
                _buildModuleCard(
                  title: 'Performance',
                  subtitle: 'Analysis and logs',
                  icon: Icons.insights_rounded,
                  route: '/owner/fleet/insights',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p24),

            // ── Quick Actions ──
            Text(
              'QUICK ACTIONS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Schedule Voyage',
                    leadingIcon: Icons.add_road_outlined,
                    onPressed: () => context.push('/owner/voyages/new'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Manage Crew',
                    leadingIcon: Icons.people_outline,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push('/owner/team'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p32),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}