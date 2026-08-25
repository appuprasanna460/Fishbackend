import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/haul_provider.dart';
import '../providers/catch_provider.dart';

/// A read-only summary screen shown for a completed haul.
/// Reuses [BoatOwnerHaulDashboard] logic but surfaced as a distinct route.
class BoatOwnerHaulSummary extends ConsumerStatefulWidget {
  final String haulId;

  const BoatOwnerHaulSummary({super.key, required this.haulId});

  @override
  ConsumerState<BoatOwnerHaulSummary> createState() => _BoatOwnerHaulSummaryState();
}

class _BoatOwnerHaulSummaryState extends ConsumerState<BoatOwnerHaulSummary> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catchProvider.notifier).fetchCatchesByHaul(widget.haulId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final haulState = ref.watch(haulProvider);
    final catchState = ref.watch(catchProvider);

    final haul = haulState.hauls.where((h) => h.id == widget.haulId).firstOrNull;

    if (haul == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Haul Summary')),
        body: const Center(child: Text('Haul data not found.')),
      );
    }

    final duration = haul.endedAt != null
        ? haul.endedAt!.difference(haul.startedAt)
        : Duration.zero;
    final durationStr = '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';

    final totalWeight = catchState.catchesForHaul.fold<double>(
      0.0,
      (sum, c) => sum + c.weight,
    );
    final totalBoxes = catchState.catchesForHaul.fold<int>(
      0,
      (sum, c) => sum + c.boxes,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Haul #${haul.haulNumber} Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUMMARY',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  _infoRow(Icons.location_on, 'Fishing Ground', haul.fishingGround),
                  _infoRow(Icons.play_circle_outline, 'Started At', DateFormat('MMM d, HH:mm').format(haul.startedAt)),
                  if (haul.endedAt != null)
                    _infoRow(Icons.stop_circle_outlined, 'Stopped At', DateFormat('MMM d, HH:mm').format(haul.endedAt!)),
                  _infoRow(Icons.timer, 'Duration', durationStr),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // Catch totals
            Row(
              children: [
                Expanded(
                  child: _statCard('Total Weight', '${totalWeight.toStringAsFixed(1)} kg', Icons.scale, AppColors.primary),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: _statCard('Total Boxes', '$totalBoxes', Icons.inventory_2, Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p24),

            // Catch detail list
            Text(
              'CATCH BREAKDOWN',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSizes.p8),

            if (catchState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (catchState.catchesForHaul.isEmpty)
              const Text('No catches recorded for this haul.', style: TextStyle(color: AppColors.textHint))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: catchState.catchesForHaul.length,
                itemBuilder: (context, index) {
                  final c = catchState.catchesForHaul[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.set_meal, color: AppColors.primary),
                    ),
                    title: Text(c.species, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${c.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${c.boxes} boxes • ${c.sharePercentage}% share', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
