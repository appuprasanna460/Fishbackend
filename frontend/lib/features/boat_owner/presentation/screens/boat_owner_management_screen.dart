import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../fish/presentation/screens/fish_list_screen.dart';
import '../providers/crew_provider.dart';
import '../providers/management_provider.dart';
import '../../domain/entities/crew_entity.dart';
import 'boat_owner_boats.dart';
import '../widgets/crew_card.dart';

class BoatOwnerManagementScreen extends ConsumerStatefulWidget {
  const BoatOwnerManagementScreen({super.key});

  @override
  ConsumerState<BoatOwnerManagementScreen> createState() => _BoatOwnerManagementScreenState();
}

class _BoatOwnerManagementScreenState extends ConsumerState<BoatOwnerManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Crew filtering states
  final TextEditingController _crewSearchCtrl = TextEditingController();
  String _crewSearch = '';
  String _roleFilter = 'ALL'; // ALL / CAPTAIN / CREW
  String _availFilter = 'ALL'; // ALL / AVAILABLE / ON_VOYAGE

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(managementTabProvider);
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialTab);
    _tabController.addListener(_handleTabChange);
    _crewSearchCtrl.addListener(() {
      setState(() {
        _crewSearch = _crewSearchCtrl.text.trim();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(crewProvider.notifier).fetchCrew();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _crewSearchCtrl.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      ref.read(managementTabProvider.notifier).switchTab(_tabController.index);
    }
  }

  void _confirmDeleteCrew(CrewEntity crew) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Crew Member'),
        content: Text('Are you sure you want to delete ${crew.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(crewProvider.notifier).deleteCrew(crew.id!);
      if (success) {
        if (mounted) {
          AppErrorBanner.showSuccess(context, 'Crew member deleted');
        }
      } else {
        if (mounted) {
          final error = ref.read(crewProvider).error ?? 'Failed to delete crew member';
          AppErrorBanner.show(context, error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch tab provider so we sync if updated externally
    ref.listen<int>(managementTabProvider, (prev, next) {
      if (next != _tabController.index) {
        _tabController.animateTo(next);
      }
    });

    final activeTab = ref.watch(managementTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/owner/dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'BOATS'),
            Tab(text: 'CREW'),
            Tab(text: 'FISH'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Boats
          const BoatOwnerBoatsScreen(isEmbedded: true),

          // TAB 2: Crew
          _buildCrewTab(),

          // TAB 3: Fish
          const FishListScreen(isEmbedded: true),
        ],
      ),
      floatingActionButton: activeTab == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/owner/management/crew/add'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add Crew',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCrewTab() {
    final crewState = ref.watch(crewProvider);

    // Apply filtering client-side
    var filteredCrew = crewState.crewMembers;

    if (_crewSearch.isNotEmpty) {
      filteredCrew = filteredCrew
          .where((c) => c.name.toLowerCase().contains(_crewSearch.toLowerCase()))
          .toList();
    }

    if (_roleFilter != 'ALL') {
      filteredCrew = filteredCrew
          .where((c) => c.role.toUpperCase() == _roleFilter.toUpperCase())
          .toList();
    }

    if (_availFilter != 'ALL') {
      final targetAvail = _availFilter == 'AVAILABLE';
      filteredCrew = filteredCrew.where((c) => c.isAvailable == targetAvail).toList();
    }

    return Column(
      children: [
        // Filters section
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _crewSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search crew by name...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                  suffixIcon: _crewSearch.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _crewSearchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p12),

              // Filter chips / dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _roleFilter,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Roles')),
                        DropdownMenuItem(value: 'CAPTAIN', child: Text('Captains')),
                        DropdownMenuItem(value: 'CREW', child: Text('Crew')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _roleFilter = val);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.p12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _availFilter,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'AVAILABLE', child: Text('Available')),
                        DropdownMenuItem(value: 'ON_VOYAGE', child: Text('On Voyage')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _availFilter = val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: crewState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredCrew.isEmpty
                  ? const AppEmptyState(
                      title: 'No Crew Found',
                      subtitle: 'Add new crew members to list them here.',
                      icon: Icons.people_outline,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(crewProvider.notifier).fetchCrew();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.p16),
                        itemCount: filteredCrew.length,
                        itemBuilder: (context, index) {
                          final member = filteredCrew[index];
                          return CrewCard(
                            crew: member,
                            onEdit: () => context.push('/owner/management/crew/edit/${member.id}'),
                            onDelete: () => _confirmDeleteCrew(member),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
