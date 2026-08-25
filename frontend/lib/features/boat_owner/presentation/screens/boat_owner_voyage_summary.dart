import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../providers/crew_provider.dart';
import '../providers/haul_provider.dart';
import '../providers/voyage_provider.dart';

// Inline providers for summary data
final _summaryExpensesProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.watch(boatOwnerApiProvider).getVoyageExpenses(id);
});

final _summaryCatchProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.watch(boatOwnerApiProvider).getCatchSummaryByVoyage(id);
});

class BoatOwnerVoyageSummary extends ConsumerStatefulWidget {
  final String voyageId;
  const BoatOwnerVoyageSummary({super.key, required this.voyageId});

  @override
  ConsumerState<BoatOwnerVoyageSummary> createState() =>
      _BoatOwnerVoyageSummaryState();
}

class _BoatOwnerVoyageSummaryState extends ConsumerState<BoatOwnerVoyageSummary> {
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voyageProvider.notifier).loadVoyageById(widget.voyageId);
      ref.read(haulProvider.notifier).fetchHauls(voyageId: widget.voyageId);
    });
  }

  Future<void> _updateStatus(String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${_capitalise(status)} Voyage'),
        content: Text('Are you sure you want to change the voyage status to $status?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  status == 'CANCELLED' ? AppColors.error : AppColors.primary,
            ),
            child: Text(status),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isTransitioning = true);
      final success = await ref
          .read(voyageProvider.notifier)
          .updateVoyageStatus(widget.voyageId, status);
      setState(() => _isTransitioning = false);

      if (mounted) {
        if (success) {
          AppErrorBanner.showSuccess(context, 'Voyage marked as $status');
          ref.read(voyageProvider.notifier).loadVoyageById(widget.voyageId);
        } else {
          AppErrorBanner.show(
              context,
              ref.read(voyageProvider).error ??
                  'Failed to update voyage status');
        }
      }
    }
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  String _fmtDate(DateTime dt) =>
      DateFormat('dd-MMM-yyyy, hh:mm a').format(dt);

  String _fmtDuration(DateTime? from, DateTime? to) {
    if (from == null || to == null) return 'N/A';
    final diff = to.difference(from);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    return '$days Days $hours Hrs $mins Mins';
  }

  @override
  Widget build(BuildContext context) {
    final voyageState = ref.watch(voyageProvider);
    final haulState = ref.watch(haulProvider);
    final expAsync = ref.watch(_summaryExpensesProvider(widget.voyageId));
    final catchAsync = ref.watch(_summaryCatchProvider(widget.voyageId));

    final voyage = voyageState.currentVoyage;

    if (voyageState.isLoading && voyage == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (voyage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Voyage Summary')),
        body: const Center(child: Text('Voyage not found.')),
      );
    }

    // Derived values
    final completedHauls = haulState.hauls.where((h) => h.status == 'COMPLETED').length;
    const kmToNm = 0.539957;
    final totalDistNm = haulState.hauls
        .fold<double>(0, (s, h) => s + ((h.distance ?? 0) * kmToNm));

    final expTotals = (expAsync.valueOrNull?['totals'] as Map?) ?? {};
    final totalFuel = (expTotals['totalFuel'] ?? 0).toDouble();
    final totalIce = (expTotals['totalIce'] ?? 0).toDouble();
    final totalWater = (expTotals['totalWater'] ?? 0).toDouble();

    final totalCatchKg = (catchAsync.valueOrNull?['totalWeight'] ?? 0).toDouble();

    // Crude cost estimates (can be replaced with real prices later)
    const fuelPricePerL = 8.0;
    const icePricePerKg = 8.0;
    const waterPricePerL = 3.0;
    final fuelCost = totalFuel * fuelPricePerL;
    final iceCost = totalIce * icePricePerKg;
    final waterCost = totalWater * waterPricePerL;
    final totalExpenses = fuelCost + iceCost + waterCost;

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
            Text('Voyage Summary',
                style: AppTextStyles.titleSmall.copyWith(color: Colors.white)),
            Text('${voyage.boatName ?? ''} | ${voyage.boatNumber ?? ''}',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Voyage Overview ────────────────────────────────────────────
            _sectionLabel('─── VOYAGE OVERVIEW ───'),
            const SizedBox(height: 10),
            _infoCard([
              _infoRow('Voyage ID', voyage.id?.substring(0, 8).toUpperCase() ?? 'N/A'),
              _divider(),
              _infoRow('Status', voyage.status, valueColor: _statusColor(voyage.status)),
              _divider(),
              _infoRow('Departure',
                  '${DateFormat('dd-MMM-yyyy').format(voyage.departureDate)} ${voyage.departureTime}'),
              _divider(),
              _infoRow('Return',
                  voyage.completedAt != null ? _fmtDate(voyage.completedAt!) : '—'),
              _divider(),
              _infoRow(
                  'Duration',
                  voyage.startedAt != null
                      ? _fmtDuration(
                          voyage.startedAt,
                          voyage.completedAt ?? DateTime.now())
                      : '—'),
              _divider(),
              _infoRow('Total Hauls', '$completedHauls'),
              _divider(),
              _infoRow('Total Catch', '${totalCatchKg.toStringAsFixed(0)} Kg'),
              _divider(),
              _infoRow('Distance', '${totalDistNm.toStringAsFixed(1)} NM'),
            ]),
            const SizedBox(height: 20),

            // ── Crew Details ───────────────────────────────────────────────
            _sectionLabel('─── CREW DETAILS ───'),
            const SizedBox(height: 10),
            _infoCard([
              _infoRow('Captain',
                  '${voyage.captainName ?? 'N/A'}${voyage.captainPhone != null ? " (${voyage.captainPhone})" : ""}'),
              _divider(),
              _infoRow('Crew Members', '${voyage.crewMembers.length}'),
              if (voyage.crewDetails != null && voyage.crewDetails!.isNotEmpty) ...[
                _divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: voyage.crewDetails!.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${m['name'] ?? ''} (${m['phone'] ?? ''})',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary)),
                    )).toList(),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 20),

            // ── Supplies Usage ─────────────────────────────────────────────
            _sectionLabel('─── SUPPLIES USAGE ───'),
            const SizedBox(height: 10),
            _infoCard([
              _supplyRow('Fuel', totalFuel, voyage.supplies.fuelRequired, 'Ltrs'),
              _divider(),
              _supplyRow('Ice', totalIce, voyage.supplies.iceRequired, 'Kg'),
              _divider(),
              _supplyRow('Water', totalWater, voyage.supplies.water, 'Ltrs'),
            ]),
            const SizedBox(height: 20),

            // ── Financial Summary ──────────────────────────────────────────
            
            const SizedBox(height: 24),

            // ── Status action buttons ──────────────────────────────────────
            if (!_isTransitioning) ...[
              if (voyage.status == 'PLANNED') ...[
                AppButton(
                  text: 'Start Voyage',
                  onPressed: () => _updateStatus('ACTIVE'),
                  backgroundColor: AppColors.success,
                  leadingIcon: Icons.play_arrow,
                ),
                const SizedBox(height: 12),
                _cancelBtn(),
              ] else if (voyage.status == 'ACTIVE') ...[
                AppButton(
                  text: 'Complete Voyage',
                  onPressed: () => _updateStatus('COMPLETED'),
                  backgroundColor: AppColors.primary,
                  leadingIcon: Icons.check,
                ),
                const SizedBox(height: 12),
                _cancelBtn(),
              ],
            ] else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(double v) => NumberFormat('#,##0.##').format(v);

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'COMPLETED':
        return AppColors.primary;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _infoCard(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _divider() => const Divider(height: 14);

  Widget _infoRow(String label, String value,
      {Color? valueColor, bool valueBold = false}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary)),
          ),
          const Text(':  '),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight:
                    valueBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  Widget _supplyRow(String label, double used, double required, String unit) =>
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                Text(
                  '${used.toStringAsFixed(0)} / ${required.toStringAsFixed(0)} $unit',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Mini progress bar
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: required > 0 ? (used / required).clamp(0.0, 1.0) : 0,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ),
        ],
      );

  Widget _cancelBtn() => OutlinedButton(
        onPressed: () => _updateStatus('CANCELLED'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, size: 20),
            SizedBox(width: 8),
            Text('Cancel Voyage'),
          ],
        ),
      );
}
