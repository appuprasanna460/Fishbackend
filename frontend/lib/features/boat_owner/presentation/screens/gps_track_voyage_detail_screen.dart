// lib/features/boat_owner/presentation/screens/gps_track_voyage_detail_screen.dart
//
// Full-screen GPS route map for a single voyage.
// Draws a polyline from the complete stored GPS track, shows start/end markers,
// fits the camera to the route, and displays voyage statistics in a bottom panel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/gps_track_provider.dart';

class GpsTrackVoyageDetailScreen extends ConsumerStatefulWidget {
  final String voyageId;

  const GpsTrackVoyageDetailScreen({super.key, required this.voyageId});

  @override
  ConsumerState<GpsTrackVoyageDetailScreen> createState() =>
      _GpsTrackVoyageDetailScreenState();
}

class _GpsTrackVoyageDetailScreenState
    extends ConsumerState<GpsTrackVoyageDetailScreen> {
  late final MapController _mapController;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(gpsTrackProvider.notifier)
          .fetchVoyageDetail(widget.voyageId);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitBounds(List<LatLng> points) {
    if (!_mapReady || points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 13);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gpsTrackProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Full-screen map ────────────────────────────────────────────────
          _buildMap(state),

          // ── Top gradient + AppBar ──────────────────────────────────────────
          _buildTopBar(context, state),

          // ── Loading overlay ────────────────────────────────────────────────
          if (state.isLoadingDetail)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x80FFFFFF),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),

          // ── Bottom info panel ──────────────────────────────────────────────
          if (!state.isLoadingDetail)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: state.detailError != null
                  ? _buildErrorPanel(state.detailError!)
                  : state.voyageDetail != null
                      ? _buildInfoPanel(state.voyageDetail!)
                      : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  // ── Map ────────────────────────────────────────────────────────────────────

  Widget _buildMap(GpsTrackState state) {
    final detail = state.voyageDetail;
    final track = detail?['track'] as List<dynamic>? ?? [];

    final latLngs = track.map<LatLng>((p) {
      final lat = (p['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (p['longitude'] as num?)?.toDouble() ?? 0.0;
      return LatLng(lat, lng);
    }).toList();

    final hasTrack = latLngs.length >= 2;

    // Fit bounds once when data arrives
    if (hasTrack && !_mapReady) {
      // Will fit after map is ready via onMapReady callback
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: hasTrack
            ? latLngs[latLngs.length ~/ 2]
            : const LatLng(10.0, 80.0),
        initialZoom: 8,
        onMapReady: () {
          _mapReady = true;
          if (hasTrack) {
            Future.delayed(const Duration(milliseconds: 300), () {
              _fitBounds(latLngs);
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.harbourpro.app',
        ),

        if (hasTrack) ...[
          // Route shadow for depth
          PolylineLayer(
            polylines: [
              Polyline(
                points: latLngs,
                color: AppColors.primary.withOpacity(0.25),
                strokeWidth: 7,
              ),
            ],
          ),
          // Main route line
          PolylineLayer(
            polylines: [
              Polyline(
                points: latLngs,
                color: AppColors.primary,
                strokeWidth: 3.5,
              ),
            ],
          ),
          // Start / End markers
          MarkerLayer(
            markers: [
              // Start marker (green)
              Marker(
                point: latLngs.first,
                width: 36,
                height: 36,
                child: _RouteMarker(
                  color: AppColors.success,
                  icon: Icons.play_arrow_rounded,
                  label: 'Start',
                ),
              ),
              // End marker (red)
              Marker(
                point: latLngs.last,
                width: 36,
                height: 36,
                child: _RouteMarker(
                  color: AppColors.error,
                  icon: Icons.flag_rounded,
                  label: 'End',
                ),
              ),
            ],
          ),
        ],

        if (!hasTrack && !state.isLoadingDetail)
          MarkerLayer(
            markers: [
              Marker(
                point: const LatLng(10.0, 80.0),
                width: 56,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gps_off, color: AppColors.textHint, size: 20),
                      Text(
                        'No GPS',
                        style: TextStyle(fontSize: 8, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, GpsTrackState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.55),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              const SizedBox(width: AppSizes.p8),
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Text(
                  'GPS Route Map',
                  style: AppTextStyles.h4.copyWith(
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        color: Colors.black45,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              // Re-centre button
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                child: IconButton(
                  icon:
                      const Icon(Icons.center_focus_strong, color: Colors.white),
                  tooltip: 'Fit route',
                  onPressed: () {
                    final detail = state.voyageDetail;
                    final track = detail?['track'] as List<dynamic>? ?? [];
                    if (track.length < 2) return;
                    final points = track.map<LatLng>((p) => LatLng(
                          (p['latitude'] as num?)?.toDouble() ?? 0.0,
                          (p['longitude'] as num?)?.toDouble() ?? 0.0,
                        )).toList();
                    _fitBounds(points);
                  },
                ),
              ),
              const SizedBox(width: AppSizes.p8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info panel ─────────────────────────────────────────────────────────────

  Widget _buildInfoPanel(Map<String, dynamic> detail) {
    final haulsList = detail['hauls'] as List<dynamic>? ?? [];
    final haulNum = haulsList.isNotEmpty
        ? haulsList.first['haulNumber']
        : detail['haulNumber'];
    final haulLabel =
        haulNum != null ? 'HD-${haulNum.toString().padLeft(2, '0')}' : 'Voyage';

    final rawDate = detail['date'] ?? detail['startTime'];
    DateTime? date;
    if (rawDate != null) {
      try {
        date = DateTime.parse(rawDate.toString()).toLocal();
      } catch (_) {}
    }

    final rawStart = detail['startTime'];
    DateTime? startTime;
    if (rawStart != null) {
      try {
        startTime = DateTime.parse(rawStart.toString()).toLocal();
      } catch (_) {}
    }

    final rawEnd = detail['endTime'];
    DateTime? endTime;
    if (rawEnd != null) {
      try {
        endTime = DateTime.parse(rawEnd.toString()).toLocal();
      } catch (_) {}
    }

    final durationMin = (detail['duration'] as num?)?.toInt() ?? 0;
    final distanceNm = ((detail['distanceNm'] ?? detail['distance'] ?? 0.0) as num).toDouble();
    final status = (detail['status'] as String? ?? '').toLowerCase();
    final boatName = detail['boatName'] as String? ?? '';

    final trackLength = (detail['track'] as List<dynamic>? ?? []).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radius8),
                      ),
                      child: Text(
                        haulLabel,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p10),
                    if (boatName.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              boatName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (date != null)
                              Text(
                                DateFormat('d MMM yyyy').format(date),
                                style: AppTextStyles.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    _buildStatusPill(status),
                  ],
                ),
                const SizedBox(height: AppSizes.p16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSizes.p12),

                // Stats grid
                Row(
                  children: [
                    _buildStatItem(
                      label: 'Distance',
                      value: '${distanceNm.toStringAsFixed(1)} NM',
                      icon: Icons.straighten_outlined,
                    ),
                    _buildStatItem(
                      label: 'Duration',
                      value: _formatDuration(durationMin),
                      icon: Icons.timer_outlined,
                    ),
                    _buildStatItem(
                      label: 'GPS Points',
                      value: trackLength.toString(),
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),

                if (startTime != null || endTime != null) ...[
                  const SizedBox(height: AppSizes.p12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSizes.p10),
                  Row(
                    children: [
                      if (startTime != null)
                        Expanded(
                          child: _buildTimeItem(
                            label: 'Start Time',
                            value: DateFormat('HH:mm').format(startTime),
                            icon: Icons.play_arrow_rounded,
                            color: AppColors.success,
                          ),
                        ),
                      if (endTime != null)
                        Expanded(
                          child: _buildTimeItem(
                            label: 'End Time',
                            value: DateFormat('HH:mm').format(endTime),
                            icon: Icons.flag_rounded,
                            color: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ],

                // Haul count
                if (haulsList.length > 1) ...[
                  const SizedBox(height: AppSizes.p10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSizes.radius8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_outlined,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${haulsList.length} hauls combined',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: AppSizes.p8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
            Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  // ── Error panel ────────────────────────────────────────────────────────────

  Widget _buildErrorPanel(String error) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.p16),
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: AppSizes.p8),
          Text(
            'Failed to load voyage track',
            style:
                AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(error,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.p12),
          ElevatedButton.icon(
            onPressed: () => ref
                .read(gpsTrackProvider.notifier)
                .fetchVoyageDetail(widget.voyageId),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius8)),
            ),
          ),
        ],
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

// ─── Route marker widget ──────────────────────────────────────────────────────

class _RouteMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _RouteMarker({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}
