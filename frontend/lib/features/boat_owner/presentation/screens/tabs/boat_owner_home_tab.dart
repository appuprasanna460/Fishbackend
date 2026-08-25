import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../providers/voyage_provider.dart';
import '../../providers/haul_provider.dart';
import '../../widgets/quick_action_card.dart';

class BoatOwnerHomeTab extends ConsumerStatefulWidget {
  const BoatOwnerHomeTab({super.key});

  @override
  ConsumerState<BoatOwnerHomeTab> createState() => _BoatOwnerHomeTabState();
}

/// One metric in the grouped "Today at a Glance" strip.
/// No longer its own boxed card — it lives inside a single shared
/// container in _buildMetricsRow, separated by thin dividers, so the
/// whole row reads as ONE element instead of three stacked cards.
class _DashboardMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p12, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BoatOwnerHomeTabState extends ConsumerState<BoatOwnerHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voyageProvider.notifier).loadStats();
      ref.read(haulProvider.notifier).fetchRecentHauls();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(voyageProvider.notifier).loadStats();
    await ref.read(haulProvider.notifier).fetchRecentHauls();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final voyageState = ref.watch(voyageProvider);
    final haulState = ref.watch(haulProvider);
    final formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(context, user),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.p16,
                    AppSizes.p20,
                    AppSizes.p16,
                    AppSizes.p16,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateRow(formattedDate),
                      const SizedBox(height: AppSizes.p20),

                      _buildMetricsRow(voyageState),
                      const SizedBox(height: AppSizes.p24),

                      _buildQuickActionsSection(),
                      const SizedBox(height: AppSizes.p24),

                      if (haulState.recentHauls.isNotEmpty) ...[
                        _buildRecentActivity(haulState),
                        const SizedBox(height: AppSizes.p24),
                      ],

                      _buildWeatherCard(),
                      const SizedBox(height: AppSizes.p24),

                      _buildAlertsSection(),
                      const SizedBox(height: AppSizes.p16),
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

  Widget _buildHeroHeader(BuildContext context, user) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(AppSizes.p20, topPadding + AppSizes.p8, AppSizes.p16, 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF1A73E8),
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8,
            bottom: -24,
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                'assets/dashboard.png',
                width: 140,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.directions_boat_filled_rounded,
                  size: 72,
                  color: Colors.white24,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HARBOUR PRO',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome, ${user?.name ?? "Boatowner"}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Stay safe, stay informed.',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Smaller, tighter tap target — minimal iOS-style icon button
              // instead of the default oversized Material IconButton.
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications coming soon')),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Plain, unboxed date row — text + icon only, no card/shadow.
  // Reads as a minimal section label rather than another stacked card.
  Widget _buildDateRow(String formattedDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          formattedDate,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 16),
      ],
    );
  }

  // All three metrics inside ONE rounded container with thin dividers,
  // instead of three separately-shadowed boxes.
  Widget _buildMetricsRow(voyageState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _DashboardMetric(
            label: 'Active Voyages',
            value: '${voyageState.activeVoyagesCount}',
            icon: Icons.directions_boat_outlined,
            color: const Color(0xFF1A73E8),
          ),
          Container(width: 1, height: 44, color: AppColors.border.withOpacity(0.5)),
          _DashboardMetric(
            label: 'Boats at Sea',
            value: '${voyageState.boatsAtSeaCount}',
            icon: Icons.waves_outlined,
            color: const Color(0xFF00B4D8),
          ),
          Container(width: 1, height: 44, color: AppColors.border.withOpacity(0.5)),
          _DashboardMetric(
            label: "Today's Sales",
            value: '₹${NumberFormat.compact().format(voyageState.todaySales)}',
            icon: Icons.monetization_on_outlined,
            color: const Color(0xFF2ECC71),
          ),
        ],
      ),
    );
  }

  // Trimmed to 5 single-word actions so labels never wrap to a second
  // line — that was what caused the misaligned look before.
  Widget _buildQuickActionsSection() {
    final actions = [
      {'icon': Icons.add_road, 'label': 'Voyage', 'color': const Color(0xFF1A73E8)},
      {'icon': Icons.set_meal_outlined, 'label': 'Catch', 'color': const Color(0xFF00B4D8)},
      {'icon': Icons.account_balance_wallet_outlined, 'label': 'Expense', 'color': const Color(0xFFF39C12)},
      {'icon': Icons.local_gas_station_outlined, 'label': 'Log', 'color': const Color(0xFF9B59B6)},
      {'icon': Icons.people_outline, 'label': 'Crew', 'color': const Color(0xFF2ECC71)},
    ];

    final routes = <String>[
      '/owner/voyages/new',
      '/owner/fishing',
      '/owner/ledger',
      '/owner/fuel-log',
      '/owner/management',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(actions.length, (index) {
              final action = actions[index];
              return _buildQuickActionItem(
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: () => context.push(routes[index]),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Recent hauls now share ONE container with thin dividers between rows —
  // an iOS-style grouped list instead of a shadowed card per haul.
  Widget _buildRecentActivity(haulState) {
    final hauls = haulState.recentHauls.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Fishing Activity',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(hauls.length, (index) {
              final haul = hauls[index];
              final isLast = index == hauls.length - 1;
              final statusColor = haul.status == 'ACTIVE'
                  ? Colors.blue
                  : (haul.status == 'STOPPED' ? Colors.orange : Colors.green);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.35))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.set_meal, color: AppColors.primary, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Haul #${haul.haulNumber}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${haul.fishingGround} • ${DateFormat('MMM d, h:mm a').format(haul.startedAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        haul.status,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: statusColor.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF00B4D8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '29°',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.wb_cloudy_rounded, color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Partly Cloudy',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Text('Wind: 18 km/h', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                  Text('Humidity: 78%', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: Colors.white24,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF39C12), size: 17),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Weather Warning',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Storm approaching Chennai coast.',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.5),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Weather details coming soon')),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    final alerts = [
      {
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFF39C12),
        'title': 'Weather Warning',
        'message': 'Storm approaching Chennai coast.',
        'time': '10m ago',
        'unread': true,
      },
      {
        'icon': Icons.chat_bubble_outline_rounded,
        'color': AppColors.primary,
        'title': 'New Message',
        'message': 'New message from Commission Agent.',
        'time': '1h ago',
        'unread': true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alerts & Notifications',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon')),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(alerts.length, (index) {
              final alert = alerts[index];
              final isLast = index == alerts.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.35))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (alert['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(alert['icon'] as IconData, color: alert['color'] as Color, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['title'] as String,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alert['message'] as String,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          alert['time'] as String,
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint),
                        ),
                        const SizedBox(height: 6),
                        if (alert['unread'] == true)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: alert['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}