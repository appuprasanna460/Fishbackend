// lib/features/boats/presentation/screens/boat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/providers/booking_provider.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../fish/presentation/providers/fish_provider.dart';
import '../../../boats/domain/entities/boat_entity.dart';
import '../../../fish/domain/entities/fish_entity.dart';
import '../../../../core/widgets/app_button.dart';

class BoatListScreen extends ConsumerStatefulWidget {
  const BoatListScreen({super.key});

  @override
  ConsumerState<BoatListScreen> createState() => _BoatListScreenState();
}

class _BoatListScreenState extends ConsumerState<BoatListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatProvider.notifier).load();
      // ✅ Load BOTH types of bookings
      ref.read(bookingProvider.notifier).loadMyBookings();
      ref.read(bookingProvider.notifier).loadAllBookings();
      ref.read(fishProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            'Boats & Bookings',
            style: AppTextStyles.h4.copyWith(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                ref.read(boatProvider.notifier).load();
                ref.read(bookingProvider.notifier).loadMyBookings();
                ref.read(fishProvider.notifier).load();
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Available Boats'),
              Tab(text: 'My Booked Boats'),
              Tab(text: 'Fish Master'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_AvailableBoatsTab(), _MyBookedBoatsTab(), _FishListTab()],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Available Boats
// ─────────────────────────────────────────────────────────────────────────────

class _AvailableBoatsTab extends ConsumerStatefulWidget {
  const _AvailableBoatsTab();

  @override
  ConsumerState<_AvailableBoatsTab> createState() => _AvailableBoatsTabState();
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Available Boats
// ─────────────────────────────────────────────────────────────────────────────

class _AvailableBoatsTabState extends ConsumerState<_AvailableBoatsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final bookingState = ref.watch(bookingProvider);
    final bookingNotifier = ref.read(bookingProvider.notifier);

    final authState = ref.watch(authProvider);
    final currentAgentId = authState.user?.id ?? '';

    // ✅ DEBUG: Print boat IDs and booking IDs
    print('📊 Boats:');
    for (final boat in boatState.boats) {
      print('  Boat: ${boat.boatName} (ID: ${boat.id})');
    }

    print('📊 Booking Status: ${bookingState.bookingStatus}');
    print('📊 Current Agent ID: $currentAgentId');

    final displayBoats = boatState.boats.where((b) {
      final q = _searchCtrl.text.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          b.boatName.toLowerCase().contains(q) ||
          b.boatNumber.toLowerCase().contains(q) ||
          (b.ownerName?.toLowerCase().contains(q) ?? false);

      if (!b.isActive || !matchesSearch) return false;

      // ✅ Check if boat is booked using boat.id
      final isBooked = bookingNotifier.isBoatBooked(b.id);
      print('  Boat ${b.boatName} (${b.id}) - isBooked: $isBooked');

      if (!isBooked) {
        print('  🟢 Boat ${b.boatName} is AVAILABLE');
        return true;
      }

      final booking = bookingNotifier.getBookingDetails(b.id);
      final isBookedByCurrentAgent = booking?.agentId == currentAgentId;

      if (isBookedByCurrentAgent) {
        print('  🔵 Boat ${b.boatName} booked by YOU - HIDDEN');
        return false;
      } else {
        print(
          '  🟡 Boat ${b.boatName} booked by ${booking?.agentName ?? 'Unknown'} - SHOW',
        );
        return true;
      }
    }).toList();

    final bookedByOthers = displayBoats
        .where((b) => bookingNotifier.isBoatBooked(b.id))
        .toList();
    final availableBoats = displayBoats
        .where((b) => !bookingNotifier.isBoatBooked(b.id))
        .toList();

    print(
      '📊 Display Boats: ${displayBoats.length} (${availableBoats.length} available, ${bookedByOthers.length} booked by others)',
    );

    return AppLoadingOverlay(
      isLoading: boatState.isLoading || bookingState.isLoading,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p16,
              AppSizes.p16,
              AppSizes.p16,
              AppSizes.p8,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search boats...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ),
          if (boatState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              child: AppErrorBanner(
                message: boatState.error!,
                onRetry: () {
                  ref.read(boatProvider.notifier).load();
                  ref.read(bookingProvider.notifier).loadMyBookings();
                },
              ),
            ),
          if (boatState.boats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p4,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${availableBoats.length} available · ${bookedByOthers.length} booked by others',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref.read(boatProvider.notifier).load();
                await ref.read(bookingProvider.notifier).loadMyBookings();
              },
              child: displayBoats.isEmpty && !boatState.isLoading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        AppEmptyState(
                          title: 'No Boats Available',
                          subtitle:
                              'All boats are either booked by you or others.',
                          icon: Icons.directions_boat_outlined,
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSizes.p16),
                      itemCount: displayBoats.length,
                      itemBuilder: (_, i) {
                        final boat = displayBoats[i];
                        final isBooked = bookingNotifier.isBoatBooked(boat.id);
                        final booking = isBooked
                            ? bookingNotifier.getBookingDetails(boat.id)
                            : null;

                        return _AvailableBoatCard(
                          boat: boat,
                          isBooked: isBooked,
                          booking: booking,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableBoatCard extends ConsumerStatefulWidget {
  final BoatEntity boat;
  final bool isBooked;
  final BookingEntity? booking;

  const _AvailableBoatCard({
    super.key,
    required this.boat,
    required this.isBooked,
    this.booking,
  });

  @override
  ConsumerState<_AvailableBoatCard> createState() => _AvailableBoatCardState();
}

class _AvailableBoatCardState extends ConsumerState<_AvailableBoatCard> {
  bool _isBooking = false;

  Future<void> _bookBoat() async {
    setState(() => _isBooking = true);

    final booking = await ref
        .read(bookingProvider.notifier)
        .bookBoat(widget.boat.id);

    setState(() => _isBooking = false);

    if (mounted) {
      if (booking != null) {
        AppErrorBanner.showSuccess(
          context,
          '✅ ${widget.boat.boatName} booked successfully!',
        );
        // ✅ Refresh to update the list
        await ref.read(bookingProvider.notifier).loadMyBookings();
        setState(() {}); // Force rebuild
      } else {
        // ✅ If booking failed (already booked), refresh to show the "Booked by" message
        await ref.read(bookingProvider.notifier).loadMyBookings();
        setState(() {}); // Force rebuild
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boat = widget.boat;
    final isBooked = widget.isBooked;
    final booking = widget.booking;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(
          color: isBooked ? AppColors.warning : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Boat Info
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isBooked
                          ? [AppColors.warning, AppColors.warningLight]
                          : [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  child: Icon(
                    isBooked ? Icons.bookmark : Icons.directions_boat,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSizes.p14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boat.boatName,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reg: ${boat.boatNumber}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (boat.ownerName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Owner: ${boat.ownerName}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                      // ✅ Show "Booked by" for OTHER agents
                      if (isBooked && booking != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Booked by: ${booking.agentName}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isBooked
                        ? AppColors.warningLight
                        : AppColors.successLight,
                    borderRadius: BorderRadius.circular(
                      AppSizes.radiusCircular,
                    ),
                  ),
                  child: Text(
                    isBooked ? 'Booked' : 'Available',
                    style: AppTextStyles.overline.copyWith(
                      color: isBooked ? AppColors.warning : AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.all(AppSizes.p12),
            child: SizedBox(
              width: double.infinity,
              child: isBooked
                  ? OutlinedButton.icon(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textHint,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.p12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius12,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.block, size: 20),
                      label: Text(
                        'Already Booked${booking != null ? ' by ${booking.agentName}' : ''}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _isBooking ? null : _bookBoat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.p12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius12,
                          ),
                        ),
                        elevation: 0,
                      ),
                      icon: _isBooking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.bookmark_add_outlined, size: 20),
                      label: Text(
                        _isBooking ? 'Booking...' : 'Book This Boat',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — My Booked Boats
// ─────────────────────────────────────────────────────────────────────────────

class _MyBookedBoatsTab extends ConsumerWidget {
  const _MyBookedBoatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingProvider);
    final boatState = ref.watch(boatProvider);

    // ✅ SAFE: Use null-aware operator with fallback
    final myBookings = bookingState.myBookings ?? const [];

    return AppLoadingOverlay(
      isLoading: bookingState.isLoading,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(bookingProvider.notifier).loadMyBookings(),
        child: myBookings.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  AppEmptyState(
                    title: 'No Bookings',
                    subtitle: 'Go to "Available Boats" tab and book a boat.',
                    icon: Icons.bookmark_border_outlined,
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.p16),
                itemCount: myBookings.length,
                itemBuilder: (_, i) {
                  final booking = myBookings[i];
                  final boat = boatState.boats
                      .where((b) => b.id == booking.boatId)
                      .firstOrNull;

                  return _BookedBoatCard(booking: booking, boat: boat);
                },
              ),
      ),
    );
  }
}

class _BookedBoatCard extends ConsumerStatefulWidget {
  final BookingEntity booking;
  final BoatEntity? boat;

  const _BookedBoatCard({super.key, required this.booking, this.boat});

  @override
  ConsumerState<_BookedBoatCard> createState() => _BookedBoatCardState();
}

class _BookedBoatCardState extends ConsumerState<_BookedBoatCard> {
  bool _isRemoving = false;

  Future<void> _removeBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove Booking'),
        content: Text(
          'Remove booking for "${widget.boat?.boatName ?? 'boat'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      setState(() => _isRemoving = true);

      final ok = await ref
          .read(bookingProvider.notifier)
          .removeBooking(widget.booking.id, widget.booking.boatId);

      setState(() => _isRemoving = false);

      if (context.mounted) {
        if (ok) {
          AppErrorBanner.showSuccess(context, ' Booking removed successfully.');
        } else {
          AppErrorBanner.show(context, 'Failed to remove booking.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final boat = widget.boat;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                child: const Icon(
                  Icons.directions_boat,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boat?.boatName ?? 'Unknown Boat',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      boat?.boatNumber ?? 'N/A',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                ),
                child: Text(
                  'Booked',
                  style: AppTextStyles.overline.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.p12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Text(
                'Booked on: ${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Booking #${booking.bookingNumber}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p10),
          // Remove Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isRemoving ? null : _removeBooking,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: AppSizes.p10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
              ),
              icon: _isRemoving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(Icons.delete_outline, size: 16),
              label: Text(
                _isRemoving ? 'Removing...' : 'Remove Booking',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Fish List
// Agent can add fish by name (calls the fish API) and see existing fish
// ─────────────────────────────────────────────────────────────────────────────

class _FishListTab extends ConsumerStatefulWidget {
  const _FishListTab();

  @override
  ConsumerState<_FishListTab> createState() => _FishListTabState();
}

class _FishListTabState extends ConsumerState<_FishListTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddFishSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddFishSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fishState = ref.watch(fishProvider);

    final filtered = fishState.fish.where((f) {
      final q = _searchCtrl.text.toLowerCase();
      return q.isEmpty ||
          f.name.toLowerCase().contains(q) ||
          (f.localName?.toLowerCase().contains(q) ?? false) ||
          (f.category?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Stack(
      children: [
        AppLoadingOverlay(
          isLoading: fishState.isLoading,
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.p16,
                  AppSizes.p16,
                  AppSizes.p16,
                  AppSizes.p8,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search fish...',
                    prefixIcon: const Icon(Icons.search, size: AppSizes.iconMd),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: AppSizes.p16,
                    ),
                  ),
                ),
              ),
              // Summary chip
              if (fishState.fish.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p16,
                    vertical: AppSizes.p4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filtered.length} fish type${filtered.length != 1 ? 's' : ''}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              const Divider(height: 1),
              // List
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () => ref.read(fishProvider.notifier).load(),
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            AppEmptyState(
                              title: 'No Fish Found',
                              subtitle:
                                  'Tap "Add Fish" to create a new fish type.',
                              icon: Icons.set_meal_outlined,
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.p16,
                            AppSizes.p12,
                            AppSizes.p16,
                            80,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _FishTile(fish: filtered[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: AppSizes.p16,
          bottom: AppSizes.p16,
          child: FloatingActionButton.extended(
            onPressed: _showAddFishSheet,
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Fish'),
          ),
        ),
      ],
    );
  }
}

class _FishTile extends ConsumerWidget {
  final FishEntity fish;
  const _FishTile({required this.fish});

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove Fish'),
        content: Text('Remove "${fish.name}" from the fish master list?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final ok = await ref.read(fishProvider.notifier).deleteFish(fish.id);
      if (context.mounted) {
        if (ok) {
          AppErrorBanner.showSuccess(context, '"${fish.name}" removed.');
        } else {
          AppErrorBanner.show(context, 'Failed to remove fish.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p10),
      padding: const EdgeInsets.all(AppSizes.p14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
            ),
            child: const Icon(
              Icons.set_meal,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fish.name, style: AppTextStyles.labelLarge),
                if (fish.localName != null)
                  Text(
                    fish.localName!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (fish.category != null)
                  Text(
                    fish.category!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: fish.isActive
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                ),
                child: Text(
                  fish.isActive ? 'Active' : 'Inactive',
                  style: AppTextStyles.overline.copyWith(
                    color: fish.isActive ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSizes.p8),
          // Remove button
          IconButton(
            onPressed: () => _remove(context, ref),
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
            tooltip: 'Remove fish',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.errorLight,
              padding: const EdgeInsets.all(AppSizes.p8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Fish Bottom Sheet ────────────────────────────────────────────────────

// ── Add Fish Bottom Sheet ────────────────────────────────────────────────────

class _AddFishSheet extends ConsumerStatefulWidget {
  const _AddFishSheet();

  @override
  ConsumerState<_AddFishSheet> createState() => _AddFishSheetState();
}

class _AddFishSheetState extends ConsumerState<_AddFishSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final success = await ref.read(fishProvider.notifier).createFish({
      'name': _nameCtrl.text.trim(),
    });

    setState(() => _isSubmitting = false);

    // In _AddFishSheet's _submit method
    if (mounted) {
      if (success) {
        AppErrorBanner.showSuccess(context, 'Fish added successfully!');
        Navigator.pop(context); // ✅ Use Navigator.pop
      } else {
        AppErrorBanner.show(context, 'Failed to add fish. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radius24),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSizes.p24,
        left: AppSizes.p20,
        right: AppSizes.p20,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.p24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.p8),
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                  ),
                  child: const Icon(
                    Icons.set_meal,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Text(
                  'Add New Fish',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p20),

            // Fish Name
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Fish Name *',
                hintText: 'e.g. Seer Fish',
                prefixIcon: const Icon(Icons.set_meal_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Fish name is required'
                  : null,
            ),
            const SizedBox(height: AppSizes.p24),

            // ✅ Use AppButton (you already have it)
            AppButton(
              text: 'Add Fish',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
              leadingIcon: Icons.add_circle_outline,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — Available Boats
// Shows all boats created by SuperAdmin; agent can book with one tap
// ─────────────────────────────────────────────────────────────────────────────
