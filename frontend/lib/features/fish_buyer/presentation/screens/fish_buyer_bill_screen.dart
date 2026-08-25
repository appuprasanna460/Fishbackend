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
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_searchable_dropdown.dart';
import '../providers/fish_buyer_bill_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../fish/presentation/providers/fish_provider.dart';

// ─── Main Screen with Tabs ───────────────────────────────────────────────────────

class FishBuyerBillScreen extends ConsumerStatefulWidget {
  final int? tabIndex;
  const FishBuyerBillScreen({super.key, this.tabIndex});

  @override
  ConsumerState<FishBuyerBillScreen> createState() =>
      _FishBuyerBillScreenState();
}

class _FishBuyerBillScreenState extends ConsumerState<FishBuyerBillScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.tabIndex ?? 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fishBuyerBillProvider.notifier).load();
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
        title: const Text('Fish Buyer Bills'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color.fromARGB(255, 255, 255, 255),
          labelColor: const Color.fromARGB(255, 255, 255, 255),
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
              ref.read(fishBuyerBillProvider.notifier).load();
            },
          ),
          const _ViewBillsTab(),
        ],
      ),
    );
  }
}

// ─── New Bill Tab ───────────────────────────────────────────────────────────────

// ─── New Bill Tab ───────────────────────────────────────────────────────────────

// ─── New Bill Tab ───────────────────────────────────────────────────────────────

class _NewBillTab extends ConsumerStatefulWidget {
  final VoidCallback onBillCreated;
  const _NewBillTab({required this.onBillCreated});

  @override
  ConsumerState<_NewBillTab> createState() => _NewBillTabState();
}

class _NewBillTabState extends ConsumerState<_NewBillTab> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAgentId;
  String? _selectedFishId;
  String? _selectedFishName;
  final _weightCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _fishList = [];

  // ✅ Form version to force rebuild
  int _formVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load fish
      await ref.read(fishProvider.notifier).load();
      final fishState = ref.read(fishProvider);
      setState(() {
        _fishList = fishState.fish
            .map(
              (f) => {
                '_id': f.id,
                'name': f.name,
                'displayName': f.displayName,
              },
            )
            .toList();
      });

      // Load agents using the new endpoint
      try {
        final dio = ref.read(dioClientProvider).dio;
        final response = await dio.get('/users/commission-agents');
        final data = response.data['data'] ?? response.data ?? [];
        if (data is List) {
          setState(() {
            _agents = data
                .map(
                  (e) => {
                    '_id': e['_id'] ?? '',
                    'name': e['name'] ?? 'Unknown',
                    'email': e['email'] ?? '',
                  },
                )
                .toList();
          });
        }
      } catch (e) {
        print('❌ Error loading agents: $e');
        if (mounted) {
          AppErrorBanner.show(
            context,
            'Could not load agents. Please check your connection.',
          );
        }
      }
    } catch (e) {
      print('❌ Error loading initial data: $e');
      if (mounted) {
        AppErrorBanner.show(
          context,
          'Failed to load data: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  //  Helper method to clear all fields
  void _clearAllFields() {
    setState(() {
      _selectedAgentId = null;
      _selectedFishId = null;
      _selectedFishName = null;
      _weightCtrl.clear();
      _priceCtrl.clear();
      _notesCtrl.clear();
      _formVersion++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.reset(); // now runs against the NEW widget state
    });
  }

  double get _totalAmount {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final p = double.tryParse(_priceCtrl.text) ?? 0;
    return w * p;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAgentId == null) {
      AppErrorBanner.show(context, 'Please select a commission agent');
      return;
    }
    if (_selectedFishId == null && _selectedFishName == null) {
      AppErrorBanner.show(context, 'Please select a fish');
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'agentId': _selectedAgentId,
      if (_selectedFishId != null) 'fishId': _selectedFishId,
      'fishName': _selectedFishName ?? 'Unknown Fish',
      'weightKg': double.tryParse(_weightCtrl.text) ?? 0,
      'pricePerKg': double.tryParse(_priceCtrl.text) ?? 0,
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
    };

    final bill = await ref
        .read(fishBuyerBillProvider.notifier)
        .createBill(data);

    setState(() => _isSubmitting = false);

    if (bill != null && mounted) {
      AppErrorBanner.showSuccess(
        context,
        'Bill ${bill['billNumber']} created!',
      );

      // ✅ Clear all fields properly
      _clearAllFields();

      // Navigate to view bills tab
      widget.onBillCreated();
    } else if (mounted) {
      AppErrorBanner.show(context, 'Failed to create bill');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fishState = ref.watch(fishProvider);

    // ✅ Use the form version to create unique keys for dropdowns
    final agentDropdownKey = ValueKey('agent_$_formVersion');
    final fishDropdownKey = ValueKey('fish_$_formVersion');

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.p16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.roleBuyer.withOpacity(0.05),
                  AppColors.info.withOpacity(0.05),
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
                    color: AppColors.roleBuyer,
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Purchase Bill', style: AppTextStyles.h4),
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

          // Dropdown 1: Select Commission Agent
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
                        color: AppColors.roleBuyer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radius8),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: AppColors.roleBuyer,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Text(
                      'Commission Agent',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p12),
                // ✅ Add key to dropdown
                DropdownButtonFormField<String>(
                  key: agentDropdownKey, // ✅ UNIQUE KEY
                  value: _selectedAgentId,
                  validator: (v) => v == null ? 'Select an agent' : null,
                  decoration: InputDecoration(
                    hintText: _agents.isEmpty
                        ? 'No agents available'
                        : 'Choose a commission agent...',
                    prefixIcon: Icon(
                      Icons.person,
                      color: _selectedAgentId != null
                          ? AppColors.roleBuyer
                          : AppColors.textHint,
                    ),
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
                        color: AppColors.roleBuyer,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textHint,
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'Select Commission Agent...',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    ),
                    ..._agents.map(
                      (agent) => DropdownMenuItem(
                        value: agent['_id'],
                        child: Text(agent['name'] ?? 'Unknown'),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedAgentId = v),
                ),
                if (_agents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.p8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSizes.p6),
                        Expanded(
                          child: Text(
                            'No commission agents available. Please contact admin.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p16),

          // Dropdown 2: Select Fish
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
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radius8),
                      ),
                      child: Icon(
                        Icons.set_meal,
                        color: AppColors.info,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Text(
                      'Select Fish',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p12),
                // ✅ Add key to dropdown
                DropdownButtonFormField<String>(
                  key: fishDropdownKey, // ✅ UNIQUE KEY
                  value: _selectedFishId,
                  validator: (v) => v == null ? 'Select a fish' : null,
                  decoration: InputDecoration(
                    hintText: _fishList.isEmpty
                        ? 'No fish available'
                        : 'Choose fish...',
                    prefixIcon: Icon(
                      Icons.set_meal,
                      color: _selectedFishId != null
                          ? AppColors.info
                          : AppColors.textHint,
                    ),
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
                      borderSide: BorderSide(color: AppColors.info, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textHint,
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'Select Fish...',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    ),
                    ..._fishList.map(
                      (fish) => DropdownMenuItem(
                        value: fish['_id'],
                        child: Text(
                          fish['displayName'] ?? fish['name'] ?? 'Unknown',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedFishId = v;
                      final fish = _fishList.firstWhere(
                        (f) => f['_id'] == v,
                        orElse: () => {'name': ''},
                      );
                      _selectedFishName = fish['name'] as String?;
                    });
                  },
                ),
                if (_fishList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.p8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSizes.p6),
                        Expanded(
                          child: Text(
                            'No fish available. Please add fish first.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p16),

          // Weight & Price fields
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Weight (KG)',
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.monitor_weight,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final val = double.tryParse(v);
                    if (val == null || val <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: AppTextField(
                  label: 'Price per KG (₹)',
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final val = double.tryParse(v);
                    if (val == null || val <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p16),

          // Notes
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
            text: 'Create Purchase Bill',
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
// ─── View Bills Tab ─────────────────────────────────────────────────────────────

class _ViewBillsTab extends ConsumerStatefulWidget {
  const _ViewBillsTab();

  @override
  ConsumerState<_ViewBillsTab> createState() => _ViewBillsTabState();
}

class _ViewBillsTabState extends ConsumerState<_ViewBillsTab> {
  Future<void> _confirmDelete(
    BuildContext context,
    Map<String, dynamic> bill,
  ) async {
    final billNumber = bill['billNumber'] ?? 'this bill';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text(
          'Are you sure you want to delete $billNumber? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final id = bill['_id'];
    if (id == null) return;

    final success = await ref
        .read(fishBuyerBillProvider.notifier)
        .deleteBill(id);

    if (!context.mounted) return;

    if (success) {
      AppErrorBanner.showSuccess(context, '$billNumber deleted');
    } else {
      AppErrorBanner.show(context, 'Failed to delete bill');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fishBuyerBillProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.bills.isEmpty) {
      return const AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Bills Yet',
        subtitle: 'No purchase bills yet.\nCreate your first bill!',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fishBuyerBillProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.p16),
        itemCount: state.bills.length,
        itemBuilder: (_, i) {
          final bill = state.bills[i];
          final billNumber = bill['billNumber'] ?? 'FBB-????';
          final agentName = bill['agentId'] is Map
              ? (bill['agentId'] as Map)['name'] ?? ''
              : '';
          final fishName = bill['fishName'] ?? '';
          final weight = (bill['weightKg'] ?? 0).toString();
          final total = (bill['totalAmount'] ?? 0).toDouble();
          final status = bill['status'] ?? 'CONFIRMED';
          final date = bill['billDate'] != null
              ? DateFormat(
                  'dd MMM yyyy',
                ).format(DateTime.parse(bill['billDate']))
              : '';

          return Container(
            margin: const EdgeInsets.only(bottom: AppSizes.p8),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.roleBuyer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radius8),
                      ),
                      child: Icon(
                        Icons.shopping_bag,
                        color: AppColors.roleBuyer,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            billNumber,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (date.isNotEmpty)
                            Text(
                              date,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AppStatusBadge.fromString(status),
                    // ✅ Delete button
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      tooltip: 'Delete bill',
                      onPressed: () => _confirmDelete(context, bill),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(left: AppSizes.p8),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p8),
                if (agentName.isNotEmpty)
                  _InfoRow(icon: Icons.person, label: 'Agent: $agentName'),
                if (fishName.isNotEmpty)
                  _InfoRow(icon: Icons.set_meal, label: 'Fish: $fishName'),
                _InfoRow(
                  icon: Icons.monitor_weight,
                  label: 'Weight: $weight KG',
                ),
                const Divider(height: AppSizes.p16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹ ${total.toStringAsFixed(2)}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.roleBuyer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
