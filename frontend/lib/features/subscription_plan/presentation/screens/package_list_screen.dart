// lib/features/subscription_plan/presentation/screens/package_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/screens/notification_list_screen.dart';
import '../providers/subscription_plan_provider.dart';
import '../widgets/package_form_sheet.dart';
import '../../domain/entities/subscription_plan_entity.dart';

class PackageListScreen extends ConsumerStatefulWidget {
  const PackageListScreen({super.key});

  @override
  ConsumerState<PackageListScreen> createState() => _PackageListScreenState();
}

class _PackageListScreenState extends ConsumerState<PackageListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionPlanProvider.notifier).loadAllPlans();
    });
  }

  Future<void> _showCreateForm() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PackageFormSheet(),
    );
    if (result == true && mounted) {
      ref.read(subscriptionPlanProvider.notifier).loadAllPlans();
    }
  }

  Future<void> _showEditForm(SubscriptionPlanEntity plan) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PackageFormSheet(plan: plan),
    );
    if (result == true && mounted) {
      ref.read(subscriptionPlanProvider.notifier).loadAllPlans();
    }
  }

  Future<void> _confirmDelete(SubscriptionPlanEntity plan) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Package',
      message:
          'Are you sure you want to delete "${plan.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDangerous: true,
      icon: Icons.delete_outline,
    );
    if (confirmed == true && mounted) {
      final ok = await ref
          .read(subscriptionPlanProvider.notifier)
          .deletePlan(plan.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Package deleted' : 'Failed to delete package'),
            backgroundColor: ok ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus(SubscriptionPlanEntity plan) async {
    final ok = await ref
        .read(subscriptionPlanProvider.notifier)
        .togglePlanStatus(plan.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Status updated' : 'Failed to update status'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionPlanProvider);
    final authState = ref.watch(authProvider);
    final adminName = authState.user?.name ?? 'Admin';
    final plans = state.plans ?? [];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildAppDrawer(context, adminName),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: SafeArea(
          child: Column(
            children: [
              // ── Unified Top Header ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p12,
                ),
                child: _buildUnifiedHeader(
                  context: context,
                  title: 'Package Details',
                  adminName: adminName,
                  scaffoldKey: _scaffoldKey,
                  onRefresh: () => ref
                      .read(subscriptionPlanProvider.notifier)
                      .loadAllPlans(),
                ),
              ),

              // Subtitle Banner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.p16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Subscription Packages',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Create, manage and configure plans for market users',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p16),

              // Plan list
              Expanded(
                child: plans.isEmpty && !state.isLoading
                    ? const AppEmptyState(
                        title: 'No Packages Found',
                        subtitle:
                            'Create your first subscription package to get started.',
                        icon: Icons.card_giftcard_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p16,
                        ),
                        itemCount: plans.length,
                        itemBuilder: (_, index) {
                          final plan = plans[index];
                          return _PackageCard(
                            plan: plan,
                            onTap: () => _showEditForm(plan),
                            onToggle: () => _toggleStatus(plan),
                            onDelete: () => _confirmDelete(plan),
                          );
                        },
                      ),
              ),

              // Create button
              Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _showCreateForm,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: Text(
                      'Create New Package',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Unified Header Builder Helper ──────────────────────────────────────────

  Widget _buildUnifiedHeader({
    required BuildContext context,
    required String title,
    required String adminName,
    required GlobalKey<ScaffoldState> scaffoldKey,
    required VoidCallback onRefresh,
  }) {
    return Row(
      children: [
        // 3-line hamburger menu button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                scaffoldKey.currentState?.openDrawer();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                context.canPop() ? Icons.arrow_back_rounded : Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Left-aligned Title
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Refresh action
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Notification Bell
        Consumer(
          builder: (context, ref, child) {
            final notifState = ref.watch(notificationListProvider);
            final count =
                notifState.items.where((i) => !i.isActioned).length;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/admin/notifications'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.border.withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 10),

        // Profile Avatar Button
        GestureDetector(
          onTap: () => context.push('/admin/profile'),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Side Drawer Builder Helper ──────────────────────────────────────────────

  Widget _buildAppDrawer(BuildContext context, String adminName) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              accountName: Text(
                adminName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text('Super Admin • Harbour Pro'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.dashboard_rounded, color: AppColors.primary),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.anchor_rounded),
              title: const Text('Harbours'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/harbours');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_rounded),
              title: const Text('Users'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_rounded),
              title: const Text('Packages'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/packages');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: const Text('Invoice Templates'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/invoice-templates');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_rounded),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/notifications');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Package Card ─────────────────────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final SubscriptionPlanEntity plan;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PackageCard({
    required this.plan,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: plan.isActive
                          ? AppColors.primarySurface
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color:
                          plan.isActive ? AppColors.primary : AppColors.textHint,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSizes.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.durationDaysLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    plan.priceLabel,
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: 'Duration',
                    value: plan.durationLabel,
                  ),
                  const SizedBox(width: AppSizes.p8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p10,
                      vertical: AppSizes.p4,
                    ),
                    decoration: BoxDecoration(
                      color: plan.isActive
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plan.isActive ? 'Active' : 'Inactive',
                      style: AppTextStyles.caption.copyWith(
                        color: plan.isActive
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      plan.isActive
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      color:
                          plan.isActive ? AppColors.primary : AppColors.textHint,
                      size: 30,
                    ),
                    tooltip: plan.isActive ? 'Deactivate' : 'Activate',
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}