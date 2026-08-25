import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../../users/domain/entities/user_entity.dart';

class HarbourUsersScreen extends ConsumerStatefulWidget {
  final String harbourId;
  final String harbourName;

  const HarbourUsersScreen({
    super.key,
    required this.harbourId,
    required this.harbourName,
  });

  @override
  ConsumerState<HarbourUsersScreen> createState() => _HarbourUsersScreenState();
}

class _HarbourUsersScreenState extends ConsumerState<HarbourUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).load(harbourId: widget.harbourId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);

    final users = state.users;
    final activeUsers = users.where((u) => u.isActive).length;
    final inactiveUsers = users.length - activeUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.harbourName,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () =>
                ref.read(userProvider.notifier).load(harbourId: widget.harbourId),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Harbour Info Banner ──────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppSizes.p16),
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
                    Icons.anchor_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.harbourName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${users.length} users registered under this harbour',
                        style: GoogleFonts.inter(
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

          // ── Stats Row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: Row(
              children: [
                Expanded(
                  child: _HarbourUserStatCard(
                    title: 'Total Users',
                    value: '${users.length}',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HarbourUserStatCard(
                    title: 'Active',
                    value: '$activeUsers',
                    icon: Icons.verified_user_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HarbourUserStatCard(
                    title: 'Inactive',
                    value: '$inactiveUsers',
                    icon: Icons.person_off_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p16),

          // ── User List ────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading && users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_outline_rounded,
                              size: 56,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No users under this harbour',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          await ref
                              .read(userProvider.notifier)
                              .load(harbourId: widget.harbourId);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.p16,
                          ),
                          itemCount: users.length,
                          itemBuilder: (ctx, i) {
                            final user = users[i];
                            return _HarbourUserCard(
                              user: user,
                              onTap: () =>
                                  context.push('/admin/users/${user.id}'),
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

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _HarbourUserStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _HarbourUserStatCard({
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
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── User Card ───────────────────────────────────────────────────────────────

class _HarbourUserCard extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onTap;

  const _HarbourUserCard({
    required this.user,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap,
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
                          if (user.companyName?.isNotEmpty == true) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '• ${user.companyName}',
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}