import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isVerified = user.companyIsVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Company Profile'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Company Header Card ───────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p28),
              child: Column(
                children: [
                  // Company Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.business_rounded,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  // Company Name
                  Text(
                    user.companyName ?? 'Fishing Company',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Row of stats
                  
                  // Verification Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isVerified ? AppColors.success.withOpacity(0.2) : AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isVerified ? AppColors.success : AppColors.warning,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                          color: isVerified ? AppColors.success : AppColors.warning,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p16),

            // ── Company Info Details ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              child: Column(
                children: [
                  Container(
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
                          'COMPANY INFORMATION',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                       
                        const Divider(height: 20),
                        _buildDetailRow('Registered Harbour', user.companyRegisteredHarbour ?? 'Nagapattinam Harbour'),
                    
                        const Divider(height: 20),
                        _buildMultilineDetailRow('Registered Address', user.companyRegisteredAddress ?? 'Nagapattinam, Tamil Nadu'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Edit Company Details Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Edit Company Details',
                      leadingIcon: Icons.edit_note_rounded,
                      onPressed: () => _showEditCompanyDialog(context, user),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMultilineDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, height: 1.4),
        ),
      ],
    );
  }

  void _showEditCompanyDialog(BuildContext context, dynamic user) {
    final nameCtrl = TextEditingController(text: user.companyName ?? '');
    final typeCtrl = TextEditingController(text: user.companyType ?? 'Sole Proprietorship');
    final harbourCtrl = TextEditingController(text: user.companyRegisteredHarbour ?? '');
    final gstCtrl = TextEditingController(text: user.companyGstNumber ?? '');
    final panCtrl = TextEditingController(text: user.companyPanNumber ?? '');
    final phoneCtrl = TextEditingController(text: user.companyPhone ?? '');
    final emailCtrl = TextEditingController(text: user.companyEmail ?? '');
    final addrCtrl = TextEditingController(text: user.companyRegisteredAddress ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Company Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Company Name')),
              const SizedBox(height: 8),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Company Type')),
              const SizedBox(height: 8),
              TextField(controller: harbourCtrl, decoration: const InputDecoration(labelText: 'Registered Harbour')),
              const SizedBox(height: 8),
              TextField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GST Number')),
              const SizedBox(height: 8),
              TextField(controller: panCtrl, decoration: const InputDecoration(labelText: 'PAN Number')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Company Phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Company Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 8),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Registered Address'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(authProvider.notifier).updateProfile({
                'companyName': nameCtrl.text.trim(),
                'companyType': typeCtrl.text.trim(),
                'companyRegisteredHarbour': harbourCtrl.text.trim(),
                'companyGstNumber': gstCtrl.text.trim(),
                'companyPanNumber': panCtrl.text.trim(),
                'companyPhone': phoneCtrl.text.trim(),
                'companyEmail': emailCtrl.text.trim(),
                'companyRegisteredAddress': addrCtrl.text.trim(),
              });
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Company details updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
