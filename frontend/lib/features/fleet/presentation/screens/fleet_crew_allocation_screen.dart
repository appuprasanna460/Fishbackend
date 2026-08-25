import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../boat_owner/presentation/providers/crew_provider.dart';

class FleetCrewAllocationScreen extends ConsumerStatefulWidget {
  const FleetCrewAllocationScreen({super.key});

  @override
  ConsumerState<FleetCrewAllocationScreen> createState() => _FleetCrewAllocationScreenState();
}

class _FleetCrewAllocationScreenState extends ConsumerState<FleetCrewAllocationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(crewProvider.notifier).fetchCrew();
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(boatProvider.notifier).load(ownerId: user.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final crewState = ref.watch(crewProvider);

    final boats = boatState.boats;
    final crew = crewState.crewMembers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fleet Crew Allocation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'By Boat'),
            Tab(text: 'By Crew'),
            Tab(text: 'Availability'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildByBoatTab(boats, crew),
          _buildByCrewTab(crew),
          _buildAvailabilityTab(crew),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: AppButton(
          text: 'Manage Crew List',
          leadingIcon: Icons.people_outline,
          onPressed: () => context.push('/owner/team'),
        ),
      ),
    );
  }

  Widget _buildByBoatTab(List boatsList, List crewList) {
    if (boatsList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.p24),
          child: Text('No boats registered in your fleet.', textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.p16),
      itemCount: boatsList.length,
      itemBuilder: (context, index) {
        final b = boatsList[index];
        final String name = b.boatName;
        // Count crew assigned to this specific boat
        final int assigned = crewList.where((m) => m.assignedTo?.boatId == b.id).length;
        final int capacity = b.capacity ?? 12;

        final double ratio = capacity > 0 ? (assigned / capacity) : 0.0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$assigned / $capacity crew',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: ratio >= 1.0 ? AppColors.error : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  color: ratio >= 1.0 ? AppColors.error : AppColors.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacity status',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      ratio >= 1.0 ? 'Fully Allocated' : 'Open Slots Available',
                      style: AppTextStyles.caption.copyWith(
                        color: ratio >= 1.0 ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildByCrewTab(List crewList) {
    if (crewList.isEmpty) {
      return const Center(child: Text('No crew members found. Use "Manage Crew List" to add.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.p16),
      itemCount: crewList.length,
      itemBuilder: (context, index) {
        final member = crewList[index];
        final String assignedBoat = member.assignedTo != null ? 'Assigned' : 'Unassigned';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.08),
              child: Text(
                member.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            title: Text(member.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('Role: ${member.role} • ${member.phone}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: member.assignedTo != null ? AppColors.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                assignedBoat,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: member.assignedTo != null ? AppColors.success : Colors.orange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailabilityTab(List crewList) {
    final available = crewList.where((m) => m.assignedTo == null).toList();

    if (available.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.p24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
              SizedBox(height: 12),
              Text(
                'All crew members are currently assigned!',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.p16),
      itemCount: available.length,
      itemBuilder: (context, index) {
        final member = available[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.account_circle_outlined, color: Colors.orange, size: 36),
            title: Text(member.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('Role: ${member.role} • Age: ${member.age}'),
            trailing: const Icon(Icons.chevron_right_outlined),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MockBoat {
  final String name;
  final int assigned;
  final int capacity;
  _MockBoat(this.name, this.assigned, this.capacity);
}