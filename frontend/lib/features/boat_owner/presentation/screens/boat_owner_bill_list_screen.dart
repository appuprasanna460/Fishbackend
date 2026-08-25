// lib/features/boat_owner/presentation/screens/boat_owner_bill_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../billing/domain/entities/bill_entity.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/boat_owner_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Scoped provider: loads bills from /api/boat-owner/bills endpoint
// ─────────────────────────────────────────────────────────────────────────────
class _BoatOwnerBillsState {
  final List<BillEntity> bills;
  final bool isLoading;
  final String? error;

  const _BoatOwnerBillsState({
    this.bills = const [],
    this.isLoading = false,
    this.error,
  });

  _BoatOwnerBillsState copyWith({
    List<BillEntity>? bills,
    bool? isLoading,
    String? error,
  }) =>
      _BoatOwnerBillsState(
        bills: bills ?? this.bills,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class _BoatOwnerBillsNotifier extends StateNotifier<_BoatOwnerBillsState> {
  final BoatOwnerApiService _api;

  _BoatOwnerBillsNotifier(this._api) : super(const _BoatOwnerBillsState()) {
    load();
  }

  Future<void> load({
    String? boatId,
    String? fromDate,
    String? toDate,
    String? createdBy,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getBills(
        boatId: boatId,
        fromDate: fromDate,
        toDate: toDate,
        createdBy: createdBy,
        limit: 100,
      );
      final List raw = res['data'] ?? [];
      state = state.copyWith(
        bills: raw.map((e) => BillEntity.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final _boatOwnerBillsProvider = StateNotifierProvider.autoDispose<
    _BoatOwnerBillsNotifier, _BoatOwnerBillsState>((ref) {
  final api = BoatOwnerApiService(ref.watch(dioClientProvider));
  return _BoatOwnerBillsNotifier(api);
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class BoatOwnerBillListScreen extends ConsumerStatefulWidget {
  const BoatOwnerBillListScreen({super.key});

  @override
  ConsumerState<BoatOwnerBillListScreen> createState() =>
      _BoatOwnerBillListScreenState();
}

class _BoatOwnerBillListScreenState
    extends ConsumerState<BoatOwnerBillListScreen> {
  String? _selectedBoatId;
  DateTimeRange? _selectedDateRange;
  String _createdByFilter = 'ALL'; // ALL, STAFF, AGENT
  final _fishNameController = TextEditingController();
  String _fishNameQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _fishNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  void _applyServerFilter() {
    ref.read(_boatOwnerBillsProvider.notifier).load(
          boatId: _selectedBoatId,
          fromDate: _selectedDateRange?.start.toIso8601String(),
          toDate: _selectedDateRange?.end.toIso8601String(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final billsState = ref.watch(_boatOwnerBillsProvider);
    final boatState = ref.watch(boatProvider);
    final authState = ref.watch(authProvider);

    final user = authState.user;
    final myBoats = boatState.boats
        .where((b) => b.ownerId == user?.id && b.isActive)
        .toList();

    // Client-side filters: staffId presence and fish name search
    final bills = billsState.bills.where((b) {
      if (_createdByFilter == 'STAFF' && b.staffId.isEmpty) return false;
      if (_createdByFilter == 'AGENT' && b.staffId.isNotEmpty) return false;
      if (_fishNameQuery.isNotEmpty) {
        final hasFish = b.fishEntries.any((f) =>
            f.fishName.toLowerCase().contains(_fishNameQuery.toLowerCase()));
        if (!hasFish) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bills & Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _applyServerFilter,
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: billsState.isLoading,
        child: Column(
          children: [
            // Error Banner
            if (billsState.error != null)
              Container(
                width: double.infinity,
                color: AppColors.errorLight,
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Error: ${billsState.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // ── Advanced Filters ─────────────────────────────────────────────
            Card(
              margin: const EdgeInsets.all(AppSizes.p12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius16)),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Boat dropdown (server filter)
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _selectedBoatId,
                            decoration: InputDecoration(
                              labelText: 'Filter Boat',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radius12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('All Boats')),
                              ...myBoats.map((b) => DropdownMenuItem(
                                  value: b.id, child: Text(b.boatName))),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedBoatId = val);
                              _applyServerFilter();
                            },
                          ),
                        ),
                        const SizedBox(width: AppSizes.p8),
                        // Created-by (client-side)
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _createdByFilter,
                            decoration: InputDecoration(
                              labelText: 'Created By',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radius12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'ALL', child: Text('All')),
                              DropdownMenuItem(
                                  value: 'STAFF', child: Text('Staff')),
                              DropdownMenuItem(
                                  value: 'AGENT', child: Text('Agent')),
                            ],
                            onChanged: (val) =>
                                setState(() => _createdByFilter = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Row(
                      children: [
                        // Date range (server filter)
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              await _selectDateRange(context);
                              _applyServerFilter();
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date Range',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radius12)),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDateRange == null
                                        ? 'Any Date'
                                        : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  if (_selectedDateRange != null)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() =>
                                            _selectedDateRange = null);
                                        _applyServerFilter();
                                      },
                                      child:
                                          const Icon(Icons.clear, size: 16),
                                    )
                                  else
                                    const Icon(Icons.calendar_today,
                                        size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.p8),
                        // Fish name (client-side)
                        Expanded(
                          child: TextField(
                            controller: _fishNameController,
                            decoration: InputDecoration(
                              labelText: 'Fish Name',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radius12)),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                              suffixIcon: _fishNameQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          size: 16),
                                      onPressed: () {
                                        _fishNameController.clear();
                                        setState(() => _fishNameQuery = '');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (val) =>
                                setState(() => _fishNameQuery = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // ── Bill Table ───────────────────────────────────────────────────
            Expanded(
              child: bills.isEmpty && !billsState.isLoading
                  ? const Center(
                      child: Text('No Bills found.',
                          style: TextStyle(color: AppColors.textHint)))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(
                                label: Text('Bill No',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Boat',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Fish Count',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Weight (kg)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Amount (₹)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Created By',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Date',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: bills.map((bill) {
                            final createdBy = bill.staffName.isNotEmpty
                                ? bill.staffName
                                : bill.agentName;
                            return DataRow(
                              onSelectChanged: (_) {
                                context.push('/owner/bills/${bill.id}');
                              },
                              cells: [
                                DataCell(Text(bill.billNumber,
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold))),
                                DataCell(Text(bill.boatName)),
                                DataCell(
                                    Text('${bill.fishEntries.length}')),
                                DataCell(Text(
                                    bill.totalWeight.toStringAsFixed(1))),
                                DataCell(Text(
                                    '₹${bill.netAmount.toStringAsFixed(0)}')),
                                DataCell(Text(createdBy.isNotEmpty
                                    ? createdBy
                                    : 'Admin')),
                                DataCell(Text(DateFormat('dd-MMM-yyyy')
                                    .format(bill.billDate))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
