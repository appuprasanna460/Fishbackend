import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/zoom_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/pin_provider.dart';
import '../../../../core/utils/secure_storage.dart';
import '../../../subscription_plan/presentation/providers/subscription_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final subState = ref.watch(subscriptionProvider);
    final zoomLevel = ref.watch(zoomLevelProvider);

    // Load subscription on first build
    ref.listenManual(subscriptionProvider.select((s) => s.subscription), (_, __) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (subState.subscription == null && !subState.isLoading) {
        ref.read(subscriptionProvider.notifier).loadMySubscription();
      }
    });

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initials = user.name.isNotEmpty
        ? user.name
              .trim()
              .split(' ')
              .take(2)
              .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
              .join()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primaryDark,
            iconTheme: const IconThemeData(color: Colors.white),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: const Text(
              'My Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.lock_reset_rounded, color: Colors.white),
                tooltip: 'Change Password',
                onPressed: () => context.push('/change-password'),
              ),
              const SizedBox(width: AppSizes.p4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDark,
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  // Content
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSizes.p32),
                        // Avatar with ring
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: AppTextStyles.h1.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Active status dot
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: user.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.p12),
                        Text(
                          user.name,
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _StatChip(
                          icon: Icons.verified_user_rounded,
                          label: user.isActive ? 'Active Account' : 'Inactive',
                          color: user.isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Curved bottom clip
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(24),
              child: Container(
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16,
                0,
                AppSizes.p16,
                AppSizes.p16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Personal Info ──────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.person_rounded,
                    title: 'Personal Information',
                  ),
                  const SizedBox(height: AppSizes.p10),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Full Name',
                        value: user.name,
                        copyable: true,
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: user.email,
                        copyable: true,
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        value: user.phone.isNotEmpty
                            ? user.phone
                            : 'Not provided',
                        copyable: user.phone.isNotEmpty,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.p20),

                  // ── Location ───────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.location_on_rounded,
                    title: 'Location',
                  ),
                  const SizedBox(height: AppSizes.p10),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Primary Location',
                        value: user.locationId ?? 'Not assigned',
                        valueColor: user.locationId == null
                            ? AppColors.textHint
                            : null,
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: Icons.place_outlined,
                        label: 'Sub-Location',
                        value: user.subLocationId ?? 'Not assigned',
                        valueColor: user.subLocationId == null
                            ? AppColors.textHint
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.p20),

                  // ── Account Details ────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Account Details',
                  ),
                  const SizedBox(height: AppSizes.p10),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.shield_outlined,
                        label: 'Role',
                        value: user.displayRole,
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Account Status',
                        value: user.isActive ? 'Active' : 'Inactive',
                        valueColor: user.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      if (user.createdAt != null) ...[
                        _Divider(),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member Since',
                          value: _formatDate(user.createdAt!),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSizes.p20),

                  // ── Subscription Card ──────────────────────────────────
                  if (!user.isSuperAdmin) ...[
                    _SectionHeader(
                      icon: Icons.card_membership_rounded,
                      title: 'Subscription',
                    ),
                    const SizedBox(height: AppSizes.p10),
                    _SubscriptionCard(
                      subState: subState,
                      onViewPlan: () => context.push('/subscription-detail'),
                    ),
                    const SizedBox(height: AppSizes.p20),
                  ],

                  // ── Actions ────────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.settings_rounded,
                    title: 'Account Settings',
                  ),
                  const SizedBox(height: AppSizes.p10),
                  _ActionCard(
                    children: [
                      _ActionRow(
                        icon: Icons.lock_reset_rounded,
                        label: 'Change Password',
                        subtitle: 'Update your login credentials',
                        color: AppColors.primary,
                        onTap: () => context.push('/change-password'),
                        showDivider: true,
                      ),
                      _ActionRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'App PIN Lock',
                        subtitle: ref.watch(pinProvider).hasPinSet
                            ? 'PIN lock is enabled (tap to change/disable)'
                            : 'Set a 4-digit PIN for quick app access',
                        color: AppColors.warning,
                        onTap: () => _showPinSettingsDialog(context, ref),
                        showDivider: true,
                      ),
                      _ActionRow(
                        icon: Icons.zoom_in_rounded,
                        label: 'UI Zoom / Scale',
                        subtitle: 'Adjust app layout size (${(zoomLevel * 100).round()}% scale)',
                        color: AppColors.primary,
                        onTap: () => _showZoomSettingsDialog(context, ref),
                        showDivider: true,
                      ),
                      _ActionRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        subtitle: 'Contact your system administrator',
                        color: AppColors.info,
                        onTap: () {},
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.p24),

                  // ── Logout ─────────────────────────────────────────────
                  AppButton.danger(
                    text: 'Logout',
                    onPressed: () => _confirmLogout(context, ref),
                    leadingIcon: Icons.logout_rounded,
                  ),
                  const SizedBox(height: AppSizes.p8),
                  Center(
                    child: Text(
                      'Fish Market Management System · v1.0.0',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showZoomSettingsDialog(BuildContext context, WidgetRef ref) {
    final currentZoom = ref.read(zoomLevelProvider);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'UI Zoom / Scale Preferences',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Adjust the layout size of the app to your preference:',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildZoomOption(ctx, ref, 0.8, '80% (Smaller)', currentZoom),
              const Divider(height: 1),
              _buildZoomOption(ctx, ref, 0.9, '90% (Slightly smaller)', currentZoom),
              const Divider(height: 1),
              _buildZoomOption(ctx, ref, 1.0, '100% (Default)', currentZoom),
              const Divider(height: 1),
              _buildZoomOption(ctx, ref, 1.1, '110% (Slightly larger)', currentZoom),
              const Divider(height: 1),
              _buildZoomOption(ctx, ref, 1.2, '120% (Larger)', currentZoom),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Close',
                style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZoomOption(
    BuildContext context,
    WidgetRef ref,
    double value,
    String label,
    double currentZoom,
  ) {
    return RadioListTile<double>(
      value: value,
      groupValue: currentZoom,
      title: Text(
        label,
        style: GoogleFonts.inter(fontSize: 14),
      ),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) async {
        if (val != null) {
          await ref.read(zoomLevelProvider.notifier).setZoomLevel(val);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('UI scale set to ${(val * 100).round()}%')),
            );
          }
        }
      },
    );
  }

  Future<void> _showPinSettingsDialog(BuildContext context, WidgetRef ref) async {
    final pinState = ref.read(pinProvider);
    final hasPin = pinState.hasPinSet;

    if (hasPin) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'App PIN Lock Settings',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
                title: const Text('Change PIN'),
                subtitle: const Text('Set a new 4-digit security PIN'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSetPinDialog(context, ref);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lock_open_rounded, color: AppColors.danger),
                title: const Text('Disable PIN Lock'),
                subtitle: const Text('Remove security PIN code entry on launch'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await AppConfirmDialog.show(
                    context: context,
                    title: 'Disable PIN Lock',
                    message: 'Are you sure you want to remove the PIN lock?',
                    confirmLabel: 'Disable',
                    isDangerous: true,
                  );
                  if (confirmed == true) {
                    await ref.read(pinProvider.notifier).clearPin();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN Lock disabled successfully')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
    } else {
      _showSetPinDialog(context, ref);
    }
  }

  void _showSetPinDialog(BuildContext context, WidgetRef ref) {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Set App PIN Lock',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a 4-digit security PIN to quickly unlock the app.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: pinCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Enter 4-Digit PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.password_rounded),
                ),
                validator: (v) {
                  if (v == null || v.length != 4) {
                    return 'Must be exactly 4 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.password_rounded),
                ),
                validator: (v) {
                  if (v != pinCtrl.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ref.read(pinProvider.notifier).setPin(pinCtrl.text);
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN Lock configured successfully')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              'Save PIN',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatYear(DateTime dt) => '${dt.year}';
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSizes.p6),
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.p4,
          horizontal: AppSizes.p4,
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final List<Widget> children;
  const _ActionCard({required this.children});

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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 60, endIndent: AppSizes.p16);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool copyable;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.copyable = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: copyable
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  margin: const EdgeInsets.all(AppSizes.p16),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: valueColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (copyable)
              Icon(Icons.copy_rounded, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  const _ActionRow({
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSizes.p4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String role;
  const _RolePill({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = role
        .split('_')
        .map(
          (w) => w.isNotEmpty
              ? w[0].toUpperCase() + w.substring(1).toLowerCase()
              : '',
        )
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p14,
        vertical: AppSizes.p6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, size: 11, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTag extends StatelessWidget {
  final String role;
  const _RoleTag({required this.role});

  Color _colorForRole(String r) {
    switch (r) {
      case 'SUPER_ADMIN':
        return AppColors.roleSuperAdmin;
      case 'COMMISSION_AGENT':
        return AppColors.roleAgent;
      case 'STAFF':
        return AppColors.roleStaff;
      case 'FISH_BUYER':
        return AppColors.roleBuyer;
      case 'BOAT_OWNER':
        return AppColors.roleOwner;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForRole(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role.split('_').first,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Subscription Card ────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionState subState;
  final VoidCallback onViewPlan;

  const _SubscriptionCard({required this.subState, required this.onViewPlan});

  Color get _statusColor {
    switch (subState.subscription?.status) {
      case 'ACTIVE':
        return const Color(0xFF2ECC71);
      case 'EXPIRING_SOON':
        return const Color(0xFFF39C12);
      case 'EXPIRED':
        return const Color(0xFFE74C3C);
      case 'PENDING_APPROVAL':
        return const Color(0xFF3498DB);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String get _statusLabel {
    switch (subState.subscription?.status) {
      case 'ACTIVE':
        return 'Active';
      case 'EXPIRING_SOON':
        return 'Expiring Soon';
      case 'EXPIRED':
        return 'Expired';
      case 'PENDING_APPROVAL':
        return 'Pending Approval';
      default:
        return 'No Plan';
    }
  }

  IconData get _statusIcon {
    switch (subState.subscription?.status) {
      case 'ACTIVE':
        return Icons.check_circle_rounded;
      case 'EXPIRING_SOON':
        return Icons.timer_rounded;
      case 'EXPIRED':
        return Icons.cancel_rounded;
      case 'PENDING_APPROVAL':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (subState.isLoading && subState.subscription == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final sub = subState.subscription;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _statusColor.withOpacity(0.08),
            _statusColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + Plan name row
            Row(
              children: [
                Icon(_statusIcon, color: _statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sub?.planName ?? 'No subscription',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (sub != null && sub.expiryDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Expires: ${_fmtDate(sub.expiryDate!)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${sub.remainingDays} day${sub.remainingDays == 1 ? '' : 's'} left',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Remaining days progress bar
              if (sub.durationDays != null && sub.durationDays! > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (sub.remainingDays / sub.durationDays!).clamp(0.0, 1.0),
                    backgroundColor: _statusColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                    minHeight: 6,
                  ),
                ),
            ],
            if (sub?.pendingRenewal != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.pending_actions_rounded,
                      size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    'Renewal pending approval',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewPlan,
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('View Plan Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _statusColor,
                  side: BorderSide(color: _statusColor.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}
