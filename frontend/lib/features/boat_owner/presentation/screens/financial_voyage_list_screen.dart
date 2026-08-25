import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../providers/financial_providers.dart';
import '../../domain/entities/financial_models.dart';

class FinancialVoyageListScreen extends ConsumerStatefulWidget {
  const FinancialVoyageListScreen({super.key});

  @override
  ConsumerState<FinancialVoyageListScreen> createState() => _FinancialVoyageListScreenState();
}

class _FinancialVoyageListScreenState extends ConsumerState<FinancialVoyageListScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Completed', 'Active', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(financialVoyagesProvider.notifier).fetchVoyages();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialVoyagesProvider);
    
    // Filter and Search logic
    final filteredVoyages = state.voyages.where((v) {
      final matchesSearch = v.voyageNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.boatName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _selectedStatus == 'All' || 
          v.status.toLowerCase() == _selectedStatus.toLowerCase() ||
          (_selectedStatus == 'Active' && v.status == 'ACTIVE') ||
          (_selectedStatus == 'Completed' && v.status == 'COMPLETED') ||
          (_selectedStatus == 'Cancelled' && v.status == 'CANCELLED');
          
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Voyage P&L List',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by voyage no. or boat...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border.withOpacity(0.6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _statusFilters.map<Widget>((status) {
                    final isSelected = _selectedStatus == status;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = status;
                          });
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // List details
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Error: ${state.error}'))
                    : filteredVoyages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filteredVoyages.length,
                            itemBuilder: (context, index) {
                              final v = filteredVoyages[index];
                              return _buildVoyagePLCard(v);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'No Voyages Found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No voyages match your search query or selected filter criteria.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoyagePLCard(VoyagePLListItem v) {
    Color statusColor = Colors.grey;
    if (v.status == 'COMPLETED') statusColor = Colors.green;
    else if (v.status == 'ACTIVE') statusColor = Colors.orange;
    else if (v.status == 'CANCELLED') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/owner/financial/voyages/${v.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voyage No & Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    v.voyageNo,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      v.status,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Boat & Date details
              Text(
                'Boat: ${v.boatName}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    v.dateRange,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey[150]),
              const SizedBox(height: 8),

              // Financial Performance metrics grid
              Row(
                children: [
                  Expanded(
                    child: _buildPLMetric('Income', currencyFormatter.format(v.income)),
                  ),
                  Expanded(
                    child: _buildPLMetric('Expenses', currencyFormatter.format(v.expenses)),
                  ),
                  Expanded(
                    child: _buildPLMetric(
                      'Net Profit',
                      currencyFormatter.format(v.profit),
                      textColor: v.profit >= 0 ? Colors.green : Colors.red,
                      isBold: true,
                    ),
                  ),
                  Expanded(
                    child: _buildPLMetric('Margin', '${v.profitMargin.toStringAsFixed(1)}%'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPLMetric(String label, String value, {Color? textColor, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
