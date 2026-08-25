import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/gps_track_provider.dart';
import '../../domain/entities/haul_entity.dart';

class GpsTrackHistoryScreen extends ConsumerStatefulWidget {
  final String voyageId;

  const GpsTrackHistoryScreen({super.key, required this.voyageId});

  @override
  ConsumerState<GpsTrackHistoryScreen> createState() => _GpsTrackHistoryScreenState();
}

class _GpsTrackHistoryScreenState extends ConsumerState<GpsTrackHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gpsTrackProvider.notifier).fetchTracksByVoyage(widget.voyageId);
      ref.read(gpsTrackProvider.notifier).fetchTrackSummary(widget.voyageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackState = ref.watch(gpsTrackProvider);
    final summary = trackState.trackSummary;
    final voyageTracks = trackState.voyageTracks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('GPS Track History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: trackState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : voyageTracks.isEmpty
              ? const AppEmptyState(
                  title: 'No GPS Tracks Found',
                  subtitle: 'There is no GPS track history for this voyage yet.',
                  icon: Icons.map,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      if (summary != null)
                        Container(
                          padding: const EdgeInsets.all(AppSizes.p16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryItem(
                                'Total Distance',
                                '${(summary['totalDistance'] ?? 0.0).toStringAsFixed(2)} km',
                                Icons.straighten,
                              ),
                              _buildSummaryItem(
                                'Avg Speed',
                                '${(summary['averageSpeed'] ?? 0.0).toStringAsFixed(1)} knots',
                                Icons.speed,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSizes.p24),

                      Text(
                        'HAUL TRACKS',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSizes.p8),

                      // List of Hauls with their tracks
                      ...voyageTracks.map((haulData) {
                        final haulNumber = haulData['haulNumber'] ?? 0;
                        final fishingGround = haulData['fishingGround'] ?? 'Unknown';
                        final tracks = haulData['tracks'] as List<dynamic>? ?? [];

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.p12),
                          child: ExpansionTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(Icons.my_location, color: AppColors.primary),
                            ),
                            title: Text('Haul #$haulNumber - $fishingGround', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${tracks.length} track points recorded'),
                            children: [
                              if (tracks.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No track points for this haul.', style: TextStyle(color: AppColors.textHint)),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: tracks.length,
                                  itemBuilder: (context, index) {
                                    final point = GpsPoint.fromJson(tracks[index]);
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.location_on, size: 16, color: Colors.black54),
                                      title: Text('Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}'),
                                      trailing: Text(DateFormat('HH:mm:ss').format(point.timestamp)),
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
