import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_fish_entry_row.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../providers/billing_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../fish/presentation/providers/fish_provider.dart';
import '../../../boats/domain/entities/boat_entity.dart';
import '../../../fish/domain/entities/fish_entity.dart';
import '../../../bookings/presentation/providers/booking_provider.dart';
import '../../../reports/presentation/providers/report_provider.dart';

// ─── Fish Entry helper ─────────────────────────────────────────────────────────

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
    'fishName': selectedFish?.name ?? selectedFish?.displayName ?? '',
    'weightKg': double.tryParse(weightCtrl.text) ?? 0,
    'pricePerKg': double.tryParse(rateCtrl.text) ?? 0,
    'totalAmount': amount,
  };

  void dispose() {
    weightCtrl.dispose();
    rateCtrl.dispose();
  }
}

// ─── Main Tabbed Screen ────────────────────────────────────────────────────────

// lib/features/billing/presentation/screens/billing_form_screen.dart

class BillingFormScreen extends ConsumerStatefulWidget {
  final String? billId;
  final int? tabIndex; // ✅ ADD THIS - 0 = New Bill, 1 = View Bills

  const BillingFormScreen({
    super.key,
    this.billId,
    this.tabIndex, // ✅ ADD THIS
  });

  @override
  ConsumerState<BillingFormScreen> createState() => _BillingFormScreenState();
}

class _BillingFormScreenState extends ConsumerState<BillingFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.tabIndex ?? 0, // ✅ USE tabIndex
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tabIndex == 0 ? 'New Bill' : 'View Bills'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'New Bill'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'View Bills'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NewBillTab(
            onBillCreated: () {
              _tabController.animateTo(1);
              ref.read(billingProvider.notifier).load();
            },
          ),
          const _ViewBillsTab(),
        ],
      ),
    );
  }
}

// ─── New Bill Tab ──────────────────────────────────────────────────────────────

class _NewBillTab extends ConsumerStatefulWidget {
  final VoidCallback onBillCreated;
  const _NewBillTab({required this.onBillCreated});

  @override
  ConsumerState<_NewBillTab> createState() => _NewBillTabState();
}

class _NewBillTabState extends ConsumerState<_NewBillTab> {
  final _formKey = GlobalKey<FormState>();
  BoatEntity? _selectedBoat;
  final _notesCtrl = TextEditingController();
  final List<_FishEntry> _entries = [];
  bool _isSubmitting = false;
  List<FishEntity> _agentFish = [];
  bool _isLoading = true;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _addEntry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final e in _entries) e.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = ref.read(authProvider).user;
    final isStaff = user?.isStaff == true;

    print('🟢 Loading initial data - isStaff: $isStaff');

    // Load bookings
    await ref.read(bookingProvider.notifier).loadAllBookings();
    await ref.read(bookingProvider.notifier).loadMyBookedBoats();

    if (isStaff && user?.agentId != null) {
      final agentId = user!.agentId!;
      print('🟢 Staff user, loading fish for agent: $agentId');

      try {
        final fish = await ref
            .read(fishRepositoryProvider)
            .getFishByAgent(agentId);
        print('🟢 Received ${fish.length} fish from repository');

        if (mounted) {
          // ✅ CRITICAL: Update state and force rebuild
          setState(() {
            _agentFish = List.from(fish);
            _isLoading = false;
            _isDataLoaded = true;
          });

          // ✅ Force rebuild after a small delay to ensure UI updates
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {});
            }
          });
        }
      } catch (e) {
        print('❌ Error loading agent fish: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isDataLoaded = true;
          });
        }
      }
    } else {
      print('🟢 Non-staff user, loading all fish');
      setState(() => _isLoading = true);

      try {
        await ref.read(fishProvider.notifier).load();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isDataLoaded = true;
          });
        }
      } catch (e) {
        print('❌ Error loading fish: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isDataLoaded = true;
          });
        }
      }
    }
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

    print('🟢 [UI] Submitting bill data: $data');

    final bill = await ref.read(billingProvider.notifier).createBill(data);

    setState(() => _isSubmitting = false);

    if (bill != null && mounted) {
      print('🟢 [UI] Bill created successfully: ${bill.billNumber}');
      AppErrorBanner.showSuccess(context, 'Bill ${bill.billNumber} created!');
      widget.onBillCreated();
      await _loadInitialData();
    } else if (mounted) {
      final error = ref.read(billingProvider).error;
      print('🔴 [UI] Bill creation failed: $error');
      AppErrorBanner.show(
        context,
        error ?? 'Failed to create bill. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fishState = ref.watch(fishProvider);
    final bookingState = ref.watch(bookingProvider);
    final billingState = ref.watch(billingProvider);
    final user = ref.read(authProvider).user;
    final isStaff = user?.isStaff == true;

    // ✅ Determine which fish list to use
    final availableFishList = isStaff ? _agentFish : fishState.fish;

    // ✅ Define availableBookedBoats
    final myBookedBoats = bookingState.myBookedBoats;
    final usedBoatIds = billingState.bills.map((b) => b.boatId).toSet();

    // ✅ This was missing
    final availableBookedBoats = myBookedBoats;

    // ✅ Determine which fish list to use
    print('🔍 BUILD - isStaff: $isStaff');
    print('🔍 BUILD - _agentFish length: ${_agentFish.length}');
    print('🔍 BUILD - fishState.fish length: ${fishState.fish.length}');
    print('🔍 BUILD - availableFishList length: ${availableFishList.length}');
    print('🔍 BUILD - _isLoading: $_isLoading');
    print('🔍 BUILD - _isDataLoaded: $_isDataLoaded');

    // Deduplicate boats
    final deduplicatedBoats = myBookedBoats
        .fold(<String, BoatEntity>{}, (map, boat) {
          map[boat.id] = boat;
          return map;
        })
        .values
        .toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.p16),
        children: [
          // Header Card
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
                Container(
                  padding: const EdgeInsets.all(AppSizes.p12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Billing Record', style: AppTextStyles.h4),
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p24),

          // Boat Selection
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radius8),
                      ),
                      child: Icon(
                        Icons.directions_boat_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Text(
                      'Select Booked Boat',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (availableBookedBoats.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusCircular,
                          ),
                        ),
                        child: Text(
                          '${availableBookedBoats.length} available',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.p12),

                if (availableBookedBoats.isEmpty && !bookingState.isLoading)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.p16),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.warning,
                          size: 24,
                        ),
                        const SizedBox(width: AppSizes.p12),
                        Expanded(
                          child: Text(
                            'You have no booked boats available for billing. '
                            'Please book a boat first from the "Available Boats" tab.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (bookingState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),

                if (availableBookedBoats.isNotEmpty)
                  DropdownButtonFormField<BoatEntity>(
                    value: _selectedBoat,
                    validator: (v) => v == null ? 'Select a boat' : null,
                    decoration: InputDecoration(
                      hintText: 'Choose a booked boat...',
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.directions_boat,
                          color: _selectedBoat != null
                              ? AppColors.primary
                              : AppColors.textHint,
                          size: 20,
                        ),
                      ),
                      suffixIcon: _selectedBoat != null
                          ? IconButton(
                              onPressed: () =>
                                  setState(() => _selectedBoat = null),
                              icon: Icon(
                                Icons.close,
                                color: AppColors.textHint,
                                size: 18,
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textHint,
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<BoatEntity>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select a booked boat...',
                                style: TextStyle(color: AppColors.textHint),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...deduplicatedBoats.map(
                        (boat) => DropdownMenuItem(
                          value: boat,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.directions_boat,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        boat.boatName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Reg: ${boat.boatNumber}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedBoat = v),
                    style: AppTextStyles.bodyMedium,
                  ),

                if (_selectedBoat != null)
                  Container(
                    margin: const EdgeInsets.only(top: AppSizes.p12),
                    padding: const EdgeInsets.all(AppSizes.p12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius8,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSizes.p12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Boat',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_selectedBoat!.boatName} (${_selectedBoat!.boatNumber})',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.p24),

          // ✅ FISH ENTRIES SECTION - FIXED
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius8,
                            ),
                          ),
                          child: Icon(
                            Icons.set_meal,
                            color: AppColors.accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSizes.p8),
                        Text(
                          'Fish Entries',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Refresh button
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          onPressed: _isLoading ? null : _loadInitialData,
                          tooltip: 'Refresh fish list',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusCircular,
                            ),
                          ),
                          child: Text(
                            '${_entries.length} items',
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p12),

                // ✅ Loading state
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 8),
                          Text('Loading fish data...'),
                        ],
                      ),
                    ),
                  )
                // ✅ Empty state
                else if (availableFishList.isEmpty && _isDataLoaded)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.warningLight),
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      color: AppColors.warningLight.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isStaff
                                ? 'No fish added by your agent yet. Please contact your agent to add fish.'
                                : 'No fish available. Please add fish first.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )
                // ✅ Show fish entries with data
                else if (availableFishList.isNotEmpty && _isDataLoaded)
                  ...List.generate(_entries.length, (i) {
                    final entry = _entries[i];

                    // ✅ CRITICAL: Use a unique key that changes when fishList updates
                    return AppFishEntryRow<FishEntity>(
                      key: ValueKey(
                        'fish_entry_$i${availableFishList.length}_${availableFishList.hashCode}',
                      ),
                      index: i,
                      selectedFish: entry.selectedFish,
                      fishList: availableFishList, // ✅ Pass the list with data
                      fishLabel: (f) => f.name, // Use name directly
                      onFishSelected: (f) {
                        print('🟢 Selected fish: ${f.name}');
                        setState(() {
                          entry.selectedFish = f;
                        });
                      },
                      weightController: entry.weightCtrl,
                      rateController: entry.rateCtrl,
                      onRemove: () => _removeEntry(i),
                      totalAmount: entry.amount,
                    );
                  })
                else
                  const SizedBox(),

                const SizedBox(height: AppSizes.p8),
                OutlinedButton.icon(
                  onPressed: (availableFishList.isEmpty || _isLoading)
                      ? null
                      : _addEntry,
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
              ],
            ),
          ),

          const SizedBox(height: AppSizes.p16),

          // Notes Field
          AppTextField(
            label: 'Notes (Optional)',
            controller: _notesCtrl,
            maxLines: 3,
            prefixIcon: Icons.notes_outlined,
          ),

          const SizedBox(height: AppSizes.p20),

          // Total Amount
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.08),
                  AppColors.success.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppSizes.radius8),
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Text('Total Amount', style: AppTextStyles.h4),
                  ],
                ),
                Text(
                  '₹ ${_totalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.p24),

          // Submit Button
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
// ─── View Bills Tab ────────────────────────────────────────────────────────────

// ─── View Bills Tab ────────────────────────────────────────────────────────────

class _ViewBillsTab extends ConsumerStatefulWidget {
  const _ViewBillsTab();

  @override
  ConsumerState<_ViewBillsTab> createState() => _ViewBillsTabState();
}

class _ViewBillsTabState extends ConsumerState<_ViewBillsTab> {
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
          '/users/by-agent/${user.id}',
          queryParameters: {'role': 'STAFF', 'isActive': true},
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

  // ✅ Cancel entire bill
  Future<void> _cancelBill(dynamic bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Bill'),
        content: Text(
          'Are you sure you want to cancel bill ${bill.billNumber}? This cannot be undone.',
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
          ref.read(reportProvider.notifier).loadAll();
        } else {
          AppErrorBanner.show(context, 'Failed to cancel bill');
        }
      }
    }
  }

  // ✅ Remove specific fish entry from a bill
  Future<void> _removeFishEntry(dynamic bill, int fishIndex) async {
    final fish = bill.fishEntries[fishIndex];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Fish Entry'),
        content: Text(
          'Remove "${fish.fishName}" from bill ${bill.billNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Remove'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      // ✅ Create updated fish entries list without the removed one
      final updatedEntries = bill.fishEntries
          .asMap()
          .entries
          .where((entry) => entry.key != fishIndex)
          .map((entry) => entry.value)
          .toList();

      // ✅ Calculate new totals
      double newSubtotal = 0;
      for (final entry in updatedEntries) {
        newSubtotal += entry.amount;
      }
      final commissionRate = 0.05;
      final commissionAmount = newSubtotal * commissionRate;
      final newGrandTotal = newSubtotal + commissionAmount;

      // ✅ Update bill with new fish entries and totals
      final ok = await ref.read(billingProvider.notifier).updateBill(bill.id, {
        'fishEntries': updatedEntries
            .map(
              (e) => {
                'fishId': e.fishId,
                'fishName': e.fishName,
                'weightKg': e.weight,
                'pricePerKg': e.rate,
                'totalAmount': e.amount,
              },
            )
            .toList(),
        'subtotal': newSubtotal,
        'grandTotal': newGrandTotal,
        'commissionAmount': commissionAmount,
      });

      if (mounted) {
        if (ok) {
          AppErrorBanner.showSuccess(
            context,
            'Fish entry removed successfully',
          );
          ref.read(billingProvider.notifier).load();
          ref.read(reportProvider.notifier).loadAll();
        } else {
          AppErrorBanner.show(context, 'Failed to remove fish entry');
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
                            const DataColumn(label: Text('Amount')),
                            const DataColumn(label: Text('Total')),
                            const DataColumn(label: Text('Billed by')),
                            const DataColumn(label: Text('Status')),
                            if (isAgent)
                              const DataColumn(label: Text('Action')),
                          ],
                          rows: bills
                              .asMap()
                              .entries
                              .map((billEntry) {
                                final billIndex = billEntry.key;
                                final bill = billEntry.value;
                                final billedByName = bill.agentName.isNotEmpty
                                    ? bill.agentName
                                    : 'Unknown';

                                final isCancellable =
                                    bill.status == 'CONFIRMED';

                                // ✅ Expand each bill into multiple rows (one per fish)
                                final fishRows = bill.fishEntries.asMap().entries.map((
                                  fishEntry,
                                ) {
                                  final fishIndex = fishEntry.key;
                                  final fish = fishEntry.value;
                                  final isFirstRow = fishIndex == 0;

                                  return DataRow(
                                    color:
                                        WidgetStateProperty.resolveWith<Color?>(
                                          (states) => bill.status == 'CANCELLED'
                                              ? AppColors.errorLight
                                                    .withOpacity(0.3)
                                              : isFirstRow
                                              ? null
                                              : AppColors.primarySurface
                                                    .withOpacity(0.3),
                                        ),
                                    cells: [
                                      // S.No - show only for first fish entry
                                      DataCell(
                                        isFirstRow
                                            ? Text('${billIndex + 1}')
                                            : const Text(''),
                                      ),

                                      // Bill No - show only for first fish entry
                                      DataCell(
                                        isFirstRow
                                            ? Text(
                                                bill.billNumber,
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              )
                                            : const Text(''),
                                      ),

                                      // Boat - show only for first fish entry
                                      DataCell(
                                        isFirstRow
                                            ? Text(
                                                bill.boatName.isNotEmpty
                                                    ? bill.boatName
                                                    : bill.boatNumber,
                                              )
                                            : const Text(''),
                                      ),

                                      // ✅ Fish Name
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // ✅ Remove button for each fish entry
                                            if (isCancellable && isAgent)
                                              InkWell(
                                                onTap: () => _removeFishEntry(
                                                  bill,
                                                  fishIndex,
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 14,
                                                    color: AppColors.error,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 4),
                                            Text(
                                              fish.fishName,
                                              style: AppTextStyles.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Weight
                                      DataCell(
                                        Text(
                                          fish.weight.toStringAsFixed(2),
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ),

                                      // Price/kg
                                      DataCell(
                                        Text(
                                          fish.rate.toStringAsFixed(2),
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ),

                                      // Amount
                                      DataCell(
                                        Text(
                                          '₹${fish.amount.toStringAsFixed(2)}',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),

                                      // Total - show only for first fish entry
                                      DataCell(
                                        isFirstRow
                                            ? Text(
                                                '₹${bill.netAmount.toStringAsFixed(2)}',
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                      color: AppColors.success,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              )
                                            : const Text(''),
                                      ),

                                      // Billed by - show only for first fish entry
                                      DataCell(
                                        isFirstRow
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.person_outline,
                                                    size: 14,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      billedByName,
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Text(''),
                                      ),

                                      // Status - show only for first fish entry
                                      DataCell(
                                        isFirstRow
                                            ? AppStatusBadge.fromString(
                                                bill.status,
                                              )
                                            : const Text(''),
                                      ),

                                      // Action - Cancel Bill button (only for first fish entry)
                                      if (isAgent)
                                        DataCell(
                                          isFirstRow && isCancellable
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.cancel_outlined,
                                                    size: 18,
                                                    color: AppColors.error,
                                                  ),
                                                  onPressed: () =>
                                                      _cancelBill(bill),
                                                  tooltip: 'Cancel Bill',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                )
                                              : const Text(''),
                                        ),
                                    ],
                                  );
                                }).toList();

                                return fishRows;
                              })
                              .expand((row) => row)
                              .toList(),
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
