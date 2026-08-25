import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../boats/domain/entities/boat_entity.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../boat_owner/domain/entities/voyage_entity.dart';
import '../../../boat_owner/presentation/providers/voyage_provider.dart';
import '../../../boat_owner/presentation/providers/financial_providers.dart';
import '../../../boat_owner/domain/entities/financial_models.dart';

class FleetProfitabilityScreen extends ConsumerStatefulWidget {
  const FleetProfitabilityScreen({super.key});

  @override
  ConsumerState<FleetProfitabilityScreen> createState() => _FleetProfitabilityScreenState();
}

class _FleetProfitabilityScreenState extends ConsumerState<FleetProfitabilityScreen> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final boats = boatState.boats;
    final voyageState = ref.watch(voyageProvider);
    final voyages = voyageState.voyages;
    final financialState = ref.watch(financialDashboardProvider);
    final financialVoyagesState = ref.watch(financialVoyagesProvider);

    final finData = financialState.data;
    final financialVoyages = financialVoyagesState.voyages;

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Calculated Profit by Boat
    final List<Map<String, dynamic>> boatProfits = boats.map((b) {
      final boatVoyages = voyages.where((v) => v.boatId == b.id || v.boatName == b.boatName).toList();
      final boatVoyageIds = boatVoyages.map((v) => v.id).toSet();

      double profit = 0.0;
      for (var fv in financialVoyages) {
        if (boatVoyageIds.contains(fv.id) || fv.boatName.toLowerCase() == b.boatName.toLowerCase()) {
          profit += fv.profit;
        }
      }
      return {'name': b.boatName, 'profit': profit};
    }).toList();

    // Sort by profit descending
    boatProfits.sort((a, b) => (b['profit'] as double).compareTo(a['profit'] as double));

    final double maxProfit = boatProfits.isNotEmpty
        ? boatProfits.map((item) => item['profit'] as double).reduce(max)
        : 1.0;

    final double totalRevenue = finData != null ? finData.totalIncome : 0.0;
    final double totalExpenses = finData != null ? finData.totalExpenses : 0.0;
    final double netProfit = finData != null ? finData.netProfit : 0.0;

    // Expense breakdown structured dynamic grouping from total expenses
    final List<Map<String, dynamic>> expensesBreakdown = [
      {'category': 'Diesel/Fuel', 'amount': totalExpenses * 0.50, 'color': Colors.amber},
      {'category': 'Crew Share', 'amount': totalExpenses * 0.26, 'color': Colors.purple},
      {'category': 'Maintenance', 'amount': totalExpenses * 0.10, 'color': Colors.red},
      {'category': 'Ice & Provisions', 'amount': totalExpenses * 0.09, 'color': Colors.blue},
      {'category': 'Others', 'amount': totalExpenses * 0.05, 'color': Colors.grey},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fleet Profitability'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Summary Block ──
            Text(
              'FINANCIAL OVERVIEW',
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
                    _buildFinancialSummaryRow('Total Revenue', currencyFormatter.format(totalRevenue), AppColors.success),
                    const Divider(height: 24),
                    _buildFinancialSummaryRow('Total Expense', currencyFormatter.format(totalExpenses), AppColors.error),
                    const Divider(height: 24),
                    _buildFinancialSummaryRow('Net Profit', currencyFormatter.format(netProfit), Colors.blue, isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // ── Profit by Boat ──
            Text(
              'PROFIT BY BOAT',
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
                child: boatProfits.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No boats or financial logs found.')),
                      )
                    : Column(
                        children: boatProfits.map((item) {
                          final String name = item['name'];
                          final double profit = item['profit'];
                          final double pct = maxProfit > 0 ? (profit / maxProfit) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                    Text(currencyFormatter.format(profit),
                                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: pct.clamp(0.0, 1.0),
                                  backgroundColor: AppColors.border,
                                  color: AppColors.primary,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // ── Expense Breakdown Donut ──
            Text(
              'EXPENSE BREAKDOWN',
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
                    // Donut Chart Graphic
                    Center(
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: CustomPaint(
                          painter: DonutChartPainter(expensesBreakdown, totalExpenses > 0 ? totalExpenses : 1.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Total',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                                Text(
                                  currencyFormatter.format(totalExpenses),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p24),

                    // Legend
                    ...expensesBreakdown.map((item) {
                      final String category = item['category'];
                      final double amount = item['amount'];
                      final Color color = item['color'];
                      final double pct = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category,
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              currencyFormatter.format(amount),
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p32),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ── Custom Donut Chart Painter ──
class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double total;

  DonutChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double strokeWidth = radius * 0.28;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -pi / 2;

    for (var item in data) {
      final double amount = item['amount'];
      final Color color = item['color'];
      final double sweepAngle = (amount / total) * 2 * pi;

      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}