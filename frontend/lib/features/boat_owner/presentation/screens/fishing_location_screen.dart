// lib/features/boat_owner/presentation/screens/fishing_location_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/fishing_location_provider.dart';

class FishingLocationScreen extends ConsumerStatefulWidget {
  const FishingLocationScreen({super.key});

  @override
  ConsumerState<FishingLocationScreen> createState() =>
      _FishingLocationScreenState();
}

class _FishingLocationScreenState
    extends ConsumerState<FishingLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBoatId;
  DateTime _selectedDate = DateTime.now();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _isSaving = false;

  // History filters
  String? _filterBoatId;
  DateTime? _filterDate;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fishingLocationProvider.notifier).loadLocations();
      ref.read(boatProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFilter) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isFilter ? (_filterDate ?? DateTime.now()) : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFilter) {
          _filterDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate() || _selectedBoatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields correctly')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final ok = await ref.read(fishingLocationProvider.notifier).saveLocation(
          boatId: _selectedBoatId!,
          date: _selectedDate,
          latitude: double.parse(_latController.text),
          longitude: double.parse(_lngController.text),
        );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Fishing Location saved successfully'
            : 'Failed to save location. Please try again.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
      if (ok) {
        _latController.clear();
        _lngController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boatState = ref.watch(boatProvider);
    final authState = ref.watch(authProvider);
    final locationState = ref.watch(fishingLocationProvider);

    final user = authState.user;
    final myBoats = boatState.boats
        .where((b) => b.ownerId == user?.id && b.isActive)
        .toList();

    // Filtered history
    final history = locationState.locations.where((loc) {
      if (_filterBoatId != null && loc.boatId != _filterBoatId) return false;
      if (_filterDate != null &&
          (loc.date.year != _filterDate!.year ||
              loc.date.month != _filterDate!.month ||
              loc.date.day != _filterDate!.day)) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !loc.boatName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fishing Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(fishingLocationProvider.notifier).loadLocations(),
          ),
        ],
      ),
      body: AppLoadingOverlay(
        isLoading: locationState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Banner
              if (locationState.error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppSizes.p12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  child: Text('Error: ${locationState.error}',
                      style: const TextStyle(color: Colors.red)),
                ),

              // ── Add Fishing Location Form ──────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radius16)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Fishing Location',
                            style: AppTextStyles.titleMedium
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSizes.p12),

                        // Boat dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedBoatId,
                          decoration: InputDecoration(
                            labelText: 'Select Boat *',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radius12)),
                          ),
                          items: myBoats
                              .map((b) => DropdownMenuItem(
                                    value: b.id,
                                    child: Text(b.boatName),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedBoatId = val),
                          validator: (val) =>
                              val == null ? 'Boat is required' : null,
                        ),
                        const SizedBox(height: AppSizes.p12),

                        // Date picker
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date *',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radius12)),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd-MMM-yyyy')
                                    .format(_selectedDate)),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.p12),

                        // ── Latitude & Longitude ────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                decoration: InputDecoration(
                                  labelText: 'Latitude *',
                                  hintText: '12.946',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.radius12)),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Required';
                                  }
                                  final n = double.tryParse(val);
                                  if (n == null || n < -90 || n > 90) {
                                    return 'Range: -90 to 90';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: AppSizes.p12),
                            Expanded(
                              child: TextFormField(
                                controller: _lngController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                decoration: InputDecoration(
                                  labelText: 'Longitude *',
                                  hintText: '78.8738',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.radius12)),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Required';
                                  }
                                  final n = double.tryParse(val);
                                  if (n == null ||
                                      n < -180 ||
                                      n > 180) {
                                    return 'Range: -180 to 180';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        // ── Coordinate Preview ──────────────────────────────
                        if (_latController.text.isNotEmpty &&
                            _lngController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    '📍 ${_latController.text}, ${_lngController.text}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSizes.p16),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radius12)),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2),
                                  )
                                : const Text('Save Location'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p24),

              // ── History Section ────────────────────────────────────────────
              Text('History',
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.p12),

              // Filter Card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radius16)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p12),
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by boat name...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSizes.radius12)),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (val) =>
                            setState(() => _searchQuery = val),
                      ),
                      const SizedBox(height: AppSizes.p8),
                      Row(
                        children: [
                          // Boat filter
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _filterBoatId,
                              decoration: InputDecoration(
                                labelText: 'Filter Boat',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radius12)),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Boats')),
                                ...myBoats.map((b) => DropdownMenuItem(
                                    value: b.id,
                                    child: Text(b.boatName))),
                              ],
                              onChanged: (val) =>
                                  setState(() => _filterBoatId = val),
                            ),
                          ),
                          const SizedBox(width: AppSizes.p8),
                          // Date filter
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Filter Date',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppSizes.radius12)),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_filterDate == null
                                        ? 'Any Date'
                                        : DateFormat('dd-MMM')
                                            .format(_filterDate!)),
                                    if (_filterDate != null)
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _filterDate = null),
                                        child: const Icon(Icons.clear,
                                            size: 16),
                                      )
                                    else
                                      const Icon(Icons.calendar_today,
                                          size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p12),

              // Location Cards
              history.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                          child: Text(
                        'No location history records found.',
                        style: TextStyle(color: AppColors.textHint),
                      )),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      itemBuilder: (context, idx) {
                        final loc = history[idx];
                        return Card(
                          margin: const EdgeInsets.only(
                              bottom: AppSizes.p8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primarySurface,
                              child: Icon(Icons.location_on,
                                  color: AppColors.primary),
                            ),
                            title: Text(loc.boatName,
                                style: AppTextStyles.labelLarge),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '📅 ${DateFormat('dd-MMM-yyyy').format(loc.date)}'),
                                const SizedBox(height: 2),
                                Text(
                                  '📍 ${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.primary),
                                  onPressed: () {
                                    setState(() {
                                      _selectedBoatId = loc.boatId;
                                      _selectedDate = loc.date;
                                      _latController.text =
                                          loc.latitude.toString();
                                      _lngController.text =
                                          loc.longitude.toString();
                                    });
                                    // Scroll to form
                                    Scrollable.ensureVisible(
                                      context,
                                      duration: const Duration(milliseconds: 300),
                                    );
                                  },
                                ),
                                // Delete
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.error),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Location'),
                                        content: const Text(
                                          'Are you sure you want to delete this location?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Delete',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final ok = await ref
                                          .read(fishingLocationProvider
                                              .notifier)
                                          .deleteLocation(loc.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(ok
                                              ? 'Location deleted'
                                              : 'Failed to delete'),
                                          backgroundColor: ok
                                              ? AppColors.success
                                              : AppColors.error,
                                        ));
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
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