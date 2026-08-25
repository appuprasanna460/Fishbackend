// lib/features/subscription_plan/presentation/screens/subscription_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/subscription_provider.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  const SubscriptionDetailScreen({super.key});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).loadMySubscription();
    });
  }

  Color get _statusColor {
    final status = ref.watch(subscriptionProvider).subscription?.status ?? '';
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF2ECC71);
      case 'EXPIRING_SOON':
        return const Color(0xFFF39C12);
      case 'EXPIRED':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);
    final sub = state.subscription;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Subscription & Plan',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(subscriptionProvider.notifier).loadMySubscription(),
          ),
        ],
      ),
      body: state.isLoading && sub == null
          ? const Center(child: CircularProgressIndicator())
          : sub == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.subscriptions_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No subscription found',
                          style: GoogleFonts.inter(
                              fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/plan-selection'),
                        child: const Text('Choose a Plan'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(subscriptionProvider.notifier)
                      .loadMySubscription(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Plan Card ──────────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryDark,
                                AppColors.primary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.card_membership_rounded,
                                      color: Colors.white70, size: 18),
                                  const SizedBox(width: 8),
                                  Text('CURRENT PLAN',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white70,
                                          letterSpacing: 1.2)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                sub.planName,
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Price: ₹${sub.planName.toLowerCase().contains("premium") ? "2,999" : "1,999"}',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Cycle: ${sub.planName.toLowerCase().contains("quarter") ? "Quarterly" : "Monthly"}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _statusColor.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: _statusColor.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      sub.status.replaceAll('_', ' '),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${sub.remainingDays} days remaining',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Dates Card ─────────────────────────────────────
                        _DetailCard(
                          title: 'Subscription Details',
                          icon: Icons.calendar_month_rounded,
                          children: [
                            if (sub.startDate != null)
                              _DetailRow(
                                label: 'Start Date',
                                value: _fmtDate(sub.startDate!),
                              ),
                            const SizedBox(height: 12),
                            if (sub.expiryDate != null)
                              _DetailRow(
                                label: 'Valid Until',
                                value: _fmtDate(sub.expiryDate!),
                                valueColor: _statusColor,
                              ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Billing Period',
                              value: sub.durationDays != null ? '${sub.durationDays} Days' : 'Quarterly',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Usage Summary Card ─────────────────────────────
                        // _DetailCard(
                        //   title: 'Usage Summary',
                        //   icon: Icons.pie_chart_outline_rounded,
                        //   children: [
                        //     _buildUsageRow('Boats', 3, 10, 'boats'),
                        //     const SizedBox(height: 16),
                        //     _buildUsageRow('Crew Members', 24, 100, 'members'),
                        //     const SizedBox(height: 16),
                        //     _buildUsageRow('Storage', 12.4, 100.0, 'GB', isDouble: true),
                        //     const SizedBox(height: 16),
                        //     _buildUsageRow('AI Requests', 1248, 10000, 'requests'),
                        //   ],
                        // ),
                        // const SizedBox(height: 16),

                        // ── Pending Renewal ────────────────────────────────
                        if (sub.hasPendingRenewal) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.blue.shade200),
                            ),
                            child: Row(children: [
                              const Icon(Icons.pending_actions_rounded,
                                  color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Renewal Request Pending',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.blue.shade800,
                                        )),
                                    Text(
                                      '${sub.pendingRenewal!.requestedPlanName} (${sub.pendingRenewal!.requestedDurationDays} days)',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.blue.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Actions: Change Plan & Billing History ─────────
                        if (!sub.hasPendingRenewal) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  context.push('/plan-selection'),
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: Text(
                                'Change Plan',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _statusColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // View Billing History row
                        InkWell(
                          onTap: () => context.push('/owner/billing-history'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.history_rounded, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'View Billing History',
                                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textHint, size: 14),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildUsageRow(String label, double current, double total, String unit, {bool isDouble = false}) {
    final percent = (current / total).clamp(0.0, 1.0);
    final valueStr = isDouble 
        ? '${current.toStringAsFixed(1)} $unit / ${total.toStringAsFixed(0)} $unit'
        : '${current.toInt()} / ${total.toInt()}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            Text(valueStr, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(percent > 0.85 ? Colors.red : AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            )),
      ],
    );
  }
}
