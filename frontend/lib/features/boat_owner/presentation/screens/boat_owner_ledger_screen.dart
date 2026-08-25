// lib/features/boat_owner/presentation/screens/boat_owner_ledger_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/boat_owner_ledger_provider.dart';

class BoatOwnerLedgerScreen extends ConsumerStatefulWidget {
  const BoatOwnerLedgerScreen({super.key});

  @override
  ConsumerState<BoatOwnerLedgerScreen> createState() =>
      _BoatOwnerLedgerScreenState();
}

class _BoatOwnerLedgerScreenState
    extends ConsumerState<BoatOwnerLedgerScreen> {
  String? _filterBoatId;
  String? _filterType;
  String? _filterCategory;

  void _showAddEditDialog([LedgerEntry? entry]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radius24)),
      ),
      builder: (ctx) => LedgerEntryFormSheet(entry: entry),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatOwnerLedgerProvider.notifier).loadAll();
      ref.read(boatProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ledgerState = ref.watch(boatOwnerLedgerProvider);
    final boatState = ref.watch(boatProvider);
    final authState = ref.watch(authProvider);

    final user = authState.user;
    final myBoats =
        boatState.boats.where((b) => b.ownerId == user?.id && b.isActive).toList();

    // Local-filter the server-returned list
    final entries = ledgerState.entries.where((e) {
      if (_filterBoatId != null && e.boatId != _filterBoatId) return false;
      if (_filterType != null && e.type != _filterType) return false;
      if (_filterCategory != null && e.category != _filterCategory) return false;
      return true;
    }).toList();

    final summary = ledgerState.summary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ledger Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(boatOwnerLedgerProvider.notifier).loadAll(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AppLoadingOverlay(
        isLoading: ledgerState.isLoading,
        child: Column(
          children: [
            // ── Summary Dashboard ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              color: AppColors.surface,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          'Total Income',
                          '₹${summary.totalIncome.toStringAsFixed(0)}',
                          AppColors.success,
                          Icons.arrow_upward,
                        ),
                      ),
                      const SizedBox(width: AppSizes.p12),
                      Expanded(
                        child: _summaryCard(
                          'Total Expense',
                          '₹${summary.totalExpense.toStringAsFixed(0)}',
                          AppColors.error,
                          Icons.arrow_downward,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radius12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Net Profit',
                          style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${summary.netProfit.toStringAsFixed(0)}',
                          style: AppTextStyles.h4.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Filter Bar ───────────────────────────────────────────────────
            // ✅ FIXED: Use Wrap with proper constraints
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p12, vertical: AppSizes.p8),
              color: AppColors.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // ✅ FIXED: Wrap each dropdown in SizedBox with fixed width
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String?>(
                        value: _filterBoatId,
                        hint: const Text('All Boats'),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Boats')),
                          ...myBoats.map((b) => DropdownMenuItem(
                              value: b.id, child: Text(b.boatName))),
                        ],
                        onChanged: (val) =>
                            setState(() => _filterBoatId = val),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    SizedBox(
                      width: 110,
                      child: DropdownButtonFormField<String?>(
                        value: _filterType,
                        hint: const Text('All Types'),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: null, child: Text('All Types')),
                          DropdownMenuItem(
                              value: 'INCOME', child: Text('Income')),
                          DropdownMenuItem(
                              value: 'EXPENSE', child: Text('Expense')),
                        ],
                        onChanged: (val) =>
                            setState(() => _filterType = val),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String?>(
                        value: _filterCategory,
                        hint: const Text('All Categories'),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Categories')),
                          ...[...kIncomeCategories, ...kExpenseCategories].map(
                            (c) => DropdownMenuItem(
                                value: c, child: Text(categoryLabel(c))),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _filterCategory = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // ── Error Banner ─────────────────────────────────────────────────
            if (ledgerState.error != null)
              Container(
                width: double.infinity,
                color: AppColors.errorLight,
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Error: ${ledgerState.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // ── Ledger List ──────────────────────────────────────────────────
            Expanded(
              child: entries.isEmpty && !ledgerState.isLoading
                  ? const Center(
                      child: Text('No Ledger entries found.',
                          style: TextStyle(color: AppColors.textHint)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      itemCount: entries.length,
                      itemBuilder: (context, idx) {
                        final entry = entries[idx];
                        final isIncome = entry.type == 'INCOME';
                        return Card(
                          margin:
                              const EdgeInsets.only(bottom: AppSizes.p8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIncome
                                  ? AppColors.successLight.withOpacity(0.2)
                                  : AppColors.errorLight.withOpacity(0.2),
                              child: Icon(
                                isIncome
                                    ? Icons.add_circle_outline
                                    : Icons.remove_circle_outline,
                                color: isIncome
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            title: Text(
                              '${entry.boatName} - ${categoryLabel(entry.category)}',
                              style: AppTextStyles.labelLarge,
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('dd-MMM-yyyy')
                                    .format(entry.date)),
                                if (entry.description.isNotEmpty)
                                  Text(
                                    entry.description,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(
                                            color: AppColors.textHint),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${entry.amount.toStringAsFixed(0)}',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(
                                    color: isIncome
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (val) async {
                                    if (val == 'edit') {
                                      _showAddEditDialog(entry);
                                    } else if (val == 'delete') {
                                      final ok = await ref
                                          .read(boatOwnerLedgerProvider
                                              .notifier)
                                          .deleteEntry(entry.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(ok
                                              ? 'Entry deleted'
                                              : 'Failed to delete'),
                                        ));
                                      }
                                    }
                                  },
                                  itemBuilder: (ctx) => const [
                                    PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit')),
                                    PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
              Text(value,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Form Sheet - COMPLETE FIXED VERSION
// ─────────────────────────────────────────────────────────────────────────────
class LedgerEntryFormSheet extends ConsumerStatefulWidget {
  final LedgerEntry? entry;
  const LedgerEntryFormSheet({super.key, this.entry});

  @override
  ConsumerState<LedgerEntryFormSheet> createState() =>
      _LedgerEntryFormSheetState();
}

class _LedgerEntryFormSheetState
    extends ConsumerState<LedgerEntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBoatId;
  DateTime _selectedDate = DateTime.now();
  String _type = 'INCOME';
  String? _category;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      final e = widget.entry!;
      _selectedBoatId = e.boatId;
      _selectedDate = e.date;
      _type = e.type;
      _category = e.category;
      _amountController.text = e.amount.toStringAsFixed(2);
      _descController.text = e.description;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedBoatId == null ||
        _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final notifier = ref.read(boatOwnerLedgerProvider.notifier);
    bool ok;

    if (widget.entry == null) {
      ok = await notifier.addEntry(
        boatId: _selectedBoatId!,
        date: _selectedDate,
        type: _type,
        category: _category!,
        amount: double.parse(_amountController.text),
        description: _descController.text.trim(),
      );
    } else {
      ok = await notifier.updateEntry(
        widget.entry!.copyWith(
          boatId: _selectedBoatId,
          date: _selectedDate,
          type: _type,
          category: _category,
          amount: double.tryParse(_amountController.text),
          description: _descController.text.trim(),
        ),
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (widget.entry == null
                ? 'Entry added successfully'
                : 'Entry updated successfully')
            : 'Failed to save entry. Please try again.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final myBoats = boatState.boats
        .where((b) => b.ownerId == user?.id && b.isActive)
        .toList();

    final categories =
        _type == 'INCOME' ? kIncomeCategories : kExpenseCategories;

    // Ensure selected category is valid for current type
    if (_category != null && !categories.contains(_category)) {
      _category = null;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: AppSizes.p24,
        left: AppSizes.p24,
        right: AppSizes.p24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.entry == null
                    ? 'Add Ledger Entry'
                    : 'Edit Ledger Entry',
                style:
                    AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.p16),

              // ── Boat selector ───────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBoatId,
                    hint: const Text('Select Boat *'),
                    isExpanded: true,
                    items: myBoats
                        .map((b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.boatName),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedBoatId = val),
                  ),
                ),
              ),
              if (_selectedBoatId == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Please select a boat',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: AppSizes.p12),

              // ── Date picker ──────────────────────────────────────────────────
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd-MMM-yyyy').format(_selectedDate),
                        style: AppTextStyles.bodyMedium,
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p12),

              // ── Type radio ───────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                child: Row(
                  children: ['INCOME', 'EXPENSE'].map((t) {
                    return Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          t == 'INCOME' ? 'Income' : 'Expense',
                          style: AppTextStyles.bodyMedium,
                        ),
                        value: t,
                        groupValue: _type,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        onChanged: (val) {
                          setState(() {
                            _type = val!;
                            _category = null;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSizes.p12),

              // ── Category dropdown ───────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    hint: const Text('Select Category *'),
                    isExpanded: true,
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(categoryLabel(c)),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _category = val),
                  ),
                ),
              ),
              if (_category == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Please select a category',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: AppSizes.p12),

              // ── Amount ───────────────────────────────────────────────────────
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (₹) *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Amount is required';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p12),

              // ── Description ──────────────────────────────────────────────────
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.p24),

              // ── Buttons ──────────────────────────────────────────────────────
              // ✅ FIXED: Properly constrained buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSizes.p12),
                  // ✅ FIXED: ConstrainedBox prevents infinite width
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 100,
                      maxWidth: MediaQuery.of(context).size.width * 0.4,
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius12),
                        ),
                        minimumSize: const Size(80, 45),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p24),
            ],
          ),
        ),
      ),
    );
  }
}