import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// The "More" tab for the Super Admin shared bottom navigation shell.
/// Hosts menu items that previously did not have a dedicated home tab:
/// Profile, Invoice Templates, Notifications, Change Password, Logout.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'More',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.p16),
        children: [
          // ── Profile Header ─────────────────────────────────────────────
          _ProfileHeader(
            name: user?.name ?? '',
            role: user?.displayRole ?? 'Super Admin',
            initials: _initials(user?.name ?? ''),
            onTap: () => context.push('/admin/profile'),
          ),
          const SizedBox(height: AppSizes.p24),

          // ── Primary item: Profile ──────────────────────────────────────
          _SectionLabel(label: 'Account'),
          const SizedBox(height: AppSizes.p8),
          _MenuCard(
            children: [
              _MenuRow(
                icon: Icons.person_rounded,
                label: 'Profile',
                subtitle: 'View and edit your personal information',
                color: AppColors.primary,
                onTap: () => context.push('/admin/profile'),
                showDivider: true,
              ),
              _MenuRow(
                icon: Icons.lock_reset_rounded,
                label: 'Change Password',
                subtitle: 'Update your login credentials',
                color: AppColors.primary,
                onTap: () => context.push('/admin/change-password'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p20),

          // ── Management ─────────────────────────────────────────────────
          _SectionLabel(label: 'Management'),
          const SizedBox(height: AppSizes.p8),
          _MenuCard(
            children: [
              _MenuRow(
                icon: Icons.description_rounded,
                label: 'Invoice Templates',
                subtitle: 'Manage invoice template designs',
                color: AppColors.accent,
                onTap: () => context.push('/admin/invoice-templates'),
                showDivider: true,
              ),
              _MenuRow(
                icon: Icons.notifications_rounded,
                label: 'Pending Approvals',
                subtitle: 'Review and approve pending registrations',
                color: AppColors.info,
                onTap: () => context.push('/admin/notifications'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p20),

          // ── Support ────────────────────────────────────────────────────
          _SectionLabel(label: 'Support'),
          const SizedBox(height: AppSizes.p8),
          _MenuCard(
            children: [
              _MenuRow(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                subtitle: 'Contact your system administrator',
                color: AppColors.warning,
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p24),

          // ── Logout ─────────────────────────────────────────────────────
          _LogoutButton(onPressed: () => _confirmLogout(context, ref)),
          const SizedBox(height: AppSizes.p8),
          Center(
            child: Text(
              'Fish Market Management System · v1.0.0',
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: AppSizes.p32),
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    return parts.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Logout',
      message:
          'Are you sure you want to logout? You will need to sign in again to access the system.',
      confirmLabel: 'Logout',
      isDangerous: true,
      icon: Icons.logout_rounded,
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String role;
  final String initials;
  final VoidCallback onTap;

  const _ProfileHeader({
    required this.name,
    required this.role,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowBlue,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Admin' : name,
                    style: AppTextStyles.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: AppSizes.p4),
                      Text(
                        role,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white70,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p14,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 68, endIndent: AppSizes.p16),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withOpacity(0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius12),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text('Logout', style: AppTextStyles.labelLarge),
      ),
    );
  }
}