import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../locations/presentation/providers/location_provider.dart';
import '../../../locations/domain/entities/location_entity.dart';
import '../providers/user_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../domain/entities/user_entity.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(userProvider.notifier).loadById(widget.userId);
      await ref.read(locationProvider.notifier).load();
      ref.read(boatProvider.notifier).load(ownerId: widget.userId);
    });
  }

  void _onToggleStatus() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Toggle User Status',
      message: 'Are you sure you want to change this user\'s active status?',
    );

    if (confirmed == true) {
      final ok = await ref.read(userProvider.notifier).toggleUserStatus(widget.userId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User status updated successfully')),
        );
        ref.read(userProvider.notifier).loadById(widget.userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
    final user = state.selected;
    final locationState = ref.watch(locationProvider);

    if (state.isLoading || user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Resolve location and sub-location names
    String locationName = 'None';
    String subLocationName = 'None';
    if (user.locationId != null) {
      LocationEntity? matchedLoc;
      for (final l in locationState.locations) {
        if (l.id == user.locationId) {
          matchedLoc = l;
          break;
        }
      }
      if (matchedLoc != null) {
        locationName = matchedLoc.name;
        if (user.subLocationId != null && matchedLoc.subLocations.isNotEmpty) {
          SubLocationEntity? matchedSub;
          for (final s in matchedLoc.subLocations) {
            if (s.id == user.subLocationId) {
              matchedSub = s;
              break;
            }
          }
          if (matchedSub != null) {
            subLocationName = matchedSub.name;
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/admin/users/${user.id}/edit'),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSizes.p16),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: AppTextStyles.displayLarge.copyWith(color: AppColors.surface),
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              Text(
                user.name,
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSizes.p6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSizes.radius24),
                ),
                child: Text(
                  user.displayRole,
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppSizes.p24),

              // ── Registration Details ──────────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registration Details', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSizes.p16),
                    _infoRow(Icons.business_outlined, 'Company Name', user.companyName?.isNotEmpty == true ? user.companyName! : 'Not provided'),
                    const Divider(height: 24),
                    _infoRow(Icons.people_outline, 'Referred By', user.referenceBy?.isNotEmpty == true ? user.referenceBy! : 'Not provided'),
                    const Divider(height: 24),
                    _infoRow(Icons.anchor_rounded, 'Harbour', user.harbourName?.isNotEmpty == true ? user.harbourName! : 'Not provided'),
                    const Divider(height: 24),
                    _infoRow(Icons.calendar_today_outlined, 'Registered On', user.createdAt != null ? _formatDate(user.createdAt!) : 'Not provided'),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // ── Plan Details ────────────────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan Details', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSizes.p16),
                    _infoRow(Icons.credit_card_rounded, 'Plan Name', _planName(user)),
                    const Divider(height: 24),
                    _infoRow(Icons.timer_outlined, 'Duration', _planDuration(user)),
                    const Divider(height: 24),
                    _infoRow(Icons.currency_rupee_rounded, 'Price', _planPrice(user)),
                    const Divider(height: 24),
                    _infoRow(Icons.event_available_rounded, 'Start Date', user.subscriptionStartDate != null ? _formatDate(user.subscriptionStartDate!) : 'Not provided'),
                    const Divider(height: 24),
                    _infoRow(Icons.event_busy_rounded, 'End Date', user.subscriptionEndDate != null ? _formatDate(user.subscriptionEndDate!) : 'Not provided'),
                    const Divider(height: 24),
                    _infoRow(Icons.verified_rounded, 'Status', _subscriptionStatus(user)),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // ── Personal Info ────────────────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Info', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSizes.p16),
                    _infoRow(Icons.email_outlined, 'Email', user.email),
                    const Divider(height: 24),
                    _infoRow(Icons.phone_outlined, 'Phone', user.phone.isNotEmpty ? user.phone : 'Not provided'),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // ── Location Settings ───────────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location Settings', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSizes.p16),
                    _infoRow(Icons.location_on_outlined, 'Primary Location', locationName),
                    const Divider(height: 24),
                    _infoRow(Icons.navigation_outlined, 'Sub-Location', subLocationName),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // ── Account Settings ─────────────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Settings', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSizes.p16),
                    _infoRow(
                      Icons.toggle_on_outlined,
                      'Status',
                      user.isActive ? 'ACTIVE' : 'INACTIVE',
                      trailing: Switch(
                        value: user.isActive,
                        onChanged: (_) => _onToggleStatus(),
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (user.isOwner) ...[
                const SizedBox(height: AppSizes.p16),
                _buildOwnerBoatsSection(context, ref, user, locationName, subLocationName),
              ],
              const SizedBox(height: AppSizes.p32),
              OutlinedButton.icon(
                onPressed: _onToggleStatus,
                icon: Icon(user.isActive ? Icons.block : Icons.check_circle_outline),
                label: Text(user.isActive ? 'Deactivate Account' : 'Activate Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: user.isActive ? AppColors.error : AppColors.success,
                  side: BorderSide(color: user.isActive ? AppColors.error : AppColors.success),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _planName(UserEntity user) {
    if (user.planName?.isNotEmpty == true) return user.planName!;
    if (user.subscriptionPlan != null && user.subscriptionPlan != 'NONE') {
      return user.subscriptionPlan!
          .split('_')
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
          .join(' ');
    }
    return 'Not provided';
  }

  String _planDuration(UserEntity user) {
    if (user.planDurationDays != null) {
      return '${user.planDurationDays} days';
    }
    return 'Not provided';
  }

  String _planPrice(UserEntity user) {
    if (user.planPrice != null) {
      return '₹${user.planPrice!.toStringAsFixed(0)}';
    }
    return 'Not provided';
  }

  String _subscriptionStatus(UserEntity user) {
    final status = user.subscriptionStatus;
    if (status == null || status.isEmpty || status == 'NONE') return 'Not provided';
    return status
        .split('_')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
        .join(' ');
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildOwnerBoatsSection(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
    String primaryLocationName,
    String subLocationName,
  ) {
    final boatState = ref.watch(boatProvider);
    final ownerBoats = boatState.boats.where((b) => b.ownerId == user.id).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Boats',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _showAddBoatSheet(context, ref, user),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Boat'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          if (ownerBoats.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
                child: Text(
                  'No boats registered under this owner',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ownerBoats.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (_, i) {
                final boat = ownerBoats[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(Icons.directions_boat, color: AppColors.primary, size: 20),
                  ),
                  title: Text(boat.boatName, style: AppTextStyles.labelLarge),
                  subtitle: Text('No: ${boat.boatNumber} | Reg: ${boat.registrationNumber ?? "N/A"}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: boat.isActive ? AppColors.successLight : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppSizes.radius4),
                    ),
                    child: Text(
                      boat.isActive ? 'Active' : 'Inactive',
                      style: AppTextStyles.overline.copyWith(
                        color: boat.isActive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddBoatSheet(BuildContext context, WidgetRef ref, UserEntity owner) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final regNumCtrl = TextEditingController();
    bool isActive = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Boat for ${owner.name}',
                        style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                      ),
                    const SizedBox(height: AppSizes.p16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Boat Name',
                        prefixIcon: const Icon(Icons.directions_boat),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius12),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Boat name is required' : null,
                    ),
                    const SizedBox(height: AppSizes.p16),
                    TextFormField(
                      controller: numberCtrl,
                      decoration: InputDecoration(
                        labelText: 'Boat Number (Registration Number)',
                        prefixIcon: const Icon(Icons.app_registration),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius12),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Boat number is required' : null,
                    ),
                    const SizedBox(height: AppSizes.p16),
                    TextFormField(
                      controller: regNumCtrl,
                      decoration: InputDecoration(
                        labelText: 'Official License/Reg ID',
                        prefixIcon: const Icon(Icons.assignment_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius12),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p16),
                    SwitchListTile(
                      title: const Text('Status (Active)'),
                      value: isActive,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => isActive = val),
                    ),
                    const SizedBox(height: AppSizes.p24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                             : () async {
                                 if (!formKey.currentState!.validate()) return;
                                 setState(() => isSubmitting = true);

                                 final boatData = {
                                   'boatName': nameCtrl.text.trim(),
                                   'boatNumber': numberCtrl.text.trim().toUpperCase(),
                                   'registrationNumber': regNumCtrl.text.trim().toUpperCase(),
                                   'ownerId': owner.id,
                                   'ownerName': owner.name,
                                   'isActive': isActive,
                                   'capacity': 0,
                                 };

                                 final ok = await ref.read(boatProvider.notifier).createBoat(boatData);
                                setState(() => isSubmitting = false);

                                if (context.mounted) {
                                  if (ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Boat added successfully!')),
                                    );
                                    Navigator.pop(context);
                                    ref.read(boatProvider.notifier).load(ownerId: owner.id);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to add boat.')),
                                    );
                                  }
                                }
},
                         style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.primary,
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(AppSizes.radius12),
                           ),
                         ),
                         child: isSubmitting
                             ? const CircularProgressIndicator(color: Colors.white)
                             : const Text('Save'),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
           );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: AppSizes.p16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}