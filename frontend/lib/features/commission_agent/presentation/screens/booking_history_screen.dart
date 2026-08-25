import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_fish_market_nav_bar.dart';
import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../boats/domain/entities/boat_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatProvider.notifier).load();
      ref.read(billingProvider.notifier).load();
    });
  }

  String _getRoute(int idx) {
    switch (idx) {
      case 0:
        return '/agent/dashboard';
      case 1:
        return '/agent/boats';
      case 2:
        return '/agent/bills/new';
      case 3:
        return '/agent/tracking';
      case 4:
        return '/agent/profile';
      default:
        return '/agent/dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final boatState = ref.watch(boatProvider);
    final billingState = ref.watch(billingProvider);
    final user = authState.user;

    final myBookings = billingState.bills
        .where((b) => b.agentId == user?.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Booking History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.push('/agent/profile'),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: billingState.isLoading || boatState.isLoading,
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () async {
            await ref.read(boatProvider.notifier).load();
            await ref.read(billingProvider.notifier).load();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.p16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppMetricCard(
                      title: 'Total Bookings',
                      value: '${myBookings.length}',
                      icon: Icons.bookmark,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.p12),
                  Expanded(
                    child: AppMetricCard(
                      title: 'Total Value',
                      value:
                          '₹${myBookings.fold(0.0, (s, b) => s + b.totalAmount).toStringAsFixed(0)}',
                      icon: Icons.currency_rupee,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p20),

              Text(
                'My Bookings',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              myBookings.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(AppSizes.p24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_outlined,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: AppSizes.p8),
                          Text(
                            'No bookings yet. Book a boat to get started!',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: myBookings.map((booking) {
                        final boat = boatState.boats.firstWhere(
                          (b) => b.id == booking.boatId,
                          orElse: () => boatState.boats.isEmpty
                              ? BoatEntity(
                                  id: booking.boatId,
                                  boatNumber: '',
                                  boatName: booking.boatName,
                                  ownerId: '',
                                  ownerName: '',
                                  agentId: '',
                                  agentName: '',
                                )
                              : boatState.boats.first,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSizes.p12),
                          padding: const EdgeInsets.all(AppSizes.p16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius16,
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySurface,
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radius8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.directions_boat,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: AppSizes.p12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            booking.billNumber,
                                            style: AppTextStyles.labelLarge
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            '${boat.boatName} (${boat.boatNumber})',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: booking.status == 'BOOKED'
                                          ? AppColors.infoLight
                                          : AppColors.warningLight,
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusCircular,
                                      ),
                                    ),
                                    child: Text(
                                      booking.status ?? 'BOOKED',
                                      style: AppTextStyles.overline.copyWith(
                                        color: booking.status == 'BOOKED'
                                            ? AppColors.info
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.p12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Date: ${booking.billDate.day}/${booking.billDate.month}/${booking.billDate.year}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ),
                                  Text(
                                    'Value: ₹${booking.totalAmount.toStringAsFixed(0)}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(width: .0),
            ],
          ),
        ),
      ),
    );
  }
}
