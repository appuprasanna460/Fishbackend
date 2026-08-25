import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_text_styles.dart';
import '/core/theme/app_sizes.dart';
import '/core/widgets/app_status_badge.dart';
import '/features/fish_buyer/presentation/providers/fish_buyer_bill_provider.dart';

class AgentFishBuyerBillsScreen extends ConsumerStatefulWidget {
  const AgentFishBuyerBillsScreen({super.key});

  @override
  ConsumerState<AgentFishBuyerBillsScreen> createState() =>
      _AgentFishBuyerBillsScreenState();
}

class _AgentFishBuyerBillsScreenState
    extends ConsumerState<AgentFishBuyerBillsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fishBuyerBillProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fishBuyerBillProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fish Buyer Bills')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.bills.isEmpty
          ? _EmptyState()
          : RefreshIndicator(
              onRefresh: () => ref.read(fishBuyerBillProvider.notifier).load(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.p16),
                itemCount: state.bills.length,
                itemBuilder: (_, i) => _BillCard(bill: state.bills[i]),
              ),
            ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final billNumber = bill['billNumber'] ?? 'FBB-????';
    final agentName = bill['agentId'] is Map
        ? (bill['agentId'] as Map)['name'] ?? ''
        : '';
    final buyerName = bill['buyerId'] is Map
        ? (bill['buyerId'] as Map)['name'] ?? ''
        : '';
    final fishName = bill['fishName'] ?? '';
    final weight = (bill['weightKg'] ?? 0).toString();
    final total = (bill['totalAmount'] ?? 0).toDouble();
    final status = bill['status'] ?? 'CONFIRMED';
    final date = bill['billDate'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(bill['billDate']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.roleBuyer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
                child: Icon(
                  Icons.shopping_cart,
                  color: AppColors.roleBuyer,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      billNumber,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              AppStatusBadge.fromString(status),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          if (agentName.isNotEmpty)
            _InfoRow(icon: Icons.person, label: 'Agent: $agentName'),
          if (buyerName.isNotEmpty)
            _InfoRow(icon: Icons.storefront, label: 'Buyer: $buyerName'),
          if (fishName.isNotEmpty)
            _InfoRow(icon: Icons.set_meal, label: 'Fish: $fishName'),
          _InfoRow(icon: Icons.monitor_weight, label: 'Weight: $weight KG'),
          const Divider(height: AppSizes.p16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₹ ${total.toStringAsFixed(2)}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.roleBuyer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSizes.p12),
            Text(
              'No fish buyer bills yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
