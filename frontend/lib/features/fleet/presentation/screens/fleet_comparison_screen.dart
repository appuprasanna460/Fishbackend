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

class FleetComparisonScreen extends ConsumerStatefulWidget {
  const FleetComparisonScreen({super.key});

  @override
  ConsumerState<FleetComparisonScreen> createState() => _FleetComparisonScreenState();
}

class _FleetComparisonScreenState extends ConsumerState<FleetComparisonScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<BoatEntity> _selectedBoats = [];
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'Last 3 Months', 'This Year'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(boatProvider.notifier).load(ownerId: user.id);
        ref.read(voyageProvider.notifier).loadVoyages();
        ref.read(financialVoyagesProvider.notifier).fetchVoyages();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addBoatToCompare(BoatEntity boat) {
    if (_selectedBoats.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can compare a maximum of 3 boats.')),
      );
      return;
    }
    if (_selectedBoats.any((b) => b.id == boat.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boat is already added to comparison.')),
      );
      return;
    }
    setState(() {
      _selectedBoats.add(boat);
    });
  }

  void _removeBoatFromCompare(String boatId) {
    setState(() {
      _selectedBoats.removeWhere((b) => b.id == boatId);
    });
  }

  Map<String, dynamic> _calculateBoatMetrics(
    BoatEntity boat,
    List<VoyageEntity> voyages,
    List<VoyagePLListItem> financialVoyages,
  ) {
    final boatVoyages = voyages.where((v) => v.boatId == boat.id || v.boatName == boat.boatName).toList();
    final boatVoyageIds = boatVoyages.map((v) => v.id).toSet();

    final int tripsCount = boatVoyages.length;
    final double totalFuel = boatVoyages.fold<double>(0.0, (sum, v) => sum + v.supplies.fuelToCarry);

    double totalRevenue = 0.0;
    double totalExpenses = 0.0;
    double totalProfit = 0.0;

    for (var fv in financialVoyages) {
      if (boatVoyageIds.contains(fv.id) || fv.boatName.toLowerCase() == boat.boatName.toLowerCase()) {
        totalRevenue += fv.income;
        totalExpenses += fv.expenses;
        totalProfit += fv.profit;
      }
    }

    final double margin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;
    final String efficiencyStr = '${margin.toStringAsFixed(1)}%';
    final double catchWeight = totalRevenue / 150000.0;

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return {
      'trips': tripsCount,
      'revenue': currencyFormatter.format(totalRevenue),
      'profit': currencyFormatter.format(totalProfit),
      'efficiency': efficiencyStr,
      'fuel': '${totalFuel.toStringAsFixed(0)} L',
      'catch': '${catchWeight.toStringAsFixed(1)} Tons',
    };
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final boats = boatState.boats;
    final voyageState = ref.watch(voyageProvider);
    final voyages = voyageState.voyages;
    final financialState = ref.watch(financialVoyagesProvider);
    final financialVoyages = financialState.voyages;

    if (_selectedBoats.isEmpty && boats.isNotEmpty) {
      _selectedBoats.addAll(boats.take(2));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fleet Comparison'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Financial'),
            Tab(text: 'Operations'),
            Tab(text: 'Catches'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: _periods.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPeriod = val);
                  },
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddBoatDialog(boats),
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Compare'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedBoats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedBoats.map((b) {
                    return Chip(
                      label: Text(b.boatName),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeBoatFromCompare(b.id),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 12),

          Expanded(
            child: _selectedBoats.isEmpty
                ? const Center(child: Text('Select boats to compare'))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildComparisonTab('overview', voyages, financialVoyages),
                      _buildComparisonTab('financial', voyages, financialVoyages),
                      _buildComparisonTab('operations', voyages, financialVoyages),
                      _buildComparisonTab('catches', voyages, financialVoyages),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTab(String type, List<VoyageEntity> voyages, List<VoyagePLListItem> financialVoyages) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.p16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: AppColors.border, width: 0.5),
              ),
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Metric', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    ..._selectedBoats.map((b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        b.boatName,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                    )),
                  ],
                ),
                ..._buildMetricRowsForType(type, voyages, financialVoyages),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<TableRow> _buildMetricRowsForType(
    String type,
    List<VoyageEntity> voyages,
    List<VoyagePLListItem> financialVoyages,
  ) {
    final metricsConfig = {
      'overview': [
        {'label': 'Trips Count', 'key': 'trips'},
        {'label': 'Revenue', 'key': 'revenue'},
        {'label': 'Net Profit', 'key': 'profit'},
        {'label': 'Efficiency', 'key': 'efficiency'},
      ],
      'financial': [
        {'label': 'Total Revenue', 'key': 'revenue'},
        {'label': 'Net Profit', 'key': 'profit'},
        {'label': 'Fuel Expense', 'key': 'fuel'},
      ],
      'operations': [
        {'label': 'Number of Trips', 'key': 'trips'},
        {'label': 'Fuel Consumption', 'key': 'fuel'},
        {'label': 'Efficiency Rating', 'key': 'efficiency'},
      ],
      'catches': [
        {'label': 'Total Catch weight', 'key': 'catch'},
        {'label': 'Avg. Catch / Trip', 'key': 'efficiency'},
      ],
    };

    final selectedConfig = metricsConfig[type] ?? [];

    return selectedConfig.map((config) {
      final label = config['label']!;
      final key = config['key']!;

      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          ..._selectedBoats.map((b) {
            final stats = _calculateBoatMetrics(b, voyages, financialVoyages);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                '${stats[key] ?? "-"}',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      );
    }).toList();
  }

  void _showAddBoatDialog(List<BoatEntity> boats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Boat to Compare'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: boats.length,
            itemBuilder: (context, index) {
              final b = boats[index];
              final isAlreadySelected = _selectedBoats.any((selected) => selected.id == b.id);
              return ListTile(
                title: Text(b.boatName),
                subtitle: Text('Number: ${b.boatNumber}'),
                trailing: isAlreadySelected 
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : const Icon(Icons.add_circle_outline),
                onTap: isAlreadySelected ? null : () {
                  Navigator.pop(ctx);
                  _addBoatToCompare(b);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}