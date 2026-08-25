import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BillingHistoryScreen extends ConsumerStatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  ConsumerState<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends ConsumerState<BillingHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBillingHistory();
  }

  Future<void> _fetchBillingHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.dio.get('/api/subscription/billing-history');
      final data = response.data['data'] as List<dynamic>;
      setState(() {
        _history = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _formatDate(String isoString) {
    try {
      final parsed = DateTime.parse(isoString);
      return DateFormat('dd-MMM-yyyy').format(parsed);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Billing History',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Failed to load billing history', style: GoogleFonts.inter(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchBillingHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No billing history found',
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final record = _history[index];
                        final planName = record['requestedPlanName'] as String;
                        final approvedDate = record['approvedAt'] != null 
                            ? _formatDate(record['approvedAt'].toString()) 
                            : _formatDate(record['createdAt'].toString());
                        final planPrice = record['requestedPlanId']?['price'] ?? 1999;

                        return _buildBillingCard(
                          date: approvedDate,
                          plan: planName,
                          amount: '₹$planPrice',
                          status: 'Paid',
                          record: record,
                        );
                      },
                    ),
    );
  }



  Widget _buildBillingCard({
    required String date,
    required String plan,
    required String amount,
    required String status,
    required Map<String, dynamic> record,
    bool isMock = false,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _showBillingDetails(context, record, date, plan, amount, isMock),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(date, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amount, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBillingDetails(
    BuildContext context, 
    Map<String, dynamic> record,
    String date,
    String plan,
    String amount,
    bool isMock,
  ) {
    final String invoice = isMock 
        ? (record['raw']['invoice'] ?? '')
        : 'INV-${date.replaceAll("-", "")}-${record['_id'].toString().substring(record['_id'].toString().length - 4)}';
    
    final String billingPeriod = isMock
        ? record['raw']['billingPeriod']
        : '${record['requestedDurationDays'] ?? 90} Days';

    final double amountRaw = isMock
        ? record['raw']['amountRaw'].toDouble()
        : (record['requestedPlanId']?['price'] ?? 1999).toDouble();

    final String tax = isMock
        ? record['raw']['tax']
        : '₹${(amountRaw * 0.18).toStringAsFixed(2)}';

    final String method = isMock
        ? record['raw']['method']
        : 'UPI / Online Payment';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Billing Details',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Invoice Number', invoice),
            _buildDetailRow('Plan Name', plan),
            _buildDetailRow('Billing Period', billingPeriod),
            _buildDetailRow('Base Amount', '₹${(amountRaw * 0.82).toStringAsFixed(2)}'),
            _buildDetailRow('Tax (18% GST)', tax),
            _buildDetailRow('Total Amount', amount),
            _buildDetailRow('Payment Date', date),
            _buildDetailRow('Payment Status', 'Paid'),
            _buildDetailRow('Payment Method', method),
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading invoice...')),
                  );
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download Invoice PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
