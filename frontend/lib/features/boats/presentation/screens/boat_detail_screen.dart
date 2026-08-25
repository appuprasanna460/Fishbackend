import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_status_badge.dart';
import 'package:HarbourPro/features/boats/presentation/providers/boat_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';

class BoatDetailScreen extends ConsumerStatefulWidget {
  final String boatId;
  const BoatDetailScreen({super.key, required this.boatId});

  @override
  ConsumerState<BoatDetailScreen> createState() => _BoatDetailScreenState();
}

class _BoatDetailScreenState extends ConsumerState<BoatDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatProvider.notifier).loadById(widget.boatId);
      ref.read(ledgerProvider.notifier).loadBoatBalance(widget.boatId);
      ref.read(billingProvider.notifier).load(boatId: widget.boatId);
      ref.read(trackingProvider.notifier).loadHistory(widget.boatId);
    });
  }

  void _onDelete() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Boat Registration',
      message:
          'Are you sure you want to delete this boat? This will remove it from all active registries.',
    );

    if (confirmed == true) {
      final ok = await ref
          .read(boatProvider.notifier)
          .deleteBoat(widget.boatId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Boat deleted successfully')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boatProvider);
    final ledgerState = ref.watch(ledgerProvider);
    final billingState = ref.watch(billingProvider);
    final trackingState = ref.watch(trackingProvider);

    final boat = state.selected;

    if (state.isLoading || boat == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final balance = ledgerState.selectedBalance;
    final history = trackingState.history;
    final double defaultLat = 13.1256; // Kasimedu Port latitude
    final double defaultLng = 80.2974; // Kasimedu Port longitude

    LatLng boatPos = LatLng(defaultLat, defaultLng);
    if (history != null && history.path.isNotEmpty) {
      boatPos = LatLng(
        history.path.first.latitude,
        history.path.first.longitude,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(boat.boatName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/agent/boats/${boat.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _onDelete,
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Boat Main Card
              AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppSizes.radius16),
                      ),
                      child: const Icon(
                        Icons.directions_boat,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            boat.boatName,
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reg No: ${boat.boatNumber}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Owner: ${boat.ownerName}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // Ledger Balance Summary
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Ledger Summary',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Balance',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                balance != null
                                    ? '₹${balance.balance.toStringAsFixed(2)}'
                                    : '₹0.00',
                                style: AppTextStyles.headlineLarge.copyWith(
                                  color: balance != null && balance.balance >= 0
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/agent/ledger/boat/${boat.id}'),
                          icon: const Icon(Icons.account_balance_outlined),
                          label: const Text('View Ledger'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // Tracking / Mini Map
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
Text(
                       'GPS Tracking (Last Seen)',
                       style: AppTextStyles.titleMedium.copyWith(
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     const SizedBox(height: AppSizes.p12),
                     SizedBox(
                      height: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: boatPos,
                            initialZoom: 13.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.fishmarket.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: boatPos,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: AppColors.error,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          history != null && history.path.isNotEmpty
                              ? 'Last update: ${history.path.first.recordedAt.toLocal()}'
                              : 'No location signal recorded',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.push('/agent/tracking/submit/${boat.id}'),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Submit GPS'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // Recent Bills List
              Text(
                'Recent Billing Trips',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              billingState.bills.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSizes.p24),
                        child: Text(
                          'No recent billing recorded for this boat.',
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: billingState.bills.take(5).length,
                      itemBuilder: (_, i) {
                        final bill = billingState.bills[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.p8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius12,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              bill.billNumber,
                              style: AppTextStyles.titleMedium,
                            ),
                            subtitle: Text(
                              'Grand Total: ₹${bill.totalAmount.toStringAsFixed(2)}',
                            ),
                            trailing: AppStatusBadge.fromString(bill.status),
                            onTap: () =>
                                context.push('/agent/bills/${bill.id}'),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
