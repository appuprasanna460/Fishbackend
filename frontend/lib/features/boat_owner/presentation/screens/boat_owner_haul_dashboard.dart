import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../providers/haul_provider.dart';
import '../providers/catch_provider.dart';
import '../providers/voyage_provider.dart';
import '../../domain/entities/haul_entity.dart';

class BoatOwnerHaulDashboard extends ConsumerStatefulWidget {
  final String haulId;

  const BoatOwnerHaulDashboard({super.key, required this.haulId});

  @override
  ConsumerState<BoatOwnerHaulDashboard> createState() => _BoatOwnerHaulDashboardState();
}

class _BoatOwnerHaulDashboardState extends ConsumerState<BoatOwnerHaulDashboard> {
  bool _isStopping = false;
  Timer? _gpsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catchProvider.notifier).fetchCatchesByHaul(widget.haulId);
      ref.read(catchProvider.notifier).checkPendingCatch(widget.haulId);
      _startGpsTracking();
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  void _startGpsTracking() {
    // Only start timer if this haul is currently active
    final haulState = ref.read(haulProvider);
    if (haulState.activeHaul?.id == widget.haulId || 
        haulState.hauls.any((h) => h.id == widget.haulId && h.status == 'ACTIVE')) {
      
      _gpsTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        try {
          // Check if the haul is still active before sending GPS update
          final currentState = ref.read(haulProvider);
          final currentHaul = currentState.activeHaul?.id == widget.haulId 
              ? currentState.activeHaul 
              : currentState.hauls.where((h) => h.id == widget.haulId).firstOrNull;
          
          // If haul is no longer ACTIVE, stop the timer
          if (currentHaul == null || currentHaul.status != 'ACTIVE') {
            timer.cancel();
            _gpsTimer = null;
            return;
          }
          
          // Fetch current location
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          
          // Send to backend
          await ref.read(haulProvider.notifier).updateGpsTrack(
            widget.haulId, 
            position.latitude, 
            position.longitude
          );
          
          // Refresh active haul data to get updated track and metrics
          final activeVoyageId = ref.read(haulProvider).activeHaul?.voyageId;
          if (activeVoyageId != null) {
            ref.read(haulProvider.notifier).fetchActiveHaul(activeVoyageId);
          }
        } catch (e) {
          // If the error is "Active haul not found", the haul has been stopped - cancel timer
          if (e.toString().contains('Active haul not found')) {
            timer.cancel();
            _gpsTimer = null;
          }
          // Otherwise fail silently in background
        }
      });
    }
  }

  Future<void> _stopHaul(String voyageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Haul'),
        content: const Text('Are you sure you want to stop this haul? You will no longer be able to record GPS tracks for it. However, you can still add pending catches.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Stop Haul'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isStopping = true);
      try {
        await ref.read(haulProvider.notifier).stopHaul(widget.haulId, voyageId);
        // Refresh the hauls list to get the updated STOPPED status
        await ref.read(haulProvider.notifier).fetchHauls(voyageId: voyageId);
        if (mounted) {
          AppErrorBanner.showSuccess(context, 'Haul stopped. Add a catch to complete it.');
          _gpsTimer?.cancel(); // Stop tracking
          // Note: Intentionally NOT calling context.pop() here so the user stays on the dashboard 
          // to review the stopped haul and add the required catch.
        }
      } catch (e) {
        if (mounted) AppErrorBanner.show(context, e.toString());
      } finally {
        if (mounted) setState(() => _isStopping = false);
      }
    }
  }

  Widget _buildMap(HaulEntity haul) {
    final startPoint = LatLng(haul.startLocation.latitude, haul.startLocation.longitude);
    final points = haul.gpsTrack.map((p) => LatLng(p.latitude, p.longitude)).toList();
    if (points.isEmpty) {
      points.add(startPoint);
    }
    
    final currentPoint = points.last;

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: currentPoint,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.harbourpro',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 4.0,
                color: Colors.blueAccent,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: startPoint,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, color: Colors.red, size: 30),
              ),
              if (points.length > 1)
                Marker(
                  point: currentPoint,
                  width: 40,
                  height: 40,
                  // Use green for active, grey for completed end point
                  child: Icon(Icons.my_location, color: haul.status == 'ACTIVE' ? Colors.green : Colors.grey.shade700, size: 30),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final haulState = ref.watch(haulProvider);
    final catchState = ref.watch(catchProvider);
    
    final haul = haulState.activeHaul?.id == widget.haulId 
        ? haulState.activeHaul 
        : haulState.hauls.where((h) => h.id == widget.haulId).firstOrNull;
        
    if (haul == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Haul Dashboard')),
        body: const Center(child: Text('Haul not found.')),
      );
    }

    final duration = DateTime.now().difference(haul.startedAt);
    final hours = haul.duration != null ? haul.duration! ~/ 60 : duration.inHours;
    final mins = haul.duration != null ? haul.duration! % 60 : duration.inMinutes.remainder(60);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Haul Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: haul.status == 'ACTIVE' 
                    ? Colors.blue.shade800 
                    : (haul.status == 'STOPPED' ? Colors.orange.shade800 : Colors.green.shade800),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            haul.status == 'ACTIVE' 
                                ? Icons.directions_boat 
                                : (haul.status == 'STOPPED' ? Icons.pause_circle : Icons.check_circle), 
                            color: Colors.white, 
                            size: 24
                          ),
                          const SizedBox(width: 8),
                          Text(
                            haul.status == 'ACTIVE' 
                                ? 'ACTIVE HAUL' 
                                : (haul.status == 'STOPPED' ? 'STOPPED - ADD CATCH' : 'COMPLETED HAUL'),
                            style: AppTextStyles.labelSmall.copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        'Haul #${haul.haulNumber.toString().padLeft(2, '0')}',
                        style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fishing Ground: ${haul.fishingGround}',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gear: ${haul.gearType.isEmpty ? 'N/A' : haul.gearType} | Net Length: ${haul.netLength}m',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                  if (haul.status == 'STOPPED') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Add a catch to complete this haul.',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // Live GPS Map
            Row(
              children: [
                const Icon(Icons.map, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  haul.status == 'ACTIVE' ? 'LIVE GPS MAP' : 'GPS TRACK HISTORY',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p12),
            _buildMap(haul),
            
            const SizedBox(height: AppSizes.p16),

            // Live Metrics
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetric('Duration', '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}', Icons.timer),
                  _buildMetric('Distance', '${haul.distance ?? 0.0} km', Icons.straighten),
                  _buildMetric('Avg Speed', '${haul.averageSpeed ?? 0.0} km/h', Icons.speed),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // Actions
            if (haul.status == 'ACTIVE') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(haulProvider.notifier).fetchActiveHaul(haul.voyageId);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Map'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.p12),
                  Expanded(
                    child: AppButton(
                      text: 'Stop Haul',
                      isLoading: _isStopping,
                      onPressed: () => _stopHaul(haul.voyageId),
                      backgroundColor: AppColors.error,
                      leadingIcon: Icons.stop,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p12),
            ],

            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Add Catch',
                onPressed: () => context.push('/owner/fishing/hauls/${haul.id}/catches/new'),
                backgroundColor: AppColors.primary,
                leadingIcon: Icons.add,
              ),
            ),
            const SizedBox(height: AppSizes.p32),

            // Recorded Catches
            Text(
              'RECORDED CATCHES',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSizes.p12),

            if (catchState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (catchState.catchesForHaul.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.p24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.set_meal_outlined, size: 48, color: AppColors.textHint),
                    SizedBox(height: 16),
                    Text('No catches recorded yet.', style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: catchState.catchesForHaul.length,
                itemBuilder: (context, index) {
                  final c = catchState.catchesForHaul[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSizes.p8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.set_meal, color: AppColors.primary),
                      ),
                      title: Text(c.species, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${c.weight} kg • ${c.boxes} boxes • ${c.sharePercentage}% share'),
                      trailing: haul.status == 'ACTIVE' 
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () async {
                               final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Catch'),
                                  content: const Text('Are you sure?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref.read(catchProvider.notifier).deleteCatch(c.id!, haul.id!);
                              }
                            },
                          )
                        : null,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
