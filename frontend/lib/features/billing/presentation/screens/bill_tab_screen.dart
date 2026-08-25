import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_fish_entry_row.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../providers/billing_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../fish/presentation/providers/fish_provider.dart';
import '../../../boats/domain/entities/boat_entity.dart';
import '../../../fish/domain/entities/fish_entity.dart';

// ─── Fish Entry helper (for New Bill) ──────────────────────────────────────────

class _FishEntry {
  FishEntity? selectedFish;
  TextEditingController weightCtrl = TextEditingController();
  TextEditingController rateCtrl = TextEditingController();

  double get amount {
    final w = double.tryParse(weightCtrl.text) ?? 0;
    final r = double.tryParse(rateCtrl.text) ?? 0;
    return w * r;
  }

  Map<String, dynamic> toJson() => {
    'fishId': selectedFish?.id ?? '',
    'weightKg': double.tryParse(weightCtrl.text) ?? 0,
    'pricePerKg': double.tryParse(rateCtrl.text) ?? 0,
    'totalAmount': amount,
  };

  void dispose() {
    weightCtrl.dispose();
    rateCtrl.dispose();
  }
}

// ─── Main Screen ───────────────────────────────────────────────────────────────

class BillTabScreen extends ConsumerStatefulWidget {
  const BillTabScreen({super.key});

  @override
  ConsumerState<BillTabScreen> createState() => _BillTabScreenState();
}

class _BillTabScreenState extends ConsumerState<BillTabScreen> {
  _BillView _currentView = _BillView.menu;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        leading: _currentView != _BillView.menu
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentView = _BillView.menu),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  String _getTitle() {
    switch (_currentView) {
      case _BillView.menu:
        return 'Bills';
      case _BillView.newBill:
        return 'New Bill';
      case _BillView.viewBills:
        return 'View Bills';
    }
  }

  Widget _buildBody() {
    switch (_currentView) {
      case _BillView.menu:
        return _buildMenu();
      case _BillView.newBill:
        return _NewBillForm(
          onBillCreated: () {
            setState(() => _currentView = _BillView.viewBills);
            ref.read(billingProvider.notifier).load();
          },
        );
      case _BillView.viewBills:
        return const _ViewBillsTable();
    }
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.p24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // New Bill card
          _MenuCard(
            icon: Icons.add_circle_outline,
            title: 'New Bill',
            subtitle: 'Create a new billing record',
            color: AppColors.primary,
            onTap: () => setState(() => _currentView = _BillView.newBill),
          ),
          const SizedBox(height: AppSizes.p24),
          // View Bills card
          _MenuCard(
            icon: Icons.receipt_long_outlined,
            title: 'View Bills',
            subtitle: 'View all billing records',
            color: AppColors.secondary,
            onTap: () => setState(() => _currentView = _BillView.viewBills),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

enum _BillView { menu, newBill, viewBills }

// ─── Menu Card ─────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.p24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSizes.radius16),
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(width: AppSizes.p20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── New Bill Form ─────────────────────────────────────────────────────────────

class _NewBillForm extends ConsumerStatefulWidget {
  final VoidCallback onBillCreated;
  const _NewBillForm({required this.onBillCreated});

  @override
  ConsumerState<_NewBillForm> createState() => _NewBillFormState();
}

class _NewBillFormState extends ConsumerState<_NewBillForm> {
  final _formKey = GlobalKey<FormState>();
  BoatEntity? _selectedBoat;
  final _notesCtrl = TextEditingController();
  final List<_FishEntry> _entries = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addEntry();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final e in _entries) e.dispose();
    super.dispose();
  }

  void _addEntry() => setState(() => _entries.add(_FishEntry()));
  void _removeEntry(int i) => setState(() {
    _entries[i].dispose();
    _entries.removeAt(i);
  });

  double get _totalAmount => _entries.fold(0, (s, e) => s + e.amount);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBoat == null) {
      AppErrorBanner.show(context, 'Please select a boat');
      return;
    }
    if (_entries.isEmpty) {
      AppErrorBanner.show(context, 'Add at least one fish entry');
      return;
    }
    if (_entries.any((e) => e.selectedFish == null)) {
      AppErrorBanner.show(context, 'Select fish for all entries');
      return;
    }

    setState(() => _isSubmitting = true);
    final data = {
      'boatId': _selectedBoat!.id,
      'billDate': DateTime.now().toIso8601String(),
      'fishEntries': _entries.map((e) => e.toJson()).toList(),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
    };
    final bill = await ref.read(billingProvider.notifier).createBill(data);
    setState(() => _isSubmitting = false);
    if (bill != null && mounted) {
      AppErrorBanner.showSuccess(context, 'Bill ${bill.billNumber} created!');
      widget.onBillCreated();
    } else if (mounted) {
      AppErrorBanner.show(context, 'Failed to create bill. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final fishState = ref.watch(fishProvider);
    final billingState = ref.watch(billingProvider);

    final bookedBoatIds = billingState.bills.map((b) => b.boatId).toSet();
    final bookedBoats = boatState.boats
        .where((b) => b.isActive && bookedBoatIds.contains(b.id))
        .toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.p16),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: AppSizes.p16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Billing ', style: AppTextStyles.h4),
                    Text(
                      'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p20),
          Text('Boat Selection', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSizes.p8),
          DropdownButtonFormField<BoatEntity>(
            value: _selectedBoat,
            validator: (v) => v == null ? 'Select a boat' : null,
            decoration: InputDecoration(
              labelText: bookedBoats.isEmpty
                  ? 'No booked boats'
                  : 'Select Boat',
              prefixIcon: const Icon(Icons.directions_boat_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
            ),
            items: bookedBoats
                .map(
                  (boat) => DropdownMenuItem(
                    value: boat,
                    child: Text('${boat.boatName} (${boat.boatNumber})'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedBoat = v),
          ),
          const SizedBox(height: AppSizes.p24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fish Entries', style: AppTextStyles.labelLarge),
              Text(
                '${_entries.length} items',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          ...List.generate(_entries.length, (i) {
            final entry = _entries[i];
            return StatefulBuilder(
              builder: (_, setRow) => AppFishEntryRow<FishEntity>(
                index: i,
                selectedFish: entry.selectedFish,
                fishList: fishState.fish,
                fishLabel: (f) => f.displayName,
                onFishSelected: (f) {
                  entry.selectedFish = f;
                  setRow(() {});
                  setState(() {});
                },
                weightController: entry.weightCtrl
                  ..addListener(() => setRow(() {})),
                rateController: entry.rateCtrl
                  ..addListener(() => setRow(() {})),
                onRemove: () => _removeEntry(i),
                totalAmount: entry.amount,
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _addEntry,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Fish Entry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          AppTextField(
            label: 'Notes (Optional)',
            controller: _notesCtrl,
            maxLines: 3,
            prefixIcon: Icons.notes_outlined,
          ),
          const SizedBox(height: AppSizes.p20),
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: AppTextStyles.h4),
                Text(
                  '₹ ${_totalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.h3.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          AppButton(
            text: 'Create Bill',
            onPressed: _submit,
            isLoading: _isSubmitting,
            leadingIcon: Icons.check_circle_outline,
          ),
          const SizedBox(height: AppSizes.p32),
        ],
      ),
    );
  }
}

// ─── View Bills Table ──────────────────────────────────────────────────────────

class _ViewBillsTable extends ConsumerStatefulWidget {
  const _ViewBillsTable();

  @override
  ConsumerState<_ViewBillsTable> createState() => _ViewBillsTableState();
}

class _ViewBillsTableState extends ConsumerState<_ViewBillsTable> {
  String? _selectedStaffId;
  List<_StaffOption> _staffList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStaff());
  }

  Future<void> _loadStaff() async {
    final user = ref.read(authProvider).user;
    if (user != null && user.isAgent) {
      try {
        final dio = ref.read(dioClientProvider).dio;
        final response = await dio.get(
          '/users',
          queryParameters: {
            'agentId': user.id,
            'role': 'STAFF',
            'isActive': true,
          },
        );
        final List data = response.data['data'] ?? response.data ?? [];
        setState(() {
          _staffList = data
              .map(
                (e) => _StaffOption(
                  id: e['_id'] as String? ?? '',
                  name: e['name'] as String? ?? 'Unknown',
                ),
              )
              .toList();
        });
      } catch (_) {}
    }
  }

  Future<void> _cancelBill(dynamic bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Bill'),
        content: Text(
          'Are you sure you want to cancel bill ${bill.billNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final ok = await ref
          .read(billingProvider.notifier)
          .updateStatus(bill.id, 'CANCELLED');
      if (mounted) {
        if (ok) {
          AppErrorBanner.showSuccess(
            context,
            'Bill ${bill.billNumber} cancelled',
          );
          ref.read(billingProvider.notifier).load();
        } else {
          AppErrorBanner.show(context, 'Failed to cancel bill');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingProvider);
    final user = ref.watch(authProvider).user;
    final isAgent = user?.isAgent == true;

    final bills = state.bills.where((b) {
      return _selectedStaffId == null || b.staffId == _selectedStaffId;
    }).toList();

    return Column(
      children: [
        // Staff filter
        if (isAgent && _staffList.isNotEmpty)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p8,
            ),
            child: DropdownButtonFormField<String?>(
              value: _selectedStaffId,
              decoration: InputDecoration(
                labelText: 'Filter by Staff',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p12,
                  vertical: AppSizes.p8,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Staff')),
                ..._staffList.map(
                  (staff) => DropdownMenuItem(
                    value: staff.id,
                    child: Text(staff.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedStaffId = v),
            ),
          ),
        const Divider(height: 1),
        // Table
        Expanded(
          child: AppLoadingOverlay(
            isLoading: state.isLoading,
            child: bills.isEmpty
                ? const AppEmptyState(
                    title: 'No Bills Found',
                    subtitle: 'No billing records found',
                    icon: Icons.receipt_long_outlined,
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(billingProvider.notifier).load(),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.primarySurface,
                          ),
                          headingTextStyle: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          dataTextStyle: AppTextStyles.bodySmall,
                          columnSpacing: 16,
                          horizontalMargin: 12,
                          columns: [
                            const DataColumn(label: Text('S.No')),
                            const DataColumn(label: Text('Bill No')),
                            const DataColumn(label: Text('Boat')),
                            const DataColumn(label: Text('Fish')),
                            const DataColumn(label: Text('Weight (kg)')),
                            const DataColumn(label: Text('Price/kg')),
                            const DataColumn(label: Text('Total')),
                            const DataColumn(label: Text('Status')),
                            if (isAgent)
                              const DataColumn(label: Text('Action')),
                          ],
                          rows: List.generate(bills.length, (i) {
                            final bill = bills[i];
                            final firstEntry = bill.fishEntries.isNotEmpty
                                ? bill.fishEntries.first
                                : null;
                            final isCancellable =
                                bill.status != 'CANCELLED' &&
                                bill.status != 'PAID';

                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>(
                                (states) => bill.status == 'CANCELLED'
                                    ? AppColors.errorLight.withOpacity(0.3)
                                    : null,
                              ),
                              cells: [
                                DataCell(Text('${i + 1}')),
                                DataCell(
                                  Text(
                                    bill.billNumber,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    bill.boatName.isNotEmpty
                                        ? bill.boatName
                                        : bill.boatNumber,
                                  ),
                                ),
                                DataCell(Text(firstEntry?.fishName ?? '-')),
                                DataCell(
                                  Text(
                                    firstEntry?.weight.toStringAsFixed(2) ??
                                        '-',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    firstEntry?.rate.toStringAsFixed(2) ?? '-',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '₹${bill.netAmount.toStringAsFixed(2)}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  AppStatusBadge.fromString(bill.status),
                                ),
                                if (isAgent)
                                  DataCell(
                                    isCancellable
                                        ? SizedBox(
                                            height: 32,
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  _cancelBill(bill),
                                              icon: const Icon(
                                                Icons.cancel_outlined,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'Cancel',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.error,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            '-',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: AppColors.textHint,
                                                ),
                                          ),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _StaffOption {
  final String id;
  final String name;
  const _StaffOption({required this.id, required this.name});
}
