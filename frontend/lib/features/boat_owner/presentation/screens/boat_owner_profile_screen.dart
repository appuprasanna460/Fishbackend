import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/pin_provider.dart';
import '../../../subscription_plan/presentation/providers/subscription_provider.dart';
import '../providers/crew_provider.dart';

class BoatOwnerProfileScreen extends ConsumerStatefulWidget {
  const BoatOwnerProfileScreen({super.key});

  @override
  ConsumerState<BoatOwnerProfileScreen> createState() => _BoatOwnerProfileScreenState();
}

class _BoatOwnerProfileScreenState extends ConsumerState<BoatOwnerProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).loadMySubscription();
      // Fetch crew members list to populate counts if Boat Owner
      final user = ref.read(authProvider).user;
      if (user != null && user.role == 'BOAT_OWNER') {
        ref.read(crewProvider.notifier).fetchCrew();
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final subState = ref.watch(subscriptionProvider);
    final crewState = ref.watch(crewProvider);
    final sub = subState.subscription;

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

    final isOwner = user.role == 'BOAT_OWNER';

    // Calculate team counts
    final totalTeam = crewState.crewMembers.length;
    final activeTeam = crewState.crewMembers.where((m) => m.isActive).length;
    final inactiveTeam = totalTeam - activeTeam;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          children: [
            // ── Profile Photo & Details Card ─────────────────────────────────────
            Card(
  elevation: 0,
  margin: EdgeInsets.zero,
  color: AppColors.primary,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(
      color: AppColors.primary,
    ),
  ),
  child: InkWell(
    onTap: () => context.push('/owner/personal-info'),
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 1,
                  ),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (user.isActive)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 17,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  user.displayRole,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                _buildHeaderDetailRow(
                  Icons.phone_outlined,
                  'Phone',
                  user.phone,
                  'phone',
                ),

                const SizedBox(height: 3),

                _buildHeaderDetailRow(
                  Icons.email_outlined,
                  'Email',
                  user.email,
                  'email',
                ),

                const SizedBox(height: 3),

                _buildHeaderDetailRow(
                  Icons.location_on_outlined,
                  'Location',
                  user.locationId ?? 'Not Assigned',
                  'locationId',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
),

const SizedBox(height: AppSizes.p16),

            // ── About You Section ─────────────────────────────────────────────
            _buildSection(
              title: 'ABOUT YOU',
              children: [
                InkWell(
                  onTap: () => _showEditFieldDialog(
                    context, 
                    'About You', 
                    'aboutYou', 
                    user.aboutYou ?? ''
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (user.aboutYou != null && user.aboutYou!.isNotEmpty)
                                ? user.aboutYou!
                                : 'Fishing is our life. Harbour Pro is our strength.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit_outlined, size: 16, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p16),



            // ── Business Profile Section ──────────────────────────────────────
            if (isOwner) ...[
              _buildSection(
                title: 'BUSINESS PROFILE',
                children: [
                  _buildNavigationRow(
                    icon: Icons.business_center_outlined,
                    label: 'Company Profile',
                    subtitle: user.companyName ?? 'Configure company details',
                    onTap: () => context.push('/owner/company-profile'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p16),
            ],

            // ── Subscription Section ─────────────────────────────────────────
            if (!user.isSuperAdmin) ...[
              _buildSection(
                title: 'SUBSCRIPTION',
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sub?.planName ?? 'Standard Plan',
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (sub?.status == 'ACTIVE')
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sub?.status ?? 'ACTIVE',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: (sub?.status == 'ACTIVE') ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valid Until: ${sub?.expiryDate != null ? _formatDate(sub!.expiryDate!) : "15-Nov-2026"}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      const Divider(height: 20),
                      _buildNavigationRow(
                        icon: Icons.wallet_membership_outlined,
                        label: 'View Subscription',
                        subtitle: 'Check plans and usage parameters',
                        onTap: () => context.push('/subscription-detail'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p16),
            ],

            // ── Team & Users Section ─────────────────────────────────────────
            if (isOwner) ...[
              _buildSection(
                title: 'TEAM & USERS',
                children: [
                  _buildNavigationRow(
                    icon: Icons.people_alt_outlined,
                    label: 'Team & Users',
                    subtitle: 'Total: $totalTeam  |  Active: $activeTeam  |  Inactive: $inactiveTeam',
                    onTap: () => context.push('/owner/team'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p16),
            ],

            // ── Preferences & Security Section ───────────────────────────────
            _buildSection(
              title: 'PREFERENCES & SECURITY',
              children: [
                _buildNavigationRow(
                  icon: Icons.language_outlined,
                  label: 'Language & Voice Settings',
                  subtitle: 'Primary: Tamil  |  Secondary: English',
                  onTap: () => context.push('/owner/language-settings'),
                ),
                const Divider(),
                _buildNavigationRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change App PIN',
                  subtitle: 'Set a new 4-digit security PIN',
                  onTap: () => context.push('/owner/change-pin'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p24),

            // ── Logout Button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: AppButton.danger(
                text: 'Logout',
                leadingIcon: Icons.logout,
                onPressed: () async {
                  final ok = await AppConfirmDialog.show(
                    context: context, 
                    title: 'Logout', 
                    message: 'Are you sure you want to sign out?',
                    confirmLabel: 'Logout',
                    isDangerous: true,
                  );
                  if (ok == true) {
                    ref.read(authProvider.notifier).logout();
                  }
                },
              ),
            ),
            const SizedBox(height: AppSizes.p32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

Widget _buildHeaderDetailRow(
  IconData icon,
  String label,
  String value,
  String fieldKey,
) {
  return Row(
    children: [
      Icon(
        icon,
        color: Colors.white.withOpacity(0.85),
        size: 12,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          value.isNotEmpty ? value : 'Not set',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

  Widget _buildEditableRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.textHint, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textHint, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Helper dialogs ──────────────────────────────────────────────────────────

  Future<void> _updateProfileField(String field, dynamic value) async {
    final success = await ref.read(authProvider.notifier).updateProfile({field: value});
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${field.toUpperCase()} updated successfully')),
      );
    }
  }

  void _showEditFieldDialog(BuildContext context, String fieldLabel, String fieldKey, String currentValue) {
    final ctrl = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $fieldLabel'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'Enter new $fieldLabel',
            border: const OutlineInputBorder(),
          ),
          maxLines: fieldKey == 'aboutYou' || fieldKey == 'address' ? 3 : 1,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateProfileField(fieldKey, ctrl.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyContactDialog(BuildContext context, dynamic user) {
    final nameCtrl = TextEditingController(text: user.emergencyContactName ?? '');
    final relCtrl = TextEditingController(text: user.emergencyContactRelationship ?? '');
    final phoneCtrl = TextEditingController(text: user.emergencyContactPhone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: relCtrl,
              decoration: const InputDecoration(labelText: 'Relationship (e.g. Wife)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).updateProfile({
                'emergencyContactName': nameCtrl.text.trim(),
                'emergencyContactRelationship': relCtrl.text.trim(),
                'emergencyContactPhone': phoneCtrl.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
