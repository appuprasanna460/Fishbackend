import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/crew_provider.dart';
import '../providers/voyage_provider.dart';

// Local provider for catch summary data
final _catchSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, voyageId) async {
  final api = ref.watch(boatOwnerApiProvider);
  return api.getCatchSummaryByVoyage(voyageId);
});

class BoatOwnerVoyageCatchSummary extends ConsumerWidget {
  final String voyageId;
  const BoatOwnerVoyageCatchSummary({super.key, required this.voyageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voyage = ref.watch(voyageProvider).currentVoyage;
    final summaryAsync = ref.watch(_catchSummaryProvider(voyageId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/owner/voyages/$voyageId'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catch Summary',
                style: AppTextStyles.titleSmall.copyWith(color: Colors.white)),
            if (voyage != null)
              Text('${voyage.boatName ?? ''} | ${voyage.boatNumber ?? ''}',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_catchSummaryProvider(voyageId)),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(err.toString(),
                    style:
                        AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(_catchSummaryProvider(voyageId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final totalWeight = (data['totalWeight'] ?? 0).toDouble();
          final bySpecies = data['bySpecies'] as List? ?? [];
          final byHaul = data['byHaul'] as List? ?? [];

          // Combine haul and species data
          final combinedData = _combineHaulAndSpecies(byHaul, bySpecies);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Total catch header ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.oceanGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('📊 TOTAL CATCH',
                          style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text(
                        '${totalWeight.toStringAsFixed(0)} Kg',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${byHaul.length} Hauls • ${bySpecies.length} Species',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Combined Haul-wise Fish List ──────────────────────────
                _sectionLabel('🐟 CATCH BY HAUL & SPECIES'),
                const SizedBox(height: 10),
                if (combinedData.isEmpty)
                  _emptyCard('No catch recorded yet')
                else
                  ...combinedData.map((haul) => _buildHaulCard(haul)),
                const SizedBox(height: 20),

                // ── Species Summary Table ──────────────────────────────────
                _sectionLabel('📊 SPECIES SUMMARY'),
                const SizedBox(height: 10),
                bySpecies.isEmpty
                    ? _emptyCard('No species data available')
                    : _buildSpeciesSummary(bySpecies, totalWeight),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Helper method to combine haul and species data ──────────────────
  List<Map<String, dynamic>> _combineHaulAndSpecies(
      List byHaul, List bySpecies) {
    if (byHaul.isEmpty) return [];

    // Create a map for quick species lookup by name
    final speciesMap = <String, Map<String, dynamic>>{};
    for (final species in bySpecies) {
      speciesMap[species['species'] ?? ''] = species;
    }

    // Combine haul data with species breakdown
    return byHaul.map((haul) {
      final haulNumber = haul['haulNumber'] ?? 0;
      final haulWeight = (haul['weight'] ?? 0).toDouble();
      final haulBoxes = haul['boxes'] ?? 0;
      final haulShare = haul['sharePercent'] ?? 0;

      // Get species caught in this haul (if available from API)
      // For now, we'll show all species with their weights
      final speciesInHaul = bySpecies.map((species) {
        return {
          'name': species['species'] ?? 'Unknown',
          'weight': (species['weight'] ?? 0).toDouble(),
          'boxes': species['boxes'] ?? 0,
          'sharePercent': species['sharePercent'] ?? 0,
        };
      }).toList();

      return {
        'haulNumber': haulNumber,
        'weight': haulWeight,
        'boxes': haulBoxes,
        'sharePercent': haulShare,
        'species': speciesInHaul,
      };
    }).toList();
  }

  // ─── Build Haul Card with Species List ────────────────────────────────
  Widget _buildHaulCard(Map<String, dynamic> haul) {
    final species = haul['species'] as List? ?? [];
    final haulNumber = haul['haulNumber'] ?? 0;
    final weight = (haul['weight'] ?? 0).toDouble();
    final boxes = haul['boxes'] ?? 0;
    final share = haul['sharePercent'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Haul Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'HAUL #$haulNumber',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildChip('${weight.toStringAsFixed(0)} Kg', AppColors.primary),
                const SizedBox(width: 8),
                _buildChip('$boxes Boxes', AppColors.accent),
                const SizedBox(width: 8),
                _buildChip('${share.toStringAsFixed(0)}%', AppColors.success),
              ],
            ),
          ),

          // ── Species List ────────────────────────────────────────────────
          if (species.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No species recorded for this haul'),
            )
          else
            Column(
              children: [
                // Species header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text('Species',
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: Text('Kg',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Boxes',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Share',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ...species.asMap().entries.map((entry) {
                  final s = entry.value;
                  final isLast = entry.key == species.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                s['name'] ?? 'Unknown',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${(s['weight'] ?? 0).toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${s['boxes'] ?? 0}',
                                textAlign: TextAlign.right,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${(s['sharePercent'] ?? 0).toStringAsFixed(0)}%',
                                textAlign: TextAlign.right,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Build Species Summary Table ──────────────────────────────────────
  Widget _buildSpeciesSummary(List species, double totalWeight) {
    return Container(
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Species',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text('Kg',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Boxes',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Share',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...species.asMap().entries.map((entry) {
            final s = entry.value;
            final isLast = entry.key == species.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          s['species'] ?? 'Unknown',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${(s['weight'] ?? 0).toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${s['boxes'] ?? 0}',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${(s['sharePercent'] ?? 0).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('TOTAL',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                Expanded(
                  child: Text(
                    totalWeight.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${species.fold<int>(0, (s, e) => s + ((e['boxes'] ?? 0) as int))}',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '100%',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper Widgets ────────────────────────────────────────────────────
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
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textHint)),
        ),
      );

  Widget _buildChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}