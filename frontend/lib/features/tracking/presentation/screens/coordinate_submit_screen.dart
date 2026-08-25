import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../providers/tracking_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';

class CoordinateSubmitScreen extends ConsumerStatefulWidget {
  final String boatId;
  const CoordinateSubmitScreen({super.key, required this.boatId});

  @override
  ConsumerState<CoordinateSubmitScreen> createState() => _CoordinateSubmitScreenState();
}

class _CoordinateSubmitScreenState extends ConsumerState<CoordinateSubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _speedController = TextEditingController();
  final _headingController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatProvider.notifier).loadById(widget.boatId);
    });
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _speedController.dispose();
    _headingController.dispose();
    super.dispose();
  }

  void _simulateGPS() {
    // Chennai Kasimedu port base
    setState(() {
      _latController.text = '13.1256';
      _lngController.text = '80.2974';
      _speedController.text = '7.5';
      _headingController.text = '120.0';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulated GPS coordinates retrieved')),
    );
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final double lat = double.parse(_latController.text);
    final double lng = double.parse(_lngController.text);
    final double? speed = double.tryParse(_speedController.text);
    final double? heading = double.tryParse(_headingController.text);

    setState(() => _isLoading = true);
    final ok = await ref.read(trackingProvider.notifier).submitCoordinates(
          widget.boatId,
          lat,
          lng,
          speed: speed,
          heading: heading,
        );
    setState(() => _isLoading = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS coordinates submitted successfully')),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit coordinates. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final boat = boatState.selected;

    return Scaffold(
      appBar: AppBar(
        title: Text(boat != null ? 'Track ${boat.boatName}' : 'Submit Coordinates'),
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
                  'GPS Tracker Reporter',
                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSizes.p6),
                Text(
                  boat != null ? 'Submitting coordinate updates for ${boat.boatName} (${boat.boatNumber})' : 'Submitting boat location details',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.p24),
                AppTextField(
                  label: 'Latitude',
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.location_on_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Latitude is required';
                    final num = double.tryParse(val);
                    if (num == null || num < -90 || num > 90) return 'Enter a valid latitude (-90 to 90)';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.p16),
                AppTextField(
                  label: 'Longitude',
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.location_on_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Longitude is required';
                    final num = double.tryParse(val);
                    if (num == null || num < -180 || num > 180) return 'Enter a valid longitude (-180 to 180)';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.p16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Speed (knots)',
                        controller: _speedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.speed,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p16),
                    Expanded(
                      child: AppTextField(
                        label: 'Heading (degrees)',
                        controller: _headingController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.explore_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p32),
                OutlinedButton.icon(
                  onPressed: _simulateGPS,
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Simulate Current GPS Fetch'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius12)),
                  ),
                ),
                const SizedBox(height: AppSizes.p16),
                AppButton(
                  text: 'Submit GPS Telemetry',
                  onPressed: _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
