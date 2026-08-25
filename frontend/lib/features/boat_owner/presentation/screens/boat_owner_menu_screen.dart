import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BoatOwnerMenuScreen extends ConsumerWidget {
  const BoatOwnerMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          children: [
            // Profile Summary
            Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Boat Owner',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.phone ?? 'No phone number',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'BOAT OWNER',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p24),
            
            // Menu Items
            _buildMenuSection(
              title: 'MANAGEMENT & OPERATIONS',
              items: [
                _buildMenuItem(
                  context,
                  icon: Icons.directions_boat_outlined,
                  title: 'My Boats',
                  onTap: () => context.push('/owner/management'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.folder_shared_outlined,
                  title: 'Fleet Management',
                  onTap: () => context.push('/owner/fleet'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'Crew Management',
                  onTap: () => context.push('/owner/management'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.folder_open_outlined,
                  title: 'Document Management',
                  onTap: () => context.push('/owner/documents'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Financial Management',
                  onTap: () => context.push('/owner/financial'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.map_outlined,
                  title: 'Fishing Grounds',
                  onTap: () => context.push('/owner/fishing-grounds'),
                ),
                 _buildMenuItem(
                  context,
                  icon: Icons.map_outlined,
                  title: 'GPS Track History',
                  onTap: () => context.push('/owner/gps-tracks'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p24),
            
            // _buildMenuSection(
            //   title: 'OPERATIONS',
            //   items: [
            //     // _buildMenuItem(
            //     //   context,
            //     //   icon: Icons.assignment_outlined,
            //     //   title: 'E-Logbook',
            //     //   onTap: () {
            //     //      ScaffoldMessenger.of(context).showSnackBar(
            //     //         const SnackBar(content: Text('E-Logbook coming soon')),
            //     //       );
            //     //   },
            //     // ),
               
            //     // _buildMenuItem(
            //     //   context,
            //     //   icon: Icons.account_balance_wallet_outlined,
            //     //   title: 'Expenses & Ledger',
            //     //   onTap: () => context.push('/owner/ledger'),
            //     // ),
            //     // _buildMenuItem(
            //     //   context,
            //     //   icon: Icons.receipt_long_outlined,
            //     //   title: 'Bills & Invoices',
            //     //   onTap: () => context.push('/owner/bills'),
            //     // ),
            //   ],
            // ),
            // const SizedBox(height: AppSizes.p24),

            _buildMenuSection(
              title: 'ACCOUNT & SETTINGS',
              items: [
                _buildMenuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile Settings',
                  onTap: () => context.push('/owner/profile'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  title: 'Log Out',
                  isDestructive: true,
                  onTap: () {
                    _showLogoutDialog(context, ref);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index != items.length - 1)
                    const Divider(height: 1, indent: 56, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: color,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isDestructive ? null : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
