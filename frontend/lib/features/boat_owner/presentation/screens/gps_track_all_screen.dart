// lib/features/boat_owner/presentation/screens/gps_track_all_screen.dart
//
// GPS Track History — full-featured screen.
// Replaces the old text-list screen with:
//   • Filter tabs (All Voyages / Today / This Week / This Month)
//   • Voyage cards with mini flutter_map route previews
//   • "View on Map" / card-tap navigation to full-screen voyage detail

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/gps_track_provider.dart';

// ─── Filter tab definition ────────────────────────────────────────────────────

class _FilterTab {
  final String label;
  final String period;
  const _FilterTab(this.label, this.period);
}

const _filterTabs = [
  _FilterTab('All Voyages', 'all'),
  _FilterTab('Today', 'today'),
  _FilterTab('This Week', 'week'),
  _FilterTab('This Month', 'month'),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class GpsTrackAllScreen extends ConsumerStatefulWidget {
  const GpsTrackAllScreen({super.key});

  @override
  ConsumerState<GpsTrackAllScreen> createState() => _GpsTrackAllScreenState();
}

class _GpsTrackAllScreenState extends ConsumerState<GpsTrackAllScreen> {
  int _selectedTab = 0;
  String? _selectedVoyageId; // for "View on Map" button

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gpsTrackProvider.notifier).fetchTrackHistory(period: 'all');
    });
  }

  void _selectTab(int index) {
    if (index == _selectedTab) return;
    setState(() {
      _selectedTab = index;
      _selectedVoyageId = null;
    });
    ref.read(gpsTrackProvider.notifier).fetchTrackHistory(
          period: _filterTabs[index].period,
        );
  }

  void _onViewOnMap() {
    final state = ref.read(gpsTrackProvider);
    final voyageId = _selectedVoyageId ??
        (state.trackHistory.isNotEmpty
            ? state.trackHistory.first['voyageId'] as String?
            : null);
    if (voyageId == null) return;
    context.push('/owner/gps-tracks/voyage/$voyageId');
  }

  @override
  Widget build(BuildContext context) {
    final trackState = ref.watch(gpsTrackProvider);
    final history = trackState.trackHistory;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter tabs
          _buildFilterTabs(),
          const Divider(height: 1, color: AppColors.border),

          // Content
          Expanded(
            child: _buildBody(trackState, history),
          ),

          // "View on Map" button pinned at bottom
          if (!trackState.isLoadingHistory && history.isNotEmpty)
            _buildViewOnMapButton(),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'GPS Track History',
        style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
          tooltip: 'Filter',
          onPressed: () {/* future: advanced filter sheet */},
        ),
      ],
    );
  }

  // ── Filter tabs ───────────────────────────────────────────────────────────

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      height: 44,
      child: Row(
        children: List.generate(_filterTabs.length, (i) {
          final selected = i == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectTab(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppColors.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _filterTabs[i].label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(GpsTrackState state, List<dynamic> history) {
    if (state.isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.historyError != null) {
      return _buildErrorState(state.historyError!);
    }

    if (history.isEmpty) {
      return const AppEmptyState(
        title: 'No GPS Tracks Found',
        subtitle:
            'No voyage tracks were recorded for the selected period.\nStart a haul to begin tracking.',
        icon: Icons.map_outlined,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(gpsTrackProvider.notifier).fetchTrackHistory(
            period: _filterTabs[_selectedTab].period,
          ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.p16, AppSizes.p16, AppSizes.p16, AppSizes.p80),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.p12),
        itemBuilder: (context, index) {
          final voyage = history[index] as Map<String, dynamic>;
          final isSelected = _selectedVoyageId == (voyage['voyageId'] as String?);
          return _VoyageCard(
            voyage: voyage,
            isSelected: isSelected,
            onTap: () {
              final voyageId = voyage['voyageId'] as String?;
              if (voyageId == null) return;
              setState(() => _selectedVoyageId = voyageId);
              context.push('/owner/gps-tracks/voyage/$voyageId');
            },
            onSelect: () {
              final voyageId = voyage['voyageId'] as String?;
              if (voyageId == null) return;
              setState(() => _selectedVoyageId = voyageId);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: AppSizes.p16),
            Text(
              'Failed to load GPS history',
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p8),
            Text(
              error,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSizes.p24),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(gpsTrackProvider.notifier)
                  .fetchTrackHistory(period: _filterTabs[_selectedTab].period),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p24, vertical: AppSizes.p12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── "View on Map" button ──────────────────────────────────────────────────

  Widget _buildViewOnMapButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
          AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p16),
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeight,
        child: ElevatedButton.icon(
          onPressed: _onViewOnMap,
          icon: const Icon(Icons.map_rounded, size: AppSizes.iconLg),
          label: const Text('View on Map'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: AppTextStyles.button,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius12)),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}

// ─── Voyage card ──────────────────────────────────────────────────────────────

class _VoyageCard extends StatelessWidget {
  final Map<String, dynamic> voyage;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  const _VoyageCard({
    required this.voyage,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final haulNumber = voyage['haulNumber'] ?? voyage['hauls']?[0]?['haulNumber'];
    final haulLabel = haulNumber != null ? 'HD-${haulNumber.toString().padLeft(2, '0')}' : 'HD-??';

    final rawDate = voyage['date'] ?? voyage['startTime'];
    DateTime? date;
    if (rawDate != null) {
      try {
        date = DateTime.parse(rawDate.toString()).toLocal();
      } catch (_) {}
    }

    final distanceRaw = voyage['distanceNm'] ?? voyage['distance'] ?? 0.0;
    final distanceNm = (distanceRaw as num).toDouble();

    final durationMin = (voyage['duration'] as num?)?.toInt() ?? 0;
    final durationStr = _formatDuration(durationMin);

    final status = (voyage['status'] as String? ?? '').toLowerCase();
    final boatName = voyage['boatName'] as String? ?? '';

    // Track preview points
    final preview = voyage['trackPreview'] as List<dynamic>? ?? [];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mini map preview
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radius16),
                bottomLeft: Radius.circular(AppSizes.radius16),
              ),
              child: _MiniMap(previewPoints: preview),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p14, vertical: AppSizes.p12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Haul ID + status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          haulLabel,
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        _StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Boat name
                    if (boatName.isNotEmpty)
                      Text(
                        boatName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    if (date != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('d MMM yyyy').format(date),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.straighten_outlined,
                          label:
                              '${distanceNm.toStringAsFixed(1)} NM',
                        ),
                        const SizedBox(width: AppSizes.p8),
                        _StatChip(
                          icon: Icons.timer_outlined,
                          label: durationStr,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            const Padding(
              padding: EdgeInsets.only(right: AppSizes.p8),
              child: Icon(Icons.chevron_right, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

// ─── Mini flutter_map preview ─────────────────────────────────────────────────

class _MiniMap extends StatelessWidget {
  final List<dynamic> previewPoints;

  const _MiniMap({required this.previewPoints});

  @override
  Widget build(BuildContext context) {
    final hasPoints = previewPoints.length >= 2;

    if (!hasPoints) {
      return Container(
        width: 86,
        height: 90,
        color: AppColors.primarySurface,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gps_not_fixed, color: AppColors.primary, size: 26),
            SizedBox(height: 4),
            Text(
              'No GPS',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Parse all points
    final latLngs = previewPoints.map<LatLng>((p) {
      final lat = (p['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (p['longitude'] as num?)?.toDouble() ?? 0.0;
      return LatLng(lat, lng);
    }).toList();

    // Bounding box
    double minLat = latLngs.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = latLngs.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = latLngs.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = latLngs.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final center = LatLng(centerLat, centerLng);

    return SizedBox(
      width: 86,
      height: 90,
      child: IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 10,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.harbourpro.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: latLngs,
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                // Start
                Marker(
                  point: latLngs.first,
                  width: 10,
                  height: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
                // End
                Marker(
                  point: latLngs.last,
                  width: 10,
                  height: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case 'completed':
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = 'Completed';
        break;
      case 'stopped':
        bg = AppColors.infoLight;
        fg = AppColors.info;
        label = 'Stopped';
        break;
      case 'active':
        bg = AppColors.accentSurface;
        fg = AppColors.accent;
        label = 'Active';
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        label = status.isEmpty ? 'Unknown' : status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radius4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}