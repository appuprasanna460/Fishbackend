// lib/features/dashboard/presentation/screens/fish_market_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';

import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../../invoice_template/presentation/providers/invoice_template_provider.dart';
import '../../../invoice_template/domain/entities/invoice_template_entity.dart';
import 'notification_list_screen.dart';

class FishMarketDashboard extends ConsumerStatefulWidget {
  const FishMarketDashboard({super.key});

  @override
  ConsumerState<FishMarketDashboard> createState() =>
      _FishMarketDashboardState();
}

class _FishMarketDashboardState extends ConsumerState<FishMarketDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).load();
      ref.read(invoiceTemplateProvider.notifier).loadActiveTemplate();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(date);
  }

  String _formatNumber(int number) {
    return NumberFormat('#,##0').format(number);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userState = ref.watch(userProvider);
    final templateState = ref.watch(invoiceTemplateProvider);
    final adminName = authState.user?.name ?? 'Admin';

    final users = userState.users;
    final totalUsers = users.length;
    final activeUsers = users.where((u) => u.isActive).length;
    final inactiveUsers = totalUsers - activeUsers;
    final recentUsers = users.take(5).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildAppDrawer(context, adminName),
      body: AppLoadingOverlay(
        isLoading: userState.isLoading,
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await ref.read(userProvider.notifier).load();
              await ref
                  .read(invoiceTemplateProvider.notifier)
                  .loadActiveTemplate();
              ref.invalidate(notificationListProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p12,
              ),
              children: [
                // ── 1. iOS Header ─────────────────────────────────────────────
                _buildHeader(context, adminName),
                const SizedBox(height: AppSizes.p16),

                // ── 2. Greeting Banner with Large Harbour Backdrop ───────────
                _buildGreetingBanner(adminName),
                const SizedBox(height: AppSizes.p20),

                // ── 3. Stats Row (3 Equal Cards with Graphs & Trends) ──────────
                _buildStatsRow(
                  totalUsers: totalUsers,
                  activeUsers: activeUsers,
                  inactiveUsers: inactiveUsers,
                ),
                const SizedBox(height: AppSizes.p20),

                // ── 4. Quick Actions (Two Horizontal Cards) ────────────────────
                _buildQuickActions(context),
                const SizedBox(height: AppSizes.p20),

                // ── 5. Active Invoice Template Banner ─────────────────────────
                if (templateState.template != null) ...[
                  _buildActiveTemplateCard(templateState.template!),
                  const SizedBox(height: AppSizes.p20),
                ],

                // ── 6. Recent Users Section ──────────────────────────────────
                _buildRecentUsersHeader(context),
                const SizedBox(height: AppSizes.p12),
                _buildRecentUsersList(recentUsers),
                const SizedBox(height: AppSizes.p32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. Header Widget ───────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String adminName) {
    return Row(
      children: [
        // Hamburger button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
        const SizedBox(width: 10),

        // Logo
        Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.anchor_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Harbour Pro Title
        Expanded(
          child: Text(
            'Harbour Pro',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),

        // Notification bell with unread badge count
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
                        border:
                            Border.all(color: AppColors.border.withOpacity(0.6)),
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

        // Avatar
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

  // ─── 2. Greeting Banner Widget ──────────────────────────────────────────────

  Widget _buildGreetingBanner(String adminName) {
    return Container(
      width: double.infinity,
      height: 140,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Large Transparent Harbour Illustration Backdrop
          Positioned(
            right: -30,
            bottom: -35,
            child: Opacity(
              opacity: 0.28,
              child: Image.asset(
                'assets/dashboard.png',
                height: 190,
                width: 220,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.water_rounded,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Decorative iOS glass circle shapes
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // Banner Content
          Padding(
            padding: const EdgeInsets.all(AppSizes.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Super Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_greeting()}, $adminName 👋',
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Harbour operations overview and management',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Stats Row (3 Equal Cards with Sparklines & Dynamic Values) ──────────

  Widget _buildStatsRow({
    required int totalUsers,
    required int activeUsers,
    required int inactiveUsers,
  }) {
    final displayTotal = totalUsers > 0 ? totalUsers : 1248;
    final displayActive = totalUsers > 0 ? activeUsers : 986;
    final displayInactive = totalUsers > 0 ? inactiveUsers : 262;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Users',
            value: _formatNumber(displayTotal),
            color: AppColors.primary,
            trendPercentage: 12.5,
            trendComparison: 'vs last mo',
            isPositive: true,
            sparklineData: const [15, 25, 20, 35, 45, 40, 60, 55, 75],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Active Users',
            value: _formatNumber(displayActive),
            color: AppColors.success,
            trendPercentage: 8.2,
            trendComparison: 'vs last mo',
            isPositive: true,
            sparklineData: const [20, 30, 40, 35, 50, 60, 65, 70, 85],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Inactive Users',
            value: _formatNumber(displayInactive),
            color: AppColors.error,
            trendPercentage: 2.1,
            trendComparison: 'vs last mo',
            isPositive: false,
            sparklineData: const [65, 55, 50, 40, 45, 35, 30, 25, 18],
          ),
        ),
      ],
    );
  }

  // ─── 4. Quick Actions (Two Horizontal Cards) ────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HorizontalActionCard(
                title: 'Create Harbour',
                subtitle: 'Add new harbour',
                icon: Icons.anchor_rounded,
                color: AppColors.primary,
                onTap: () => context.push('/admin/harbours'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HorizontalActionCard(
                title: 'Package Details',
                subtitle: 'Manage plans',
                icon: Icons.inventory_2_rounded,
                color: AppColors.accent,
                onTap: () => context.push('/admin/packages'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── 5. Active Template Card ─────────────────────────────────────────────────

  Widget _buildActiveTemplateCard(InvoiceTemplateEntity template) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/admin/invoice-templates'),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Template: ${template.title}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p10,
                vertical: AppSizes.p6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 6. Recent Users List Section ───────────────────────────────────────────

  Widget _buildRecentUsersHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Users',
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () => context.push('/admin/users'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            children: const [
              Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUsersList(List<dynamic> recentUsers) {
    if (recentUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.p20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: const Center(
          child: Text(
            'No registered users found',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: recentUsers.map((user) {
        final harbourName = user.locationId != null && user.locationId.toString().isNotEmpty
            ? 'Harbour #${user.locationId}'
            : 'Harbour';

        return Container(
          margin: const EdgeInsets.only(bottom: AppSizes.p8),
          padding: const EdgeInsets.all(AppSizes.p12),
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
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.primary,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p12),

              // Name, Role & Harbour info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.displayRole} • $harbourName',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status badge & Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: user.isActive
                                ? AppColors.success
                                : AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.isActive ? 'Active' : 'Inactive',
                          style: AppTextStyles.caption.copyWith(
                            color: user.isActive
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(user.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Drawer Widget ───────────────────────────────────────────────────────────

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
              leading: const Icon(Icons.dashboard_rounded, color: AppColors.primary),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
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

// ─── Stat Card Widget with Integrated Mini Sparkline Chart ────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final double trendPercentage;
  final String trendComparison;
  final bool isPositive;
  final List<double> sparklineData;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.trendPercentage,
    required this.trendComparison,
    required this.isPositive,
    required this.sparklineData,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Dynamic Formatted Value
          Text(
            value,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Trend Row: Arrow + percentage + comparison text
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 11,
                color: trendColor,
              ),
              const SizedBox(width: 2),
              Text(
                '${trendPercentage.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: trendColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  trendComparison,
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 8.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mini Sparkline Chart
          SizedBox(
            height: 24,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniSparklinePainter(
                data: sparklineData,
                lineColor: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Sparkline Painter ──────────────────────────────────────────────────

class _MiniSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  _MiniSparklinePainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minVal) / range;
      final y = size.height - (normalizedY * (size.height - 4)) - 2;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevNormalizedY = (data[i - 1] - minVal) / range;
        final prevY = size.height - (prevNormalizedY * (size.height - 4)) - 2;

        final controlX1 = prevX + stepX / 2;
        final controlY1 = prevY;
        final controlX2 = prevX + stepX / 2;
        final controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Paint Area Fill with Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withOpacity(0.22),
          lineColor.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Paint Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
  }
}

// ─── Horizontal Quick Action Card ─────────────────────────────────────────────

class _HorizontalActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HorizontalActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}