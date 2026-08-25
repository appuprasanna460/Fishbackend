import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../providers/financial_providers.dart';
import '../../domain/entities/financial_models.dart';

class FinancialVoyageSummaryScreen extends ConsumerStatefulWidget {
  final String voyageId;
  final int initialTab;

  const FinancialVoyageSummaryScreen({
    super.key,
    required this.voyageId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<FinancialVoyageSummaryScreen> createState() => _FinancialVoyageSummaryScreenState();
}

class _FinancialVoyageSummaryScreenState extends ConsumerState<FinancialVoyageSummaryScreen> with SingleTickerProviderStateMixin {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  late TabController _tabController;

  // Controllers for editable fields
  final Map<String, TextEditingController> _catchControllers = {};
  final Map<String, TextEditingController> _expenseControllers = {};
  final Map<String, TextEditingController> _crewControllers = {};
  final Map<String, bool> _crewPaidStates = {};

  bool _isEditingIncome = false;
  bool _isEditingExpenses = false;
  bool _isEditingCrew = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    Future.microtask(() {
      ref.read(voyagePLSummaryProvider(widget.voyageId).notifier).fetchSummary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _catchControllers.forEach((_, c) => c.dispose());
    _expenseControllers.forEach((_, c) => c.dispose());
    _crewControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  void _initializeControllers(VoyagePLSummaryData data) {
    // 1. Income Catch controllers
    for (var item in data.catchIncome) {
      if (!_catchControllers.containsKey(item.speciesName)) {
        _catchControllers[item.speciesName] = TextEditingController(
          text: item.rate > 0 ? item.rate.toStringAsFixed(0) : '',
        );
      }
    }

    // 2. Expenses controllers
    for (var item in data.expenses) {
      if (!item.isCustom && !_expenseControllers.containsKey(item.expenseName)) {
        _expenseControllers[item.expenseName] = TextEditingController(
          text: item.rate > 0 ? item.rate.toStringAsFixed(0) : '',
        );
      }
    }

    // 3. Crew controllers & paid checkboxes
    for (var item in data.crew) {
      if (!_crewControllers.containsKey(item.crewMemberId)) {
        _crewControllers[item.crewMemberId] = TextEditingController(
          text: item.advance > 0 ? item.advance.toStringAsFixed(0) : '',
        );
      }
      if (!_crewPaidStates.containsKey(item.crewMemberId)) {
        _crewPaidStates[item.crewMemberId] = item.paid;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voyagePLSummaryProvider(widget.voyageId));
    final data = state.data;

    if (data != null) {
      _initializeControllers(data);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          data?.voyage.voyageNo ?? 'Voyage Summary',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
            Tab(text: 'Crew'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : data == null
                  ? const Center(child: Text('Voyage not found'))
                  : Stack(
                      children: [
                        TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSummaryTab(data),
                            _buildIncomeTab(data),
                            _buildExpensesTab(data),
                            _buildCrewTab(data),
                          ],
                        ),
                        if (state.isSaving)
                          Container(
                            color: Colors.black.withOpacity(0.15),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
    );
  }

  // ── 1. Summary Tab ──────────────────────────────────────────────────────────
  Widget _buildSummaryTab(VoyagePLSummaryData data) {
    Color statusColor = Colors.grey;
    if (data.voyage.status == 'COMPLETED') statusColor = Colors.green;
    else if (data.voyage.status == 'ACTIVE') statusColor = Colors.orange;
    else if (data.voyage.status == 'CANCELLED') statusColor = Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vessel details header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.directions_boat, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.voyage.vesselName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No: ${data.voyage.vesselNumber} • Capt: ${data.voyage.captainName}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data.voyage.status,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // High-level Financial Cards
          _buildSummaryFinancialCards(data.summary),
          const SizedBox(height: 16),

          // Voyage information log card
          _buildInfoSection('Voyage Details', [
            _buildInfoRow('Departure', '${data.voyage.departureDate} (${data.voyage.departureTime})'),
            _buildInfoRow('Arrival', data.voyage.arrivalDate ?? 'Active/Planned'),
            _buildInfoRow('Duration', '${data.voyage.durationDays} Days'),
          ]),
          const SizedBox(height: 24),

          // Action report buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('P&L report downloaded successfully')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download P&L'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('P&L summary report shared')),
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryFinancialCards(VoyagePLTotals summary) {
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
            'Financial Statement',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Total Income', currencyFormatter.format(summary.totalIncome), valueBold: true, valueColor: Colors.green),
          Divider(color: Colors.grey[200]),
          _buildInfoRow('Total Expenses', currencyFormatter.format(summary.totalExpenses), valueBold: true, valueColor: Colors.red),
          Divider(color: Colors.grey[200]),
          _buildInfoRow(
            'Net Profit',
            currencyFormatter.format(summary.netProfit),
            valueBold: true,
            valueColor: summary.netProfit >= 0 ? Colors.green : Colors.red,
            isLarge: true,
          ),
          Divider(color: Colors.grey[200]),
          _buildInfoRow('Profit Margin', '${summary.profitMargin.toStringAsFixed(1)}%', valueBold: true),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
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
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool valueBold = false, Color? valueColor, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: isLarge ? 14 : 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: isLarge ? 16 : 14,
              fontWeight: valueBold || isLarge ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Income Tab ──────────────────────────────────────────────────────────
  Widget _buildIncomeTab(VoyagePLSummaryData data) {
    final catchIncomeTotal = data.catchIncome.fold<double>(0.0, (sum, item) {
      final rateController = _catchControllers[item.speciesName];
      final rate = double.tryParse(rateController?.text ?? '') ?? 0.0;
      return sum + (item.quantity * rate);
    });

    final otherIncomeTotal = data.otherIncome.fold(0.0, (sum, item) => sum + item.amount);
    final totalIncome = catchIncomeTotal + otherIncomeTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catch Income Grid Card
          Container(
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
                      'Catch Income',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isEditingIncome ? Icons.check_circle : Icons.edit, color: AppColors.primary),
                      onPressed: () {
                        if (_isEditingIncome) {
                          // Save Rates to DB
                          final List<Map<String, dynamic>> ratesPayload = [];
                          data.catchIncome.forEach((item) {
                            final text = _catchControllers[item.speciesName]?.text ?? '';
                            final rate = double.tryParse(text) ?? 0.0;
                            ratesPayload.add({
                              'speciesName': item.speciesName,
                              'quantity': item.quantity,
                              'rate': rate,
                            });
                          });
                          ref.read(voyagePLSummaryProvider(widget.voyageId).notifier).updateRates(ratesPayload);
                        }
                        setState(() {
                          _isEditingIncome = !_isEditingIncome;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.catchIncome.isEmpty)
                  const Center(child: Text('No catches logged for this voyage'))
                else
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(1.5),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      // Header Row
                      TableRow(
                        children: [
                          _buildTableHeader('Species'),
                          _buildTableHeader('Weight'),
                          _buildTableHeader('Rate'),
                          _buildTableHeader('Amount'),
                        ],
                      ),
                      // Data Rows
                      ...data.catchIncome.map((item) {
                        final rateController = _catchControllers[item.speciesName];
                        final rateVal = double.tryParse(rateController?.text ?? '') ?? 0.0;
                        final amountVal = item.quantity * rateVal;

                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                item.speciesName,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ),
                            Text(
                              '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: _isEditingIncome
                                  ? SizedBox(
                                      height: 35,
                                      child: TextField(
                                        controller: rateController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          setState(() {}); // Recalculate local quantities dynamically
                                        },
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          border: OutlineInputBorder(),
                                          prefixText: '₹',
                                        ),
                                        style: GoogleFonts.inter(fontSize: 13),
                                      ),
                                    )
                                  : Text(
                                      '₹${rateVal.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                    ),
                            ),
                            Text(
                              currencyFormatter.format(amountVal),
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[200]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Catch Income Total',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    Text(
                      currencyFormatter.format(catchIncomeTotal),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Other Income Card
          Container(
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
                      'Other Income',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      onPressed: () => _showAddOtherIncomeSheet(context),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.otherIncome.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(child: Text('No other income added')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.otherIncome.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey[150]),
                    itemBuilder: (context, index) {
                      final item = data.otherIncome[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.incomeName,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ),
                            Text(
                              currencyFormatter.format(item.amount),
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () {
                                if (item.id != null) {
                                  ref.read(voyagePLSummaryProvider(widget.voyageId).notifier).deleteOtherIncome(item.id!);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Total Income statement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL INCOME',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  currencyFormatter.format(totalIncome),
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOtherIncomeSheet(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Other Income', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Income Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (name.isNotEmpty && amt > 0) {
                  ref.read(voyagePLSummaryProvider(widget.voyageId).notifier).addOtherIncome(name, amt);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // ── 3. Expenses Tab ────────────────────────────────────────────────────────
  Widget _buildExpensesTab(VoyagePLSummaryData data) {
    final standardExpenses = data.expenses.where((e) => !e.isCustom).toList();
    final customExpenses = data.expenses.where((e) => e.isCustom).toList();

    final voyageExpensesTotal = data.expenses.fold<double>(0.0, (sum, item) {
      if (!item.isCustom) {
        final controller = _expenseControllers[item.expenseName];
        final rate = double.tryParse(controller?.text ?? '') ?? 0.0;
        return sum + (item.quantity * rate);
      }
      return sum + item.amount;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Standard Expenses Card
          Container(
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
                      'Standard Voyage Expenses',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isEditingExpenses ? Icons.check_circle : Icons.edit, color: AppColors.primary),
                      onPressed: () {
                        if (_isEditingExpenses) {
                          // Save standard supply rates to DB
                          final List<Map<String, dynamic>> expensesPayload = [];
                          standardExpenses.forEach((item) {
                            final text = _expenseControllers[item.expenseName]?.text ?? '';
                            final rate = double.tryParse(text) ?? 0.0;
                            expensesPayload.add({
                              'expenseName': item.expenseName,
                              'quantity': item.quantity,
                              'unit': item.unit,
                              'rate': rate,
                            });
                          });
                          ref.read(voyagePLSummaryProvider(widget.voyageId).notifier).updateExpenses(expensesPayload);
                        }
                        setState(() {
                          _isEditingExpenses = !_isEditingExpenses;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.5),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeader('Expense'),
                        _buildTableHeader('Quantity'),
                        _buildTableHeader('Rate'),
                        _buildTableHeader('Amount'),
                      ],
                    ),
                    ...standardExpenses.map((item) {
                      final controller = _expenseControllers[item.expenseName];
                      final rateVal = double.tryParse(controller?.text ?? '') ?? 0.0;
                      final amountVal = item.quantity * rateVal;

                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              item.expenseName,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: _isEditingExpenses
                                ? SizedBox(
                                    height: 35,
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        setState(() {});
                                      },
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        border: OutlineInputBorder(),
                                        prefixText: '₹',
                                      ),
                                      style: GoogleFonts.inter(fontSize: 13),
                                    ),
                                  )
                                : Text(
                                    '₹${rateVal.toStringAsFixed(0)}',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                          ),
                          Text(
                            currencyFormatter.format(amountVal),
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Custom/Additional Expenses Card
          Container(
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
                      'Additional Expenses',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      onPressed: () => _showAddExpenseSheet(context),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (customExpenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(child: Text('No additional expenses added')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: customExpenses.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey[150]),
                    itemBuilder: (context, index) {
                      final item = customExpenses[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.expenseName,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity.toStringAsFixed(0)} ${item.unit} x ₹${item.rate.toStringAsFixed(0)}',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormatter.format(item.amount),
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () {
                                if (item.id != null) {
                                  ref.read(voyagePLSummaryProvider(widget.voyageId).notifier).deleteCustomExpense(item.id!);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Total Expenses summary statement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Voyage Expenses Total',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    Text(
                      currencyFormatter.format(voyageExpensesTotal),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Crew Settlement (Paid)',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    Text(
                      currencyFormatter.format(data.summary.crewSettlementTotal),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.red.withOpacity(0.2)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL EXPENSES',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      currencyFormatter.format(voyageExpensesTotal + data.summary.crewSettlementTotal),
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController(text: 'Qty');
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Custom Expense', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Expense Name (e.g. Repair)'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Unit (e.g. Ltrs)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rate (₹)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final qty = double.tryParse(qtyController.text.trim()) ?? 0.0;
                final unit = unitController.text.trim();
                final rate = double.tryParse(rateController.text.trim()) ?? 0.0;

                if (name.isNotEmpty && qty > 0 && unit.isNotEmpty && rate > 0) {
                  ref.read(voyagePLSummaryProvider(widget.voyageId).notifier).addCustomExpense(name, qty, unit, rate);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // ── 4. Crew Tab ───────────────────────────────────────────────────────────
  Widget _buildCrewTab(VoyagePLSummaryData data) {
    final paidSettlementTotal = data.crew.fold<double>(0.0, (sum, item) {
      final isPaid = _crewPaidStates[item.crewMemberId] ?? false;
      if (isPaid) {
        final controller = _crewControllers[item.crewMemberId];
        final advance = double.tryParse(controller?.text ?? '') ?? 0.0;
        return sum + advance;
      }
      return sum;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                      'Crew Settlement',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isEditingCrew ? Icons.check_circle : Icons.edit, color: AppColors.primary),
                      onPressed: () {
                        if (_isEditingCrew) {
                          // Save settlements payload to DB
                          final List<Map<String, dynamic>> settlementsPayload = [];
                          data.crew.forEach((item) {
                            final controller = _crewControllers[item.crewMemberId];
                            final advance = double.tryParse(controller?.text ?? '') ?? 0.0;
                            final isPaid = _crewPaidStates[item.crewMemberId] ?? false;

                            settlementsPayload.add({
                              'crewMemberId': item.crewMemberId,
                              'crewMemberName': item.crewMemberName,
                              'role': item.role,
                              'advance': advance,
                              'paid': isPaid,
                            });
                          });
                          ref.read(voyagePLSummaryProvider(widget.voyageId).notifier).updateCrewSettlement(settlementsPayload);
                        }
                        setState(() {
                          _isEditingCrew = !_isEditingCrew;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.crew.isEmpty)
                  const Center(child: Text('No crew members associated with this voyage'))
                else
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1.4),
                      3: FlexColumnWidth(1.2),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        children: [
                          _buildTableHeader('Crew Member'),
                          _buildTableHeader('Role'),
                          _buildTableHeader('Advance'),
                          _buildTableHeader('Paid'),
                        ],
                      ),
                      ...data.crew.map((item) {
                        final controller = _crewControllers[item.crewMemberId];
                        final isPaid = _crewPaidStates[item.crewMemberId] ?? false;

                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.crewMemberName,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item.role,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: _isEditingCrew
                                  ? SizedBox(
                                      height: 35,
                                      child: TextField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          setState(() {});
                                        },
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          border: OutlineInputBorder(),
                                          prefixText: '₹',
                                        ),
                                        style: GoogleFonts.inter(fontSize: 13),
                                      ),
                                    )
                                  : Text(
                                      currencyFormatter.format(item.advance),
                                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Checkbox(
                                value: isPaid,
                                activeColor: AppColors.primary,
                                onChanged: _isEditingCrew
                                    ? (bool? val) {
                                        setState(() {
                                          _crewPaidStates[item.crewMemberId] = val ?? false;
                                        });
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[200]),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Crew Settlement (Paid)',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    Text(
                      currencyFormatter.format(paidSettlementTotal),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: AppColors.textHint,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
