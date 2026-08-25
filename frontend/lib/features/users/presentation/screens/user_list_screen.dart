import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../providers/user_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../locations/presentation/providers/location_provider.dart';
import '../../../dashboard/presentation/screens/notification_list_screen.dart';
import '../../data/models/user_model.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _selectedRole = 'ALL';

  final List<String> _roles = [
    'ALL',
    'SUPER_ADMIN',
    'COMMISSION_AGENT',
    'STAFF',
    'FISH_BUYER',
    'BOAT_OWNER',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).load();
      ref.read(locationProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    ref.read(userProvider.notifier).load(
          role: _selectedRole == 'ALL' ? null : _selectedRole,
          search: val.isEmpty ? null : val,
        );
  }

  void _onRoleChanged(String role) {
    setState(() => _selectedRole = role);
    final searchText = _searchController.text;
    ref.read(userProvider.notifier).load(
          role: role == 'ALL' ? null : role,
          search: searchText.isEmpty ? null : searchText,
        );
  }

  void _showRoleFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: AppSizes.p20),
            Text(
              'Filter by Role',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            ..._roles.map((role) {
              final isSelected = _selectedRole == role;
              final label = role == 'ALL'
                  ? 'All Roles'
                  : role.split('_').join(' ').toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.p8),
                child: InkWell(
                  onTap: () {
                    _onRoleChanged(role);
                    Navigator.of(ctx).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p16,
                      vertical: AppSizes.p12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primarySurface
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border.withOpacity(0.6),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textHint,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.p12),
                        Expanded(
                          child: Text(
                            label,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState.user?.role == 'SUPER_ADMIN';
    final adminName = authState.user?.name ?? 'Admin';
    final locationState = ref.watch(locationProvider);

    final allUsers = state.users;
    final totalUsers = allUsers.length;
    final activeUsers = allUsers.where((u) => u.isActive).length;
    final inactiveUsers = totalUsers - activeUsers;

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
                  title: 'User Management',
                  adminName: adminName,
                  scaffoldKey: _scaffoldKey,
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await ref.read(userProvider.notifier).load(
                          role: _selectedRole == 'ALL' ? null : _selectedRole,
                          search: _searchController.text.isEmpty
                              ? null
                              : _searchController.text,
                        );
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p16,
                      vertical: AppSizes.p8,
                    ),
                    children: [
                      // ── Stat Cards Row ──────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _UserStatCard(
                              title: 'Total Users',
                              value: '$totalUsers',
                              icon: Icons.people_alt_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _UserStatCard(
                              title: 'Active Accounts',
                              value: '$activeUsers',
                              icon: Icons.verified_user_rounded,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _UserStatCard(
                              title: 'Inactive',
                              value: '$inactiveUsers',
                              icon: Icons.person_off_rounded,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.p16),

                      // ── Add New User Action Button ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/admin/users/new'),
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            'Add New User',
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
                      const SizedBox(height: AppSizes.p16),

                      // ── Search & Filter Bar ─────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.border.withOpacity(0.6),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: const InputDecoration(
                                  hintText: 'Search user by name or email...',
                                  hintStyle: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showRoleFilterSheet,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.filter_list_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.p16),

                      // ── Active Role Chip ────────────────────────────────────
                      if (_selectedRole != 'ALL') ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Role: ${_selectedRole.replaceAll('_', ' ')}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _onRoleChanged('ALL'),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.p12),
                      ],

                      // ── User List Cards ─────────────────────────────────────
                      if (state.users.isEmpty && !state.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: AppEmptyState(
                            title: 'No Users Found',
                            subtitle:
                                'Try adjusting search query or filtering criteria.',
                            icon: Icons.people_outline,
                          ),
                        )
                      else
                        ...state.users.map((user) {
                          String locationName = '-';
                          if (user.locationId != null) {
                            for (final l in locationState.locations) {
                              if (l.id == user.locationId) {
                                locationName = l.name;
                                break;
                              }
                            }
                          }

                          return _buildUserCard(
                            context: context,
                            user: user,
                            locationName: locationName,
                            isSuperAdmin: isSuperAdmin,
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Individual User Card Widget ─────────────────────────────────────────────

  Widget _buildUserCard({
    required BuildContext context,
    required dynamic user,
    required String locationName,
    required bool isSuperAdmin,
  }) {
    final roleColor = _roleColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p10),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/admin/users/${user.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p14),
            child: Row(
              children: [
                // User Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        roleColor.withOpacity(0.85),
                        roleColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.p12),

                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Active status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: user.isActive
                                  ? AppColors.successLight
                                  : AppColors.errorLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isActive ? 'Active' : 'Inactive',
                              style: AppTextStyles.caption.copyWith(
                                color: user.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(_roleIcon(user.role),
                              size: 13, color: roleColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user.displayRole,
                              style: TextStyle(
                                color: roleColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '• $locationName',
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isSuperAdmin && user.role != 'SUPER_ADMIN') ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (val) async {
                      if (val == 'edit') {
                        context.push('/admin/users/${user.id}/edit');
                      } else if (val == 'delete') {
                        final confirm = await AppConfirmDialog.show(
                          context: context,
                          title: 'Delete User',
                          message:
                              'Are you sure you want to delete ${user.name}? This action cannot be undone.',
                          confirmLabel: 'Delete',
                          isDangerous: true,
                          icon: Icons.delete_outline,
                        );
                        if (confirm != true) return;
                        final ok = await ref
                            .read(userProvider.notifier)
                            .deleteUser(user.id);
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${user.name} deleted'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return Icons.admin_panel_settings_rounded;
      case 'COMMISSION_AGENT':
        return Icons.handshake_rounded;
      case 'STAFF':
        return Icons.badge_rounded;
      case 'BOAT_OWNER':
        return Icons.sailing_rounded;
      case 'FISH_BUYER':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return AppColors.roleSuperAdmin;
      case 'COMMISSION_AGENT':
        return AppColors.roleAgent;
      case 'STAFF':
        return AppColors.roleStaff;
      case 'BOAT_OWNER':
        return AppColors.roleOwner;
      case 'FISH_BUYER':
        return AppColors.roleBuyer;
      default:
        return AppColors.textSecondary;
    }
  }

  // ─── Unified Header Builder Helper ──────────────────────────────────────────

  Widget _buildUnifiedHeader({
    required BuildContext context,
    required String title,
    required String adminName,
    required GlobalKey<ScaffoldState> scaffoldKey,
  }) {
    return Row(
      children: [
        // 3-line hamburger menu button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => scaffoldKey.currentState?.openDrawer(),
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
                Icons.menu_rounded,
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

// ─── Compact User Stat Card Widget ────────────────────────────────────────────

class _UserStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _UserStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}