import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../providers/crew_provider.dart';
import '../providers/voyage_provider.dart';

// Provider that fetches voyage expenses from backend
final _voyageExpensesProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, voyageId) async {
  final api = ref.watch(boatOwnerApiProvider);
  return api.getVoyageExpenses(voyageId);
});

class BoatOwnerVoyageExpenses extends ConsumerStatefulWidget {
  final String voyageId;
  const BoatOwnerVoyageExpenses({super.key, required this.voyageId});

  @override
  ConsumerState<BoatOwnerVoyageExpenses> createState() =>
      _BoatOwnerVoyageExpensesState();
}

class _BoatOwnerVoyageExpensesState
    extends ConsumerState<BoatOwnerVoyageExpenses> {
  DateTime _selectedDate = DateTime.now();
  final _fuelCtrl = TextEditingController();
  final _iceCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _fuelCtrl.dispose();
    _iceCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime dt) => DateFormat('dd-MMM-yyyy').format(dt);

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final voyage = ref.read(voyageProvider).currentVoyage;
    if (voyage == null) return;

    setState(() => _saving = true);
    try {
      final api = ref.read(boatOwnerApiProvider);
      await api.saveVoyageExpenses({
        'voyageId': voyage.id,
        'boatId': voyage.boatId,
        'date': _selectedDate.toIso8601String(),
        'fuelUsed': double.tryParse(_fuelCtrl.text) ?? 0,
        'iceUsed': double.tryParse(_iceCtrl.text) ?? 0,
        'waterUsed': double.tryParse(_waterCtrl.text) ?? 0,
      });
      ref.invalidate(_voyageExpensesProvider(widget.voyageId));
      if (mounted) AppErrorBanner.showSuccess(context, 'Expenses saved successfully');
    } catch (e) {
      if (mounted) AppErrorBanner.show(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voyage = ref.watch(voyageProvider).currentVoyage;
    final expensesAsync = ref.watch(_voyageExpensesProvider(widget.voyageId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/owner/voyages/${widget.voyageId}'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expenses',
                style: AppTextStyles.titleSmall.copyWith(color: Colors.white)),
            if (voyage != null)
              Text('${voyage.boatName ?? ''} | ${voyage.boatNumber ?? ''}',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_voyageExpensesProvider(widget.voyageId)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date picker ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '📅 Date: ${_fmtDate(_selectedDate)}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        // Pre-fill from existing records
                        final data = expensesAsync.valueOrNull;
                        if (data != null) {
                          final expenses = data['expenses'] as List? ?? [];
                          final key = _dateKey(picked);
                          for (final e in expenses) {
                            if (_dateKey(DateTime.parse(e['date'])) == key) {
                              _fuelCtrl.text =
                                  '${(e['fuelUsed'] ?? 0).toStringAsFixed(0)}';
                              _iceCtrl.text =
                                  '${(e['iceUsed'] ?? 0).toStringAsFixed(0)}';
                              _waterCtrl.text =
                                  '${(e['waterUsed'] ?? 0).toStringAsFixed(0)}';
                            }
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Today's usage entry ──────────────────────────────────────────
            _sectionLabel("─── TODAY'S USAGE ───"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInputRow('⛽', 'Fuel Used', 'Litres', _fuelCtrl),
                  const Divider(height: 20),
                  _buildInputRow('🧊', 'Ice Used', 'Kg', _iceCtrl),
                  const Divider(height: 20),
                  _buildInputRow('💧', 'Water Used', 'Litres', _waterCtrl),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : AppButton(
                    text: 'Save Expenses',
                    onPressed: _save,
                    backgroundColor: AppColors.primary,
                    leadingIcon: Icons.save_outlined,
                  ),
            const SizedBox(height: 24),

            // ── Previous days ────────────────────────────────────────────────
            _sectionLabel('─── PREVIOUS DAYS ───'),
            const SizedBox(height: 10),
            expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString(),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              data: (data) {
                final expenses = (data['expenses'] as List? ?? [])
                    .where((e) {
                      final d = DateTime.parse(e['date']);
                      return !_isSameDay(d, _selectedDate);
                    })
                    .toList()
                    .reversed
                    .toList();

                final totals = data['totals'] as Map? ?? {};

                return Column(
                  children: [
                    if (expenses.isEmpty)
                      _emptyCard('No previous records')
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.shadowMedium,
                                blurRadius: 6,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          children: [
                            _prevHeader(),
                            const Divider(height: 1),
                            ...expenses.asMap().entries.map((entry) {
                              final e = entry.value;
                              final isLast = entry.key == expenses.length - 1;
                              return Column(
                                children: [
                                  _prevRow(
                                    _fmtDate(DateTime.parse(e['date'])),
                                    '${(e['fuelUsed'] ?? 0).toStringAsFixed(0)}',
                                    '${(e['iceUsed'] ?? 0).toStringAsFixed(0)}',
                                    '${(e['waterUsed'] ?? 0).toStringAsFixed(0)}',
                                  ),
                                  if (!isLast) const Divider(height: 1),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    _sectionLabel('─── VOYAGE TOTAL ───'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryContainer),
                      ),
                      child: Column(
                        children: [
                          _totalRow('⛽ Total Fuel',
                              '${(totals['totalFuel'] ?? 0).toStringAsFixed(0)} Ltrs'),
                          const Divider(height: 12),
                          _totalRow('🧊 Total Ice',
                              '${(totals['totalIce'] ?? 0).toStringAsFixed(0)} Kg'),
                          const Divider(height: 12),
                          _totalRow('💧 Total Water',
                              '${(totals['totalWater'] ?? 0).toStringAsFixed(0)} Ltrs'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _sectionLabel(String text) => Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _emptyCard(String msg) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: Text(msg,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
        ),
      );

  Widget _buildInputRow(
      String emoji, String label, String unit, TextEditingController ctrl) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style:
                  AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: unit,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _prevHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text('Date',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.bold))),
            _hdrCell('Fuel'),
            _hdrCell('Ice'),
            _hdrCell('Water'),
          ],
        ),
      );

  Widget _hdrCell(String t) => SizedBox(
        width: 60,
        child: Text(t,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      );

  Widget _prevRow(String date, String fuel, String ice, String water) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
                child: Text(date, style: AppTextStyles.bodySmall)),
            SizedBox(
                width: 60,
                child: Text(fuel,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall)),
            SizedBox(
                width: 60,
                child: Text(ice,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall)),
            SizedBox(
                width: 60,
                child: Text(water,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall)),
          ],
        ),
      );

  Widget _totalRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      );
}
