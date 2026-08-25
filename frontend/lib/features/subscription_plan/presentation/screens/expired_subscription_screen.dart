// lib/features/subscription_plan/presentation/screens/expired_subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ExpiredSubscriptionScreen extends ConsumerWidget {
  const ExpiredSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFE74C3C).withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  Icons.subscriptions_outlined,
                  size: 56,
                  color: Color(0xFFE74C3C),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Subscription Expired',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFE74C3C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your subscription has expired. Please request a renewal to continue using Harbour Pro.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF555555),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Renew CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/plan-selection'),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'Request Renewal',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // View subscription details
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/subscription-detail'),
                  icon: const Icon(Icons.info_outline_rounded),
                  label: Text(
                    'View Subscription Details',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: BorderSide(
                        color: AppColors.primaryDark.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Logout
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                child: Text(
                  'Sign out',
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
