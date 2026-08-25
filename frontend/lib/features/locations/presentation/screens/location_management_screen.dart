import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../providers/location_provider.dart';
import '../../domain/entities/location_entity.dart';

class LocationManagementScreen extends ConsumerStatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  ConsumerState<LocationManagementScreen> createState() => _LocationManagementScreenState();
}

class _LocationManagementScreenState extends ConsumerState<LocationManagementScreen> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(locationProvider.notifier).load()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationDialog(context),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Location'),
      ),
      body: AppLoadingOverlay(
        isLoading: state.isLoading,
        child: state.error != null
            ? AppErrorBanner(message: state.error!, onRetry: () => ref.read(locationProvider.notifier).load())
            : state.locations.isEmpty && !state.isLoading
                ? const AppEmptyState(title: 'No Locations', subtitle: 'Add your first fishing location', icon: Icons.location_off_outlined)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.p16),
                    itemCount: state.locations.length,
                    itemBuilder: (_, i) => _buildLocationTile(state.locations[i]),
                  ),
      ),
    );
  }

  Widget _buildLocationTile(LocationEntity loc) {
    final isExpanded = _expanded.contains(loc.id);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius16)),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
              child: const Icon(Icons.location_on, color: AppColors.primary, size: 22),
            ),
            title: Text(loc.name, style: AppTextStyles.labelLarge),
            subtitle: Text(
              [if (loc.district != null) loc.district, if (loc.state != null) loc.state].join(', '),
              style: AppTextStyles.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${loc.subLocations.length} sub', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                ),
              ],
            ),
            onTap: () => setState(() => isExpanded ? _expanded.remove(loc.id) : _expanded.add(loc.id)),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
              child: Column(
                children: [
                  ...loc.subLocations.map((sub) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, color: AppColors.secondary, size: 18),
                    title: Text(sub.name, style: AppTextStyles.bodyMedium),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      onPressed: () => _confirmDeleteSubLocation(sub.id),
                    ),
                  )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showSubLocationDialog(context, loc.id),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Sub-location'),
                      ),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary), onPressed: () => _showLocationDialog(context, existing: loc)),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error), onPressed: () => _confirmDeleteLocation(loc.id)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context, {LocationEntity? existing}) {
    final ctrl = TextEditingController(text: existing?.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius16)),
        title: Text(existing == null ? 'Add Location' : 'Edit Location', style: AppTextStyles.h3),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Location Name', prefixIcon: Icon(Icons.location_on_outlined))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final notifier = ref.read(locationProvider.notifier);
              bool ok;
              if (existing == null) {
                ok = await notifier.createLocation(ctrl.text.trim());
              } else {
                ok = await notifier.updateLocation(existing.id, ctrl.text.trim());
              }
              if (context.mounted) {
                Navigator.pop(context);
                if (ok) AppErrorBanner.showSuccess(context, existing == null ? 'Location added!' : 'Location updated!');
              }
            },
            child: Text(existing == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showSubLocationDialog(BuildContext context, String locationId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius16)),
        title: Text('Add Sub-location', style: AppTextStyles.h3),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Sub-location Name', prefixIcon: Icon(Icons.place_outlined))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final ok = await ref.read(locationProvider.notifier).createSubLocation(ctrl.text.trim(), locationId);
              if (context.mounted) { Navigator.pop(context); if (ok) AppErrorBanner.showSuccess(context, 'Sub-location added!'); }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteLocation(String id) async {
    final ok = await AppConfirmDialog.show(context: context, title: 'Delete Location', message: 'This will also delete all sub-locations.', isDangerous: true, confirmLabel: 'Delete');
    if (ok == true && mounted) await ref.read(locationProvider.notifier).deleteLocation(id);
  }

  Future<void> _confirmDeleteSubLocation(String id) async {
    final ok = await AppConfirmDialog.show(context: context, title: 'Remove Sub-location', message: 'Are you sure?', isDangerous: true, confirmLabel: 'Remove');
    if (ok == true && mounted) await ref.read(locationProvider.notifier).deleteSubLocation(id);
  }
}
