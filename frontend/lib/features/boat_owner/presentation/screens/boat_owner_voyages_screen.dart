import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../domain/entities/voyage_entity.dart';
import '../providers/voyage_provider.dart';
import '../widgets/voyage_card.dart';

class BoatOwnerVoyagesScreen extends ConsumerStatefulWidget {
  const BoatOwnerVoyagesScreen({super.key});

  @override
  ConsumerState<BoatOwnerVoyagesScreen> createState() => _BoatOwnerVoyagesScreenState();
}

class _BoatOwnerVoyagesScreenState extends ConsumerState<BoatOwnerVoyagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isDeleting = false;

  final List<String> _statuses = [
    'ALL',
    'PLANNED', // Upcoming
    'ACTIVE',
    'COMPLETED',
    'CANCELLED'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
      _fetchVoyages();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchVoyages());
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _fetchVoyages();
    }
  }

  void _fetchVoyages() {
    final status = _statuses[_tabController.index];
    ref.read(voyageProvider.notifier).loadVoyages(
          status: status == 'ALL' ? null : status,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
        );
  }

  Future<void> _handleDelete(VoyageEntity voyage) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Voyage'),
        content: Text('Are you sure you want to delete the voyage for ${voyage.boatName ?? "this boat"}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      final success = await ref.read(voyageProvider.notifier).deleteVoyage(voyage.id!);
      setState(() => _isDeleting = false);

      if (success) {
        if (mounted) {
          AppErrorBanner.showSuccess(context, 'Voyage deleted successfully');
          _fetchVoyages();
        }
      } else {
        if (mounted) {
          final error = ref.read(voyageProvider).error ?? 'Failed to delete voyage';
          AppErrorBanner.show(context, error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final voyageState = ref.watch(voyageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voyages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchVoyages,
          ),
        ],
       bottom: TabBar(
  controller: _tabController,
  isScrollable: true,
  tabs: const [
    Tab(text: 'All'),
    Tab(text: 'Upcoming'),
    Tab(text: 'Active'),
    Tab(text: 'Completed'),
    Tab(text: 'Cancelled'),
  ],
  labelColor: Colors.white, // Selected tab text is white
  unselectedLabelColor: Colors.white60, // Unselected tab text is semi-transparent white
  indicatorColor: Colors.white, // Underline indicator is white
  indicatorWeight: 3.0,
  labelStyle: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
  unselectedLabelStyle: const TextStyle(
    fontWeight: FontWeight.normal,
  ),
)
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search voyages by boat name...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),

          // Voyage List
          Expanded(
            child: voyageState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : voyageState.voyages.isEmpty
                    ? const AppEmptyState(
                        title: 'No Voyages Found',
                        subtitle: 'Tap the button below to add your first voyage plan.',
                        icon: Icons.directions_boat_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchVoyages(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                          itemCount: voyageState.voyages.length,
                          itemBuilder: (context, index) {
                            final voyage = voyageState.voyages[index];
                            return VoyageCard(
                              voyage: voyage,
                              onTap: () => context.go('/owner/voyages/${voyage.id}'),
                              onEdit: () => context.go('/owner/voyages/${voyage.id}/edit'),
                              onDelete: () => _handleDelete(voyage),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/owner/voyages/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Voyage',
          style: AppTextStyles.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}