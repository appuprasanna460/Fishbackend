// lib/features/boat_owner/presentation/screens/boat_owner_boats.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../boats/domain/entities/boat_entity.dart';
import '../../../boats/presentation/screens/boat_form_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BoatOwnerBoatsScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const BoatOwnerBoatsScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<BoatOwnerBoatsScreen> createState() =>
      _BoatOwnerBoatsScreenState();
}

class _BoatOwnerBoatsScreenState extends ConsumerState<BoatOwnerBoatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBoats();
    });
  }

  void _loadBoats() {
    final authState = ref.read(authProvider);
    final user = authState.user;
    ref.read(boatProvider.notifier).load(ownerId: user?.id);
  }

  void _navigateToAddBoat() {
    context.push('/owner/my-boats/add'); // ✅ Use push for adding
  }

  void _navigateToEditBoat(BoatEntity boat) {
    context.push('/owner/my-boats/edit/${boat.id}'); // ✅ Use push for editing
  }

  // ✅ Fixed: Go back to dashboard
  void _goBack() {
    context.go('/owner/dashboard'); // ✅ Use go() to navigate to dashboard
  }

  Future<void> _toggleBoatStatus(BoatEntity boat) async {
    final updatedBoat = boat.copyWith(isActive: !boat.isActive);
    final success = await ref
        .read(boatProvider.notifier)
        .updateBoat(boat.id!, updatedBoat.toJson());

    if (success && mounted) {
      _loadBoats();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Boat ${updatedBoat.isActive ? 'activated' : 'deactivated'}',
          ),
          backgroundColor: updatedBoat.isActive ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // lib/features/boat_owner/presentation/screens/boat_owner_boats.dart

  Future<void> _deleteBoat(BoatEntity boat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Boat'),
        content: Text(
          'Are you sure you want to delete "${boat.boatName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false), // ✅ Fixed: Use context.pop()
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true), // ✅ Fixed: Use context.pop()
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(boatProvider.notifier)
          .deleteBoat(boat.id!);
      if (success && mounted) {
        _loadBoats();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Boat deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final boats = boatState.boats.where((b) => b.ownerId == user?.id).toList();

    final body = AppLoadingOverlay(
      isLoading: boatState.isLoading,
      child: boats.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () async {
                _loadBoats();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.p16),
                itemCount: boats.length,
                itemBuilder: (_, index) {
                  final boat = boats[index];
                  return _buildBoatCard(context, boat);
                },
              ),
            ),
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        // ✅ Fixed back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack, // ✅ Uses go() instead of pop()
          tooltip: 'Back to Dashboard',
        ),
        title: const Text('My Boats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddBoat,
            tooltip: 'Add Boat',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBoats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_boat_outlined,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No Boats Added',
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first boat to get started',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Add Boat',
            onPressed: _navigateToAddBoat,
            leadingIcon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildBoatCard(BuildContext context, BoatEntity boat) {
    final isActive = boat.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        side: BorderSide(
          color: isActive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Name + Status ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boat.boatName,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        boat.boatNumber,
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
                    color: isActive
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: AppTextStyles.caption.copyWith(
                      color: isActive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Details ────────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.person_outline, boat.ownerName ?? 'Owner'),
                if (boat.registrationNumber != null &&
                    boat.registrationNumber!.isNotEmpty)
                  _buildInfoChip(
                    Icons.confirmation_number,
                    boat.registrationNumber!,
                  ),
                if (boat.capacity != null)
                  _buildInfoChip(Icons.scale, '${boat.capacity} kg'),
                if (boat.locationName != null && boat.locationName!.isNotEmpty)
                  _buildInfoChip(Icons.location_on, boat.locationName!),
              ],
            ),
            const SizedBox(height: 12),

            // ── Actions ─────────────────────────────────────────────────
            // ✅ ONLY ONE ROW - REMOVED THE DUPLICATE Row
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: [
                // Edit button
                TextButton(
                  onPressed: () => _navigateToEditBoat(boat),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(40, 30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 4),
                      Text('Edit', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),

                // Toggle status button
                TextButton(
                  onPressed: () => _toggleBoatStatus(boat),
                  style: TextButton.styleFrom(
                    foregroundColor: isActive
                        ? AppColors.warning
                        : AppColors.success,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(40, 30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isActive ? Icons.pause : Icons.play_arrow, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Deactivate' : 'Activate',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Delete button
                TextButton(
                  onPressed: () => _deleteBoat(boat),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(40, 30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete, size: 16),
                      SizedBox(width: 4),
                      Text('Delete', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
