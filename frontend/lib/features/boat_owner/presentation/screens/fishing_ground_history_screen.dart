import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/fishing_ground_provider.dart';

class FishingGroundHistoryScreen extends ConsumerStatefulWidget {
  const FishingGroundHistoryScreen({super.key});

  @override
  ConsumerState<FishingGroundHistoryScreen> createState() => _FishingGroundHistoryScreenState();
}

class _FishingGroundHistoryScreenState extends ConsumerState<FishingGroundHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fishingGroundProvider.notifier).fetchGroundHistory();
      ref.read(fishingGroundProvider.notifier).fetchFishingGrounds();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groundState = ref.watch(fishingGroundProvider);
    final history = groundState.history;
    final allGrounds = groundState.fishingGrounds;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fishing Grounds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(fishingGroundProvider.notifier).fetchGroundHistory();
          await ref.read(fishingGroundProvider.notifier).fetchFishingGrounds();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR LOCATIONS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSizes.p8),

              if (groundState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (allGrounds.isEmpty)
                const AppEmptyState(
                  title: 'No Grounds Recorded',
                  subtitle: 'Fishing grounds will appear here once you start using them in your hauls.',
                  icon: Icons.map_outlined,
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allGrounds.length,
                  itemBuilder: (context, index) {
                    final g = allGrounds[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.p8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(Icons.location_on, color: AppColors.primary),
                        ),
                        title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Used ${g.usedCount} times • Total Catch: ${g.totalCatch.toStringAsFixed(1)} kg'),
                        trailing: IconButton(
                          icon: Icon(
                            g.isFavourite ? Icons.star : Icons.star_border,
                            color: g.isFavourite ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () {
                            ref.read(fishingGroundProvider.notifier).toggleFavourite(g.id!);
                          },
                        ),
                      ),
                    );
                  },
                ),
                
              const SizedBox(height: AppSizes.p32),
              
              Text(
                'RECENT HISTORY',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSizes.p8),

              if (history.isEmpty && !groundState.isLoading)
                const Text('No recent usage history.', style: TextStyle(color: AppColors.textHint))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length > 5 ? 5 : history.length,
                  itemBuilder: (context, index) {
                    final h = history[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history, color: AppColors.textHint),
                      title: Text(h.name),
                      subtitle: Text(
                        h.lastUsedAt != null 
                            ? 'Last visited: ${DateFormat('MMM d, yyyy').format(h.lastUsedAt!)}' 
                            : 'Date unknown',
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
