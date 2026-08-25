import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../providers/haul_provider.dart';

class BoatOwnerHaulForm extends ConsumerStatefulWidget {
  final String voyageId;

  const BoatOwnerHaulForm({super.key, required this.voyageId});

  @override
  ConsumerState<BoatOwnerHaulForm> createState() => _BoatOwnerHaulFormState();
}

class _BoatOwnerHaulFormState extends ConsumerState<BoatOwnerHaulForm> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedGroundName;
  final List<String> _fishingGrounds = ['Arabian Sea', 'Pacific Ocean', 'Indian Ocean'];
  
  final TextEditingController _gearTypeCtrl = TextEditingController();
  final TextEditingController _netLengthCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _gearTypeCtrl.dispose();
    _netLengthCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Location services are turned off on your device. '
            'Please turn on Location Services to fetch GPS coordinates for this haul.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAppSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Denied'),
          content: const Text(
            'Location permission is permanently denied. '
            'Please open App Settings and grant location access to start the haul.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('App Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled.
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      throw Exception('Failed to check location services status: $e');
    }
    
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationSettingsDialog();
      }
      throw Exception('Please turn on Location Services.');
    }

    // 2. Check location permissions.
    try {
      permission = await Geolocator.checkPermission();
    } catch (e) {
      throw Exception('Failed to check location permissions: $e');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied. We need GPS permission to start the haul.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showAppSettingsDialog();
      }
      throw Exception('Location permission permanently denied. Please enable location access in App Settings.');
    } 

    // 3. Try to get last known location first (quick check)
    Position? position;
    try {
      position = await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('Error getting last known position: $e');
    }

    // 4. If last known is null or unavailable, request fresh position
    if (position == null) {
      try {
        // Try high accuracy with timeout
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // Fallback to medium accuracy
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (err) {
          throw Exception('Failed to fetch GPS coordinates. GPS signal might be weak.');
        }
      }
    }

    if (position == null) {
      throw Exception('GPS location is unavailable. Please verify GPS is enabled on your device.');
    }

    return position;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroundName == null) {
      AppErrorBanner.show(context, 'Please select a fishing ground');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 4. Automatically fetch user current lat long
      final position = await _determinePosition();
      
      if (position == null) {
        throw Exception('Failed to get current location');
      }

      await ref.read(haulProvider.notifier).startHaul({
        'voyageId': widget.voyageId,
        'fishingGround': _selectedGroundName,
        'gearType': _gearTypeCtrl.text.trim(),
        'netLength': int.tryParse(_netLengthCtrl.text.trim()) ?? 0,
        'startLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'notes': _notesCtrl.text.trim(),
      });
      
      if (mounted) {
        AppErrorBanner.showSuccess(context, 'Haul started successfully');
        context.pop(); // Go back to Fishing screen
      }
    } catch (e) {
      if (mounted) {
        AppErrorBanner.show(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Start New Haul'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Fishing Ground Dropdown
              Text(
                'FISHING GROUND',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedGroundName,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    hintText: 'Select a location',
                  ),
                  items: _fishingGrounds.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedGroundName = val;
                    });
                  },
                  validator: (val) => val == null ? 'Required' : null,
                ),
              ),
              const SizedBox(height: AppSizes.p24),

              // 2. Gear Type Text Input
              Text(
                'GEAR TYPE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              TextFormField(
                controller: _gearTypeCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Trawl, Gillnet, Longline',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSizes.p24),

              // 3. Net Length Number Input
              Text(
                'NET LENGTH (METERS)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              TextFormField(
                controller: _netLengthCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 500',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Must be a valid number';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p24),

              // 4. Start Location (Visual Cue)
              Text(
                'START LOCATION',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              Container(
                padding: const EdgeInsets.all(AppSizes.p16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: AppColors.primary),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Text(
                        'Your current GPS location will be fetched automatically when you start the haul.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p24),

              // 5. Notes (Optional)
              Text(
                'NOTES (OPTIONAL)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Weather conditions, strategy, etc.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p32),

              AppButton(
                text: 'Start Haul',
                isLoading: _isSubmitting,
                onPressed: _submit,
                backgroundColor: AppColors.primary,
                leadingIcon: Icons.play_arrow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
