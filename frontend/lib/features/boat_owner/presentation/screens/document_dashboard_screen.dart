import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/document_providers.dart';
import '../../domain/entities/document_entity.dart';

class DocumentDashboardScreen extends ConsumerStatefulWidget {
  const DocumentDashboardScreen({super.key});

  @override
  ConsumerState<DocumentDashboardScreen> createState() => _DocumentDashboardScreenState();
}

class _DocumentDashboardScreenState extends ConsumerState<DocumentDashboardScreen> {
  final Connectivity _connectivity = Connectivity();
  late Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivityStream = _connectivity.onConnectivityChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentProvider.notifier).fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);
    final summary = state.summary;
    final expiringSoonList = state.expiringSoonList;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Documents',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSizes.p8),
            // Online/Offline Status Indicator
            StreamBuilder<List<ConnectivityResult>>(
              stream: _connectivityStream,
              builder: (context, snapshot) {
                final results = snapshot.data;
                final isOffline = results != null && results.contains(ConnectivityResult.none);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOffline
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOffline ? AppColors.error : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOffline ? 'Offline' : 'Online',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOffline ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(documentProvider.notifier).fetchStats(),
          ),
        ],
      ),
      body: state.isLoading && summary['total'] == 0
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(documentProvider.notifier).fetchStats(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards Grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      childAspectRatio: 1.5,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildSummaryCard(
                          title: 'Total Documents',
                          value: summary['total']?.toString() ?? '0',
                          icon: Icons.folder_copy_rounded,
                          color: AppColors.primary,
                          bgColor: AppColors.primarySurface,
                        ),
                        _buildSummaryCard(
                          title: 'Valid',
                          value: summary['valid']?.toString() ?? '0',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          bgColor: AppColors.successLight,
                        ),
                        _buildSummaryCard(
                          title: 'Expiring Soon',
                          value: summary['expiringSoon']?.toString() ?? '0',
                          icon: Icons.timelapse_rounded,
                          color: AppColors.warning,
                          bgColor: AppColors.warningLight,
                        ),
                        _buildSummaryCard(
                          title: 'Expired',
                          value: summary['expired']?.toString() ?? '0',
                          icon: Icons.error_rounded,
                          color: AppColors.error,
                          bgColor: AppColors.errorLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p24),

                    // Document Categories Section
                    Text(
                      'DOCUMENT CATEGORIES',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildCategoryRow(
                            icon: Icons.directions_boat_filled_rounded,
                            title: 'Boat Documents',
                            subtitle: 'Boat registrations and operation documents',
                            onTap: () => context.push('/owner/documents/list?type=BOAT'),
                          ),
                          const Divider(height: 1, indent: 56, endIndent: 16),
                          _buildCategoryRow(
                            icon: Icons.people_alt_rounded,
                            title: 'Crew Documents',
                            subtitle: 'Crew members ID proofs and verification documents',
                            onTap: () => context.push('/owner/documents/crew'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.p24),

                    // Expiring Soon Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EXPIRING SOON',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        if (expiringSoonList.isNotEmpty)
                          Text(
                            '${expiringSoonList.length} docs',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p10),
                    if (expiringSoonList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.p24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.verified_rounded, size: 40, color: AppColors.success.withOpacity(0.3)),
                            const SizedBox(height: 8),
                            Text(
                              'All documents are secure',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'No documents are expiring within 30 days.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: expiringSoonList.length,
                        itemBuilder: (context, index) {
                          final doc = expiringSoonList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.warningLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                              ),
                              title: Text(
                                doc.documentName,
                                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    'Number: ${doc.documentNumber}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  Text(
                                    'Expires: ${_formatDate(doc.expiryDate)} (${doc.remainingDays} days left)',
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                              onTap: () => context.push('/owner/documents/details/${doc.id}'),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/owner/documents/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: AppTextStyles.metricValueSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
  }
}
