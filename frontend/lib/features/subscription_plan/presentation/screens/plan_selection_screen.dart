// lib/features/subscription_plan/presentation/screens/plan_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../providers/subscription_provider.dart';

class PlanSelectionScreen extends ConsumerStatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  ConsumerState<PlanSelectionScreen> createState() =>
      _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends ConsumerState<PlanSelectionScreen> {
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).loadActivePlans();
      ref.read(subscriptionProvider.notifier).loadMySubscription();
    });
  }

  Future<void> _submitPlanChange() async {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan to continue')),
      );
      return;
    }

    final ok = await ref
        .read(subscriptionProvider.notifier)
        .submitRenewalRequest(_selectedPlanId!);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Plan change request submitted successfully!'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
      context.pop();
    } else {
      final error = ref.read(subscriptionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to submit plan change request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);
    final plans = state.activePlans;
    final sub = state.subscription;
    final hasPending = sub?.hasPendingRenewal ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Change Plan',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: state.isLoading && plans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : plans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.subscriptions_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No active plans available',
                          style: GoogleFonts.inter(color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Pending Banner
                    if (hasPending)
                      Container(
                        width: double.infinity,
                        color: Colors.amber.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pending Approval: You already have a plan change request pending. Select another plan if you wish to override.',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            'Select a plan created by Super Admin to request a change',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...plans.map((plan) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _PlanCard(
                                  plan: plan,
                                  isSelected: _selectedPlanId == plan.id,
                                  onTap: () => setState(
                                      () => _selectedPlanId = plan.id),
                                ),
                              )),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: state.isSubmitting ? null : _submitPlanChange,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: state.isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Request Plan Change',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanEntity plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard(
      {required this.plan, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? AppColors.primary : Colors.grey.shade300;
    final bgColor = isSelected
        ? AppColors.primary.withOpacity(0.04)
        : Colors.white;

    // Deduce limits based on price/plan name for clean presentation
    final isPremium = plan.name.toLowerCase().contains('premium') || plan.price > 2000;
    final boats = isPremium ? 10 : 5;
    final crew = isPremium ? 100 : 50;
    final storage = isPremium ? '100 GB' : '50 GB';
    final aiRequests = isPremium ? '10,000' : '5,000';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.durationLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  plan.priceLabel,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Limits
            _buildLimitRow(Icons.sailing_rounded, 'Boats limit', '$boats boats'),
            const SizedBox(height: 8),
            _buildLimitRow(Icons.people_rounded, 'Crew limit', '$crew members'),
            const SizedBox(height: 8),
            _buildLimitRow(Icons.cloud_outlined, 'Storage limit', storage),
            const SizedBox(height: 8),
            _buildLimitRow(Icons.psychology_outlined, 'AI requests', aiRequests),
            const Divider(height: 24),
            // Features
            if (plan.features.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plan.features.map((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    f,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Select button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isSelected ? Colors.white : AppColors.primary,
                  backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(isSelected ? 'Selected' : 'Select Plan', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
