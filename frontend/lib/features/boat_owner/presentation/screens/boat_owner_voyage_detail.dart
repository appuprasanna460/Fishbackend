import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/voyage_provider.dart';
import '../providers/voyage_dashboard_provider.dart';
import '../widgets/voyage_status_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';

class BoatOwnerVoyageDetail extends ConsumerStatefulWidget {
  final String voyageId;
  const BoatOwnerVoyageDetail({super.key, required this.voyageId});

  @override
  ConsumerState<BoatOwnerVoyageDetail> createState() => _BoatOwnerVoyageDetailState();
}

class _BoatOwnerVoyageDetailState extends ConsumerState<BoatOwnerVoyageDetail> {
  bool _isTransitioning = false;

  Future<void> _updateStatus(String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${_capitalise(status)} Voyage'),
        content: Text('Are you sure you want to change the voyage status to $status?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  status == 'CANCELLED' ? AppColors.error : AppColors.primary,
            ),
            child: Text(status),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isTransitioning = true);
      final success = await ref
          .read(voyageProvider.notifier)
          .updateVoyageStatus(widget.voyageId, status);
      setState(() => _isTransitioning = false);

      if (mounted) {
        if (success) {
          AppErrorBanner.showSuccess(context, 'Voyage marked as $status');
          ref.read(voyageProvider.notifier).loadVoyageById(widget.voyageId);
          // Reload dashboard data
          final voyage = ref.read(voyageProvider).currentVoyage;
          if (voyage != null) {
            ref.read(voyageDashboardProvider.notifier).load(
                  widget.voyageId,
                  departureDate: voyage.departureDate,
                  expectedDuration: voyage.expectedDuration,
                );
          }
        } else {
          AppErrorBanner.show(
              context,
              ref.read(voyageProvider).error ??
                  'Failed to update voyage status');
        }
      }
    }
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(voyageProvider.notifier).loadVoyageById(widget.voyageId);
      final voyage = ref.read(voyageProvider).currentVoyage;
      if (voyage != null) {
        ref.read(voyageDashboardProvider.notifier).load(
              widget.voyageId,
              departureDate: voyage.departureDate,
              expectedDuration: voyage.expectedDuration,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final voyageState = ref.watch(voyageProvider);
    final dashState = ref.watch(voyageDashboardProvider);
    final voyage = voyageState.currentVoyage;

    if (voyageState.isLoading && voyage == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (voyage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Voyage')),
        body: const Center(child: Text('Voyage not found.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header SliverAppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100, // ✅ Increased to accommodate boat details
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/owner/voyages'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Voyage Dashboard',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${voyage.boatName ?? ''} • ${voyage.boatNumber ?? ''}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 60, bottom: 35), // ✅ Adjusted bottom padding
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.oceanGradient,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 85, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Text('🚢', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  voyage.boatName ?? 'Voyage',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            voyage.boatNumber ?? '',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        VoyageStatusBadge(status: voyage.status),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go('/owner/gps-tracks/voyage/${voyage.id}'),
                          icon: const Icon(Icons.map_outlined, size: 14, color: Colors.white),
                          label: const Text('View Map',
                              style: TextStyle(fontSize: 12, color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Voyage Status Cards ────────────────────────────────────
                _buildSectionLabel('📊 VOYAGE STATUS'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatCard(
                      '📅 Day',
                      '${dashState.currentDay} / ${dashState.totalDays}',
                      AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      '⏱ Total',
                      '${dashState.totalHours} Hrs',
                      AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      '📍 Dist',
                      '${dashState.totalDistanceNm.toStringAsFixed(1)} NM',
                      AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Quick Actions ──────────────────────────────────────────
                _buildSectionLabel('⚓ QUICK ACTIONS'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.05,
                  children: [
                    _buildQuickAction(context, '📋', 'Entry',
                        '/owner/voyages/${widget.voyageId}/entry', AppColors.primarySurface),
                    _buildQuickAction(context, '📖', 'Logbook',
                        '/owner/voyages/${widget.voyageId}/checklist', const Color(0xFFE8F5E9)),
                    _buildQuickAction(context, '📊', 'Logs',
                        '/owner/voyages/${widget.voyageId}/logbook', const Color(0xFFEDE7F6)),
                    _buildQuickAction(context, '🐟', 'Catch',
                        '/owner/voyages/${widget.voyageId}/catch', const Color(0xFFE3F2FD)),
                    _buildQuickAction(context, '💰', 'Expense',
                        '/owner/voyages/${widget.voyageId}/expenses', const Color(0xFFFFF8E1)),
                    _buildQuickAction(context, '📈', 'Summary',
                        '/owner/voyages/${widget.voyageId}/summary', const Color(0xFFFCE4EC)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Today's Summary ────────────────────────────────────────
                _buildSectionLabel("📋 TODAY'S SUMMARY"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        'Hauls Completed',
                        '${dashState.completedHauls}',
                        'Total Catch',
                        '${dashState.totalCatchKg.toStringAsFixed(0)} Kg',
                      ),
                      const Divider(height: 16),
                      _buildSummaryRow(
                        'Fuel Used',
                        '${dashState.todayFuelUsed.toStringAsFixed(0)} L',
                        'Ice Used',
                        '${dashState.todayIceUsed.toStringAsFixed(0)} Kg',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Recent Activity ────────────────────────────────────────
                _buildSectionLabel('🕐 RECENT ACTIVITY'),
                const SizedBox(height: 8),
                if (dashState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (dashState.recentActivity.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'No activity yet for this voyage',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dashState.recentActivity.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 52,
                      ),
                      itemBuilder: (context, i) {
                        final event = dashState.recentActivity[i];

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          minVerticalPadding: 0,
                          visualDensity: const VisualDensity(
                            horizontal: 0,
                            vertical: -2,
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.access_time,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            event.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            event.time +
                                (event.subtitle != null ? '  •  ${event.subtitle}' : ''),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                if (!_isTransitioning) ...[
                  if (voyage.status == 'PLANNED') ...[
                    AppButton(
                      text: 'Start Voyage',
                      onPressed: () => _updateStatus('ACTIVE'),
                      backgroundColor: AppColors.success,
                      leadingIcon: Icons.play_arrow,
                    ),
                  ] else if (voyage.status == 'ACTIVE') ...[
                    AppButton(
                      text: 'Complete Voyage',
                      onPressed: () => _updateStatus('COMPLETED'),
                      backgroundColor: AppColors.primary,
                      leadingIcon: Icons.stop,
                    ),
                  ],
                ] else
                  const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
      BuildContext context, String emoji, String label, String route, Color bg) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String lLabel, String lValue, String rLabel, String rValue) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lLabel,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text(lValue,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const VerticalDivider(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rLabel,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text(rValue,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}