import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/voyage_provider.dart';
import '../providers/haul_provider.dart';
import '../../domain/entities/voyage_entity.dart';
import '../../domain/entities/haul_entity.dart';

class BoatOwnerFishingScreen extends ConsumerStatefulWidget {
  const BoatOwnerFishingScreen({super.key});

  @override
  ConsumerState<BoatOwnerFishingScreen> createState() => _BoatOwnerFishingScreenState();
}

class _BoatOwnerFishingScreenState extends ConsumerState<BoatOwnerFishingScreen> {
  String? _selectedVoyageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Load all voyages
    await ref.read(voyageProvider.notifier).loadVoyages();
    
    final voyages = ref.read(voyageProvider).voyages;
    
    // Auto-select an active voyage if none is selected, or fallback to the first available
    if (voyages.isNotEmpty) {
      if (_selectedVoyageId == null || !voyages.any((v) => v.id == _selectedVoyageId)) {
        setState(() {
          _selectedVoyageId = voyages.where((v) => v.status == 'ACTIVE').firstOrNull?.id ?? voyages.first.id;
        });
      }
    } else {
      setState(() {
        _selectedVoyageId = null;
      });
    }
    
    final selectedVoyage = voyages.where((v) => v.id == _selectedVoyageId).firstOrNull;
    if (selectedVoyage != null && selectedVoyage.status == 'ACTIVE') {
      await ref.read(haulProvider.notifier).fetchActiveHaul(selectedVoyage.id!);
      await ref.read(haulProvider.notifier).fetchHauls(voyageId: selectedVoyage.id!); 
    }
  }

  Future<void> _onVoyageSelected(String? voyageId) async {
    if (voyageId == null) return;
    setState(() {
      _selectedVoyageId = voyageId;
    });
    
    final voyages = ref.read(voyageProvider).voyages;
    final voyage = voyages.where((v) => v.id == voyageId).firstOrNull;
    
    if (voyage != null && voyage.status == 'ACTIVE') {
      await ref.read(haulProvider.notifier).fetchActiveHaul(voyage.id!);
      await ref.read(haulProvider.notifier).fetchHauls(voyageId: voyage.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voyageState = ref.watch(voyageProvider);
    final haulState = ref.watch(haulProvider);

    final selectedVoyage = voyageState.voyages.where((v) => v.id == _selectedVoyageId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fishing Operations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (voyageState.isLoading && voyageState.voyages.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (voyageState.voyages.isEmpty)
                _buildNoVoyages()
              else ...[
                _buildVoyageSelector(voyageState.voyages),
                const SizedBox(height: AppSizes.p24),
                
                if (selectedVoyage != null) ...[
                  if (selectedVoyage.status == 'ACTIVE')
                    if (haulState.isLoading && haulState.hauls.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildActiveVoyageOperations(selectedVoyage, haulState)
                  else if (selectedVoyage.status == 'PLANNED')
                    _buildPlannedVoyage(selectedVoyage)
                  else if (selectedVoyage.status == 'COMPLETED')
                    _buildCompletedVoyage(selectedVoyage, haulState)
                  else
                    _buildCancelledVoyage(selectedVoyage)
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoyageSelector(List<VoyageEntity> voyages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedVoyageId,
          isExpanded: true,
          hint: const Text('Select a Voyage'),
          items: voyages.map((voyage) {
            return DropdownMenuItem<String>(
              value: voyage.id,
              child: Row(
                children: [
                  Icon(
                    Icons.directions_boat,
                    color: voyage.status == 'ACTIVE' ? AppColors.primary : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${voyage.boatName ?? 'Unknown Boat'} - ${DateFormat('MMM d').format(voyage.departureDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(voyage.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      voyage.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(voyage.status),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: _onVoyageSelected,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE': return AppColors.primary;
      case 'COMPLETED': return AppColors.success;
      case 'CANCELLED': return AppColors.error;
      default: return Colors.orange;
    }
  }

  Widget _buildNoVoyages() {
    return AppEmptyState(
      title: 'No Voyages Found',
      subtitle: 'Create a voyage before starting fishing operations.',
      icon: Icons.directions_boat_outlined,
      actionButton: AppButton(
        text: 'Create Voyage',
        onPressed: () => context.go('/owner/voyages/new'),
      ),
    );
  }

  Widget _buildPlannedVoyage(VoyageEntity voyage) {
    return AppEmptyState(
      title: 'Voyage is Planned',
      subtitle: 'This voyage has not started yet. You need to start it to begin fishing operations.',
      icon: Icons.calendar_today_outlined,
      actionButton: AppButton(
        text: 'View & Start Voyage',
        onPressed: () => context.push('/owner/voyages/${voyage.id}'),
      ),
    );
  }
  
  Widget _buildCompletedVoyage(VoyageEntity voyage, HaulState haulState) {
    return AppEmptyState(
      title: 'Voyage Completed',
      subtitle: 'This voyage has been completed. Fishing operations have ended.',
      icon: Icons.check_circle_outline,
      actionButton: AppButton(
        text: 'View Voyage Summary',
        onPressed: () => context.push('/owner/voyages/${voyage.id}'),
      ),
    );
  }

  Widget _buildCancelledVoyage(VoyageEntity voyage) {
    return AppEmptyState(
      title: 'Voyage Cancelled',
      subtitle: 'This voyage was cancelled.',
      icon: Icons.cancel_outlined,
    );
  }

  Widget _buildActiveVoyageOperations(VoyageEntity voyage, HaulState haulState) {
    final activeHaul = haulState.activeHaul;
    final stoppedHauls = haulState.hauls.where((h) => h.status == 'STOPPED').toList();
    final completedHauls = haulState.hauls.where((h) => h.status == 'COMPLETED').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voyage Status Header
        Container(
          padding: const EdgeInsets.all(AppSizes.p16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.waves, color: Colors.white, size: 32),
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE VOYAGE',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      voyage.boatName ?? 'Unknown Boat',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Started: ${DateFormat('MMM d, h:mm a').format(voyage.startedAt ?? DateTime.now())}',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p24),

        // Active Haul Section
        Text(
          'CURRENT FISHING HAUL',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSizes.p8),

        if (activeHaul == null)
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
                const Icon(Icons.set_meal_outlined, size: 48, color: AppColors.textHint),
                const SizedBox(height: AppSizes.p16),
                Text(
                  'No active haul',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a new haul to track catches and GPS.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.p24),
                AppButton(
                  text: 'Start New Haul',
                  onPressed: () => context.push('/owner/fishing/hauls/new?voyageId=${voyage.id}'),
                  leadingIcon: Icons.play_arrow,
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Haul #${activeHaul.haulNumber} is Active',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${DateTime.now().difference(activeHaul.startedAt).inHours}h ${DateTime.now().difference(activeHaul.startedAt).inMinutes.remainder(60)}m',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p12),
                Text(
                  'Ground: ${activeHaul.fishingGround}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
                if (activeHaul.notes != null && activeHaul.notes!.isNotEmpty)
                  Text(
                    'Notes: ${activeHaul.notes}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                const SizedBox(height: AppSizes.p16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Dashboard',
                        onPressed: () => context.push('/owner/fishing/hauls/${activeHaul.id}'),
                        backgroundColor: Colors.blue.shade600,
                        leadingIcon: Icons.dashboard,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
        const SizedBox(height: AppSizes.p32),

        // Stopped Hauls Section (need catch to complete)
        if (stoppedHauls.isNotEmpty) ...[
          Text(
            'STOPPED HAULS - PENDING CATCH (${stoppedHauls.length})',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          ...stoppedHauls.map((h) => Card(
            margin: const EdgeInsets.only(top: AppSizes.p8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: const Icon(Icons.pause_circle, color: Colors.orange),
              ),
              title: Text('Haul #${h.haulNumber} - ${h.fishingGround}'),
              subtitle: Text(
                'Stopped: ${h.endedAt != null ? DateFormat('MMM d, HH:mm').format(h.endedAt!) : "Unknown"}\n'
                'Add a catch to complete this haul.',
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/owner/fishing/hauls/${h.id}'),
            ),
          )).toList(),
          const SizedBox(height: AppSizes.p24),
        ],

        // Completed Hauls Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'COMPLETED HAULS (${completedHauls.length})',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            if (completedHauls.isNotEmpty)
              TextButton(
                onPressed: () => context.push('/owner/fishing/hauls/history?voyageId=${voyage.id}'),
                child: const Text('View All'),
              ),
          ],
        ),
        if (completedHauls.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSizes.p16),
            child: Text('No completed hauls for this voyage yet.', style: TextStyle(color: AppColors.textHint)),
          )
        else
          ...completedHauls.take(5).map((h) => Card(
            margin: const EdgeInsets.only(top: AppSizes.p8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.successLight,
                child: Icon(Icons.check, color: AppColors.success),
              ),
              title: Text('Haul #${h.haulNumber} - ${h.fishingGround}'),
              subtitle: Text(
                'Started: ${DateFormat('MMM d, HH:mm').format(h.startedAt)}\n'
                'Stopped: ${h.endedAt != null ? DateFormat('MMM d, HH:mm').format(h.endedAt!) : "Unknown"}',
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/owner/fishing/hauls/${h.id}/summary'),
            ),
          )).toList(),
      ],
    );
  }
}

