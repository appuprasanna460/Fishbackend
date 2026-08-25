import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../providers/tracking_provider.dart';

class TrackingMapScreen extends ConsumerStatefulWidget {
  final String? boatId;
  const TrackingMapScreen({super.key, this.boatId});

  @override
  ConsumerState<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends ConsumerState<TrackingMapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.boatId != null) {
        ref.read(trackingProvider.notifier).loadHistory(widget.boatId!);
      } else {
        ref.read(trackingProvider.notifier).loadAll();
      }
    });
  }

  Color _getMarkerColor(String status) {
    return switch (status.toUpperCase()) {
      'ACTIVE' => AppColors.success,
      'STALE' => AppColors.warning,
      'INACTIVE' => AppColors.error,
      _ => AppColors.info,
    };
  }

  void _showBoatDetails(dynamic boat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radius24),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    boat.boatName,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p10,
                    vertical: AppSizes.p4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMarkerColor(boat.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    boat.status,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _getMarkerColor(boat.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Reg Number: ${boat.boatNumber}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric(
                  'Speed',
                  '${boat.speed?.toStringAsFixed(1) ?? "0.0"} kts',
                  Icons.speed,
                ),
                _metric(
                  'Heading',
                  '${boat.heading?.toStringAsFixed(0) ?? "0"}°',
                  Icons.explore_outlined,
                ),
                _metric(
                  'Lat/Lng',
                  '${boat.latitude.toStringAsFixed(4)}, ${boat.longitude.toStringAsFixed(4)}',
                  Icons.location_on_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingProvider);
    final history = state.history;

    final double defaultLat = 13.0827; // Chennai Area
    final double defaultLng = 80.2707;

    LatLng center = LatLng(defaultLat, defaultLng);
    List<Marker> markers = [];
    List<Polyline> polylines = [];

    if (widget.boatId != null && history != null && history.path.isNotEmpty) {
      final latest = history.path.first;
      center = LatLng(latest.latitude, latest.longitude);
      markers.add(
        Marker(
          point: center,
          width: 44,
          height: 44,
          child: const Icon(
            Icons.directions_boat,
            color: AppColors.primary,
            size: 40,
          ),
        ),
      );
      polylines.add(
        Polyline(
          points: history.path
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
          color: AppColors.info,
          strokeWidth: 4.0,
        ),
      );
    } else {
      // Multiple boats mode
      for (var boat in state.boatLocations) {
        final pos = LatLng(boat.latitude, boat.longitude);
        if (markers.isEmpty) {
          center = pos; // center on first boat
        }
        markers.add(
          Marker(
            point: pos,
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _showBoatDetails(boat),
              child: Icon(
                Icons.directions_boat,
                color: _getMarkerColor(boat.status),
                size: 36,
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.boatId != null ? 'Boat Route History' : 'GPS Boat Monitor',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.boatId != null) {
                ref.read(trackingProvider.notifier).loadHistory(widget.boatId!);
              } else {
                ref.read(trackingProvider.notifier).loadAll();
              }
            },
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: center, initialZoom: 11.0),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fishmarket.app',
            ),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
