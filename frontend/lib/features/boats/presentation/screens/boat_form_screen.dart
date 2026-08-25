// lib/features/boats/presentation/screens/boat_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_location_picker.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../providers/boat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../../locations/presentation/providers/location_provider.dart';
import '../../../locations/domain/entities/location_entity.dart';

class BoatFormScreen extends ConsumerStatefulWidget {
  final String? boatId;
  const BoatFormScreen({super.key, this.boatId});

  @override
  ConsumerState<BoatFormScreen> createState() => _BoatFormScreenState();
}

class _BoatFormScreenState extends ConsumerState<BoatFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _regNumController = TextEditingController();
  final _capacityController = TextEditingController();

  String? _selectedOwnerId;
  String? _selectedLocationId;
  String? _selectedSubLocationId;

  bool _isEdit = false;
  bool _isLoading = false;
  bool _isBoatOwner = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.boatId != null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _isLoading = true);

      // ✅ Check if current user is BOAT_OWNER
      final authState = ref.read(authProvider);
      final user = authState.user;
      _isBoatOwner = user?.role == 'BOAT_OWNER';

      // Load locations
      await ref.read(locationProvider.notifier).load();

      // ✅ Only load boat owners if NOT a boat owner
      if (!_isBoatOwner) {
        await ref.read(userProvider.notifier).loadBoatOwners();
      }

      if (_isEdit) {
        final success = await ref
            .read(boatProvider.notifier)
            .loadById(widget.boatId!);
        if (success) {
          final boat = ref.read(boatProvider).selected;
          if (boat != null) {
            _nameController.text = boat.boatName;
            _numberController.text = boat.boatNumber;
            _regNumController.text = boat.registrationNumber ?? '';
            _capacityController.text = boat.capacity?.toString() ?? '';
            _selectedOwnerId = boat.ownerId;
            _selectedLocationId = boat.locationId;
            _selectedSubLocationId = boat.subLocationId;
          }
        }
      } else {
        // ✅ For BOAT_OWNER, auto-set ownerId when creating new boat
        if (_isBoatOwner) {
          _selectedOwnerId = user?.id;
        }
      }

      setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _regNumController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    final currentUser = authState.user;
    final isBoatOwner = currentUser?.role == 'BOAT_OWNER';

    String? ownerId = _selectedOwnerId;
    String ownerName = '';

    if (isBoatOwner) {
      // ✅ BOAT_OWNER: use their own ID
      ownerId = currentUser?.id;
      ownerName = currentUser?.name ?? '';
    } else {
      // SUPER_ADMIN or AGENT: get owner name from dropdown
      final userState = ref.read(userProvider);
      final owners = userState.boatOwners;
      UserEntity? owner;
      for (final o in owners) {
        if (o.id == _selectedOwnerId) {
          owner = o;
          break;
        }
      }
      owner ??= owners.isNotEmpty ? owners.first : null;
      ownerName = owner?.name ?? '';
    }

    final data = {
      'boatName': _nameController.text,
      'boatNumber': _numberController.text,
      'registrationNumber': _regNumController.text,
      'capacity': int.tryParse(_capacityController.text) ?? 0,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'locationId': _selectedLocationId,
      'subLocationId': _selectedSubLocationId,
      'isActive': true,
    };

    setState(() => _isLoading = true);
    bool ok;
    if (_isEdit) {
      ok = await ref
          .read(boatProvider.notifier)
          .updateBoat(widget.boatId!, data);
    } else {
      ok = await ref.read(boatProvider.notifier).createBoat(data);
    }
    setState(() => _isLoading = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Boat ${_isEdit ? 'updated' : 'registered'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operation failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final userState = ref.watch(userProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final owners = userState.boatOwners;
    final isBoatOwner = user?.role == 'BOAT_OWNER';

    // Map selected locations to display names
    LocationEntity? selectedLocation;
    try {
      selectedLocation = locationState.locations.firstWhere(
        (l) => l.id == _selectedLocationId,
      );
    } catch (_) {
      selectedLocation = null;
    }
    final selectedLocationName = selectedLocation?.name;

    final subLocations = selectedLocation?.subLocations ?? [];
    SubLocationEntity? selectedSubLocation;
    try {
      selectedSubLocation = subLocations.firstWhere(
        (s) => s.id == _selectedSubLocationId,
      );
    } catch (_) {
      selectedSubLocation = null;
    }
    final selectedSubLocationName = selectedSubLocation?.name;

    return Scaffold(
      appBar: AppBar(
        // ✅ Add back button with leading
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(_isEdit ? 'Edit Boat Details' : 'Register New Boat'),
      ),
      body: AppLoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boat Characteristics',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.p16),
                AppTextField(
                  label: 'Boat Name',
                  controller: _nameController,
                  prefixIcon: Icons.directions_boat,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Boat name is required'
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                AppTextField(
                  label: 'Boat Registration Number (e.g. IND-TN-01-M-1234)',
                  controller: _numberController,
                  prefixIcon: Icons.app_registration,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Boat registration number is required'
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                AppTextField(
                  label: 'Official License/Reg ID',
                  controller: _regNumController,
                  prefixIcon: Icons.assignment_outlined,
                ),
                const SizedBox(height: AppSizes.p16),
                AppTextField(
                  label: 'Capacity (in Tons)',
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.scale_outlined,
                ),
                const SizedBox(height: AppSizes.p24),
                Text(
                  'Owner & Port Location',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.p16),

                // ✅ Show owner dropdown ONLY for SUPER_ADMIN and AGENTS
                // Hide for BOAT_OWNER (auto-set their ID)
                if (!isBoatOwner) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedOwnerId,
                    decoration: InputDecoration(
                      labelText: 'Assign Boat Owner',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                      ),
                    ),
                    items: owners
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(o.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedOwnerId = val),
                    validator: (val) =>
                        val == null ? 'Please assign an owner' : null,
                  ),
                  const SizedBox(height: AppSizes.p16),
                ],

                // ✅ Show owner info for BOAT_OWNER (read-only)
                if (isBoatOwner) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Boat Owner',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                user?.name ?? 'You',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p16),
                ],

                const SizedBox(height: AppSizes.p32),
                AppButton(
                  text: _isEdit ? 'Save Boat Information' : 'Register Boat',
                  onPressed: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
