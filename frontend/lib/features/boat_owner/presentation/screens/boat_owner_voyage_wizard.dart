import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../boats/presentation/providers/boat_provider.dart';
import '../../../boats/domain/entities/boat_entity.dart';
import '../providers/crew_provider.dart';
import '../providers/voyage_provider.dart';
import '../../domain/entities/crew_entity.dart';
import '../../domain/entities/voyage_entity.dart';
import '../widgets/wizard_step_indicator.dart';

// Future providers for fetching harbours and target species
final harboursFutureProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioClientProvider).dio;
  final response = await dio.get(ApiConstants.harbours);
  final data = response.data['data'] as List? ?? [];
  return data.map((e) => e as Map<String, dynamic>).toList();
});

final fishFutureProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioClientProvider).dio;
  final response = await dio.get(ApiConstants.boatOwnerFish);
  final data = response.data['data'] ?? response.data ?? [];
  return data is List ? data.map((e) => e as Map<String, dynamic>).toList() : [];
});

class BoatOwnerVoyageWizard extends ConsumerStatefulWidget {
  final String? voyageId;

  const BoatOwnerVoyageWizard({super.key, this.voyageId});

  @override
  ConsumerState<BoatOwnerVoyageWizard> createState() => _BoatOwnerVoyageWizardState();
}

class _BoatOwnerVoyageWizardState extends ConsumerState<BoatOwnerVoyageWizard> {
  int _currentStep = 0;
  final int _totalSteps = 6;
  bool _isEditMode = false;
  String? _editVoyageId;
  bool _isLoadingVoyage = false;

  final List<String> _stepNames = [
    'Select Boat',
    'Voyage Plan',
    'Select Captain',
    'Select Crew',
    'Supplies',
    'Confirm'
  ];

  // Wizard State variables
  BoatEntity? _selectedBoat;

  String? _selectedHarbourId;
  String? _selectedHarbourName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _voyageType = 'DEEP_SEA'; // DEEP_SEA / UNDERDEEP
  String _expectedDuration = '5-7_DAYS'; // 5-7_DAYS / 8-9_DAYS
  final List<String> _selectedTargetSpeciesIds = [];
  final List<String> _selectedTargetSpeciesNames = [];
  final TextEditingController _notesCtrl = TextEditingController();

  CrewEntity? _selectedCaptain;
  String _captainSearch = '';

  final List<CrewEntity> _selectedCrew = [];
  String _crewSearch = '';

  // Supplies controllers
  final TextEditingController _fuelReqCtrl = TextEditingController(text: '0');
  final TextEditingController _fuelTankCtrl = TextEditingController(text: '0');
  final TextEditingController _iceReqCtrl = TextEditingController(text: '0');
  final TextEditingController _iceStockCtrl = TextEditingController(text: '0');
  final TextEditingController _waterCtrl = TextEditingController(text: '0');
  final TextEditingController _foodSuppliesCtrl = TextEditingController();
  final TextEditingController _otherSuppliesCtrl = TextEditingController();

  double _fuelToCarry = 0;
  double _iceToCarry = 0;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fuelReqCtrl.addListener(_calculateFuelToCarry);
    _fuelTankCtrl.addListener(_calculateFuelToCarry);
    _iceReqCtrl.addListener(_calculateIceToCarry);
    _iceStockCtrl.addListener(_calculateIceToCarry);

    if (widget.voyageId != null) {
      _isEditMode = true;
      _editVoyageId = widget.voyageId;
      _isLoadingVoyage = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatProvider.notifier).load();
      ref.read(crewProvider.notifier).fetchCrew();
      ref.read(crewProvider.notifier).fetchAvailableCaptains();
      ref.read(crewProvider.notifier).fetchAvailableCrew();
      if (_isEditMode && _isLoadingVoyage) {
        ref.read(voyageProvider.notifier).loadVoyageById(_editVoyageId!);
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _fuelReqCtrl.dispose();
    _fuelTankCtrl.dispose();
    _iceReqCtrl.dispose();
    _iceStockCtrl.dispose();
    _waterCtrl.dispose();
    _foodSuppliesCtrl.dispose();
    _otherSuppliesCtrl.dispose();
    super.dispose();
  }

  void _calculateFuelToCarry() {
    final req = double.tryParse(_fuelReqCtrl.text) ?? 0;
    final tank = double.tryParse(_fuelTankCtrl.text) ?? 0;
    setState(() {
      _fuelToCarry = (req - tank) > 0 ? (req - tank) : 0;
    });
  }

  void _calculateIceToCarry() {
    final req = double.tryParse(_iceReqCtrl.text) ?? 0;
    final stock = double.tryParse(_iceStockCtrl.text) ?? 0;
    setState(() {
      _iceToCarry = (req - stock) > 0 ? (req - stock) : 0;
    });
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_selectedBoat == null) {
        AppErrorBanner.show(context, 'Please select a boat');
        return false;
      }
    } else if (_currentStep == 1) {
      if (_selectedHarbourId == null) {
        AppErrorBanner.show(context, 'Please select departure harbour');
        return false;
      }
      if (_selectedDate == null) {
        AppErrorBanner.show(context, 'Please select departure date');
        return false;
      }
      if (_selectedTime == null) {
        AppErrorBanner.show(context, 'Please select departure time');
        return false;
      }
    } else if (_currentStep == 2) {
      if (_selectedCaptain == null) {
        AppErrorBanner.show(context, 'Please select a captain');
        return false;
      }
    } else if (_currentStep == 3) {
      if (_selectedCrew.isEmpty) {
        AppErrorBanner.show(context, 'Please select at least 1 crew member');
        return false;
      }
    } else if (_currentStep == 4) {
      final fuelReq = double.tryParse(_fuelReqCtrl.text) ?? 0;
      final iceReq = double.tryParse(_iceReqCtrl.text) ?? 0;
      final water = double.tryParse(_waterCtrl.text) ?? 0;
      if (fuelReq <= 0) {
        AppErrorBanner.show(context, 'Please enter required diesel amount');
        return false;
      }
      if (iceReq <= 0) {
        AppErrorBanner.show(context, 'Please enter required ice amount');
        return false;
      }
      if (water <= 0) {
        AppErrorBanner.show(context, 'Please enter required water amount');
        return false;
      }
    }
    return true;
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
  }

  /// Parses a time string (24-hour "HH:mm" or 12-hour "h:mm AM/PM") into a TimeOfDay.
  TimeOfDay? _parseTimeOfDay(String timeStr) {
    if (timeStr.isEmpty) return null;
    final trimmed = timeStr.trim().toUpperCase();

    // Try 12-hour format: "8:30 PM" or "08:30 AM"
    final match12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(trimmed);
    if (match12 != null) {
      var hour = int.tryParse(match12.group(1)!) ?? 0;
      final minute = int.tryParse(match12.group(2)!) ?? 0;
      final isPM = match12.group(3) == 'PM';
      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    }

    // Try 24-hour format: "08:30" or "20:30"
    final parts24 = trimmed.split(':');
    if (parts24.length >= 2) {
      final hour = int.tryParse(parts24[0]);
      final minute = int.tryParse(parts24[1].split(' ')[0]);
      if (hour != null && minute != null && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    return null;
  }

  /// Formats a TimeOfDay into 24-hour "HH:mm" format for API submission.
  String _formatTime24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Attempts to load voyage data only when both voyage and boat/crew data are available.
  void _tryLoadVoyageData(VoyageEntity voyage) {
    final boatState = ref.read(boatProvider);
    final crewState = ref.read(crewProvider);

    // Check if boat data is loaded
    final boatLoaded = !boatState.isLoading && boatState.boats.isNotEmpty;
    // Check if crew data is loaded
    final crewLoaded = !crewState.isLoading && crewState.crewMembers.isNotEmpty;

    if (boatLoaded && crewLoaded) {
      _loadVoyageData(voyage);
      setState(() {
        _isLoadingVoyage = false;
      });
    }
  }

  /// Renders a loading indicator while voyage data is being fetched in edit mode.
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSizes.p16),
          Text(
            'Loading voyage details...',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _loadVoyageData(VoyageEntity voyage) {
    // Set boat
    final boatState = ref.read(boatProvider);
    for (final boat in boatState.boats) {
      if (boat.id == voyage.boatId) {
        _selectedBoat = boat;
        break;
      }
    }

    // Set harbour
    _selectedHarbourId = voyage.departureHarbour;
    _selectedHarbourName = voyage.departureHarbourName;

    // Set date and time
    _selectedDate = voyage.departureDate;
    _selectedTime = _parseTimeOfDay(voyage.departureTime);

    // Set voyage type and duration
    _voyageType = voyage.voyageType;
    _expectedDuration = voyage.expectedDuration;

    // Set target species
    _selectedTargetSpeciesIds.clear();
    _selectedTargetSpeciesNames.clear();
    _selectedTargetSpeciesIds.addAll(voyage.targetSpecies);
    if (voyage.targetSpeciesDetails != null) {
      _selectedTargetSpeciesNames.addAll(
        voyage.targetSpeciesDetails!.map((s) => s['name']?.toString() ?? '').where((n) => n.isNotEmpty),
      );
    }

    // Set captain
    final crewState = ref.read(crewProvider);
    for (final captain in crewState.crewMembers) {
      if (captain.id == voyage.captainId) {
        _selectedCaptain = captain;
        break;
      }
    }

    // Set crew
    _selectedCrew.clear();
    for (final crewId in voyage.crewMembers) {
      for (final crew in crewState.crewMembers) {
        if (crew.id == crewId) {
          _selectedCrew.add(crew);
          break;
        }
      }
    }

    // Set supplies
    _fuelReqCtrl.text = voyage.supplies.fuelRequired.toStringAsFixed(1);
    _fuelTankCtrl.text = voyage.supplies.fuelInTank.toStringAsFixed(1);
    _iceReqCtrl.text = voyage.supplies.iceRequired.toStringAsFixed(1);
    _iceStockCtrl.text = voyage.supplies.iceInStock.toStringAsFixed(1);
    _waterCtrl.text = voyage.supplies.water.toStringAsFixed(1);
    _foodSuppliesCtrl.text = voyage.supplies.foodSupplies;
    _otherSuppliesCtrl.text = voyage.supplies.otherSupplies;
    _notesCtrl.text = voyage.notes ?? '';

    _calculateFuelToCarry();
    _calculateIceToCarry();
  }

  Future<void> _submitVoyage() async {
    // Guard against null selections (e.g., voyage data didn't fully load in edit mode)
    if (_selectedBoat == null || _selectedCaptain == null) {
      if (mounted) {
        AppErrorBanner.show(context, 'Unable to save. Please ensure boat and captain are selected.');
      }
      return;
    }
    if (_selectedHarbourId == null || _selectedDate == null || _selectedTime == null) {
      if (mounted) {
        AppErrorBanner.show(context, 'Unable to save. Please ensure all voyage plan details are set.');
      }
      return;
    }

    setState(() => _isSaving = true);
    final fuelRequired = double.tryParse(_fuelReqCtrl.text) ?? 0;
    final fuelInTank = double.tryParse(_fuelTankCtrl.text) ?? 0;
    final iceRequired = double.tryParse(_iceReqCtrl.text) ?? 0;
    final iceInStock = double.tryParse(_iceStockCtrl.text) ?? 0;
    final water = double.tryParse(_waterCtrl.text) ?? 0;

    final data = {
      'boatId': _selectedBoat!.id,
      'captainId': _selectedCaptain!.id,
      'crewMembers': _selectedCrew.map((c) => c.id).toList(),
      'departureHarbour': _selectedHarbourId,
      'departureDate': _selectedDate!.toIso8601String(),
      'departureTime': _formatTime24(_selectedTime!),
      'voyageType': _voyageType,
      'expectedDuration': _expectedDuration,
      'targetSpecies': _selectedTargetSpeciesIds,
      'supplies': {
        'fuelRequired': fuelRequired,
        'fuelInTank': fuelInTank,
        'iceRequired': iceRequired,
        'iceInStock': iceInStock,
        'water': water,
        'foodSupplies': _foodSuppliesCtrl.text.trim(),
        'otherSupplies': _otherSuppliesCtrl.text.trim(),
      },
      'notes': _notesCtrl.text.trim(),
    };

    final bool success;
    if (_isEditMode) {
      success = await ref.read(voyageProvider.notifier).updateVoyage(_editVoyageId!, data);
    } else {
      success = await ref.read(voyageProvider.notifier).createVoyage(data);
    }
    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        AppErrorBanner.showSuccess(context, _isEditMode ? 'Voyage updated successfully!' : 'Voyage created successfully!');
        context.go('/owner/voyages');
      }
    } else {
      if (mounted) {
        final error = ref.read(voyageProvider).error ?? 'Failed to save voyage';
        AppErrorBanner.show(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set up listeners for voyage, boat, and crew state changes in edit mode
    if (_isEditMode && _isLoadingVoyage) {
      ref.listen(voyageProvider, (previous, next) {
        if (next.currentVoyage != null) {
          _tryLoadVoyageData(next.currentVoyage!);
        } else if (!next.isLoading && next.error != null) {
          setState(() => _isLoadingVoyage = false);
          if (mounted) {
            AppErrorBanner.show(context, 'Failed to load voyage: ${next.error}');
          }
        }
      });

      ref.listen(boatProvider, (previous, next) {
        if (next.boats.isNotEmpty && !next.isLoading) {
          final voyage = ref.read(voyageProvider).currentVoyage;
          if (voyage != null) {
            _tryLoadVoyageData(voyage);
          }
        }
      });

      ref.listen(crewProvider, (previous, next) {
        if (next.crewMembers.isNotEmpty && !next.isLoading) {
          final voyage = ref.read(voyageProvider).currentVoyage;
          if (voyage != null) {
            _tryLoadVoyageData(voyage);
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_stepNames[_currentStep]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              context.go('/owner/voyages');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Indicator Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p12),
            child: WizardStepIndicator(
              currentStep: _currentStep,
              stepNames: _stepNames,
            ),
          ),
          const SizedBox(height: 2),

          // Step Body
          Expanded(
            child: _isLoadingVoyage
                ? _buildLoadingIndicator()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.p16),
                    child: _buildStepBody(),
                  ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16, vertical: AppSizes.p10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoadingVoyage ? null : _prevStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: AppTextStyles.labelLarge,
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.p12),
                ],
                Expanded(
                  child: AppButton(
                    text: _currentStep == _totalSteps - 1
                        ? 'Confirm & Save Voyage'
                        : 'Next',
                    onPressed: _isLoadingVoyage
                        ? null
                        : (_currentStep == _totalSteps - 1
                            ? _submitVoyage
                            : _nextStep),
                    isLoading: _isSaving,
                    height: 44,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildStep1SelectBoat();
      case 1:
        return _buildStep2PlanDetails();
      case 2:
        return _buildStep3SelectCaptain();
      case 3:
        return _buildStep4SelectCrew();
      case 4:
        return _buildStep5Supplies();
      case 5:
        return _buildStep6Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── STEP 1: Select Boat ──────────────────────────────────────────────────────
  Widget _buildStep1SelectBoat() {
    final boatState = ref.watch(boatProvider);
    if (boatState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (boatState.boats.isEmpty) {
      return AppEmptyState(
        title: 'No Boats Registered',
        subtitle: 'Please register a boat in management tab first.',
        icon: Icons.directions_boat,
        actionLabel: 'Register Boat',
        onAction: () => context.go('/owner/my-boats/add'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which boat is setting sail?',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.p12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: boatState.boats.length,
          itemBuilder: (context, index) {
            final boat = boatState.boats[index];
            final isSelected = _selectedBoat?.id == boat.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBoat = boat;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSizes.p8),
                padding: const EdgeInsets.all(AppSizes.p16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: boat.id,
                      groupValue: _selectedBoat?.id ?? '',
                      onChanged: (_) {
                        setState(() {
                          _selectedBoat = boat;
                        });
                      },
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            boat.boatName,
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reg No: ${boat.boatNumber} | Capacity: ${boat.capacity} kg',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── STEP 2: Plan Details ─────────────────────────────────────────────────────
  Widget _buildStep2PlanDetails() {
    final harboursAsync = ref.watch(harboursFutureProvider);
    final fishAsync = ref.watch(fishFutureProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Define the Voyage details',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.p16),

        // Departure Harbour
        harboursAsync.when(
          data: (harbours) {
            return DropdownButtonFormField<String>(
              value: _selectedHarbourId,
              hint: const Text('Select Departure Harbour *'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: harbours.map((h) {
                return DropdownMenuItem<String>(
                  value: h['_id'],
                  child: Text(h['name'] ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedHarbourId = val;
                  _selectedHarbourName = harbours.firstWhere((h) => h['_id'] == val)['name'];
                });
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, _) => Text('Error loading harbours: $err'),
        ),
        const SizedBox(height: AppSizes.p16),

        // Departure Date Picker
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? now,
              firstDate: now.subtract(const Duration(days: 1)),
              lastDate: now.add(const Duration(days: 30)),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
          child: AbsorbPointer(
            child: AppTextField(
              label: 'Departure Date *',
              controller: TextEditingController(
                text: _selectedDate != null
                    ? DateFormat('dd-MMM-yyyy').format(_selectedDate!)
                    : '',
              ),
              prefixIcon: Icons.calendar_today,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p16),

        // Departure Time Picker
        GestureDetector(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedTime ?? TimeOfDay.now(),
            );
            if (time != null) {
              setState(() {
                _selectedTime = time;
              });
            }
          },
          child: AbsorbPointer(
            child: AppTextField(
              label: 'Departure Time *',
              controller: TextEditingController(
                text: _selectedTime != null ? _selectedTime!.format(context) : '',
              ),
              prefixIcon: Icons.access_time,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p16),

        // Voyage Type Toggle
        Text(
          'Voyage Type',
          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('DEEP SEA')),
                selected: _voyageType == 'DEEP_SEA',
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _voyageType == 'DEEP_SEA' ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) {
                  if (val) setState(() => _voyageType = 'DEEP_SEA');
                },
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('UNDERDEEP')),
                selected: _voyageType == 'UNDERDEEP',
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _voyageType == 'UNDERDEEP' ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) {
                  if (val) setState(() => _voyageType = 'UNDERDEEP');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),

        // Expected Duration Toggle
        Text(
          'Expected Duration',
          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('5 - 7 DAYS')),
                selected: _expectedDuration == '5-7_DAYS',
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _expectedDuration == '5-7_DAYS' ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) {
                  if (val) setState(() => _expectedDuration = '5-7_DAYS');
                },
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('8 - 9 DAYS')),
                selected: _expectedDuration == '8-9_DAYS',
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _expectedDuration == '8-9_DAYS' ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) {
                  if (val) setState(() => _expectedDuration = '8-9_DAYS');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),

        // Target Species Multi-select
        Text(
          'Target Species (Optional)',
          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        fishAsync.when(
          data: (fishList) {
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: fishList.map((fish) {
                final id = fish['_id'] as String;
                final name = fish['name'] as String;
                final isSelected = _selectedTargetSpeciesIds.contains(id);

                return FilterChip(
                  label: Text(name),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTargetSpeciesIds.add(id);
                        _selectedTargetSpeciesNames.add(name);
                      } else {
                        _selectedTargetSpeciesIds.remove(id);
                        _selectedTargetSpeciesNames.remove(name);
                      }
                    });
                  },
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text('Error loading fish: $err'),
        ),
        const SizedBox(height: AppSizes.p16),

        AppTextField(
          label: 'Notes',
          controller: _notesCtrl,
          prefixIcon: Icons.notes,
          maxLines: 3,
        ),
      ],
    );
  }

  // ── STEP 3: Select Captain ───────────────────────────────────────────────────
  Widget _buildStep3SelectCaptain() {
    final crewState = ref.watch(crewProvider);
    if (crewState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final captains = crewState.crewMembers.where((c) => c.role.toUpperCase() == 'CAPTAIN').toList();

    // Local filter by search query
    final filteredCaptains = captains
        .where((c) => c.name.toLowerCase().contains(_captainSearch.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Captain',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.p12),

        TextField(
          decoration: InputDecoration(
            hintText: 'Search available captains...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            setState(() {
              _captainSearch = val;
            });
          },
        ),
        const SizedBox(height: AppSizes.p16),

        if (filteredCaptains.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No available captains found.'),
          ))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCaptains.length,
            itemBuilder: (context, index) {
              final captain = filteredCaptains[index];
              final isSelected = _selectedCaptain?.id == captain.id;
              // In edit mode, the currently assigned captain is selectable even if marked unavailable
              final isSelectable = captain.isAvailable || (_isEditMode && isSelected);

              return GestureDetector(
                onTap: () {
                  if (isSelectable) {
                    setState(() {
                      _selectedCaptain = captain;
                    });
                  } else {
                    AppErrorBanner.show(context, 'Captain is currently on another voyage');
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSizes.p8),
                  padding: const EdgeInsets.all(AppSizes.p16),
                  decoration: BoxDecoration(
                    color: isSelectable ? Colors.white : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: captain.id ?? '',
                        groupValue: _selectedCaptain?.id ?? '',
                        onChanged: isSelectable
                            ? (_) {
                                setState(() {
                                  _selectedCaptain = captain;
                                });
                              }
                            : null,
                      ),
                      const SizedBox(width: AppSizes.p8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  captain.name,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelectable
                                        ? AppColors.textPrimary
                                        : AppColors.textHint,
                                  ),
                                ),
                                if (!isSelectable) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ON VOYAGE',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Exp: ${captain.experience ?? 0} yrs | Location: ${captain.location}',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ── STEP 4: Select Crew ──────────────────────────────────────────────────────
  Widget _buildStep4SelectCrew() {
    final crewState = ref.watch(crewProvider);
    if (crewState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final crewMembers = crewState.crewMembers.where((c) => c.role.toUpperCase() == 'CREW').toList();

    // Local filter by search query
    final filteredCrew = crewMembers
        .where((c) => c.name.toLowerCase().contains(_crewSearch.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Crew Members',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Selected: ${_selectedCrew.length}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p12),

        TextField(
          decoration: InputDecoration(
            hintText: 'Search available crew...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            setState(() {
              _crewSearch = val;
            });
          },
        ),
        const SizedBox(height: AppSizes.p16),

        if (filteredCrew.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No available crew members found.'),
          ))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCrew.length,
            itemBuilder: (context, index) {
              final member = filteredCrew[index];
              final isChecked = _selectedCrew.any((c) => c.id == member.id);
              // In edit mode, currently assigned crew members are selectable even if marked unavailable
              final isSelectable = member.isAvailable || (_isEditMode && isChecked);

              return Container(
                margin: const EdgeInsets.only(bottom: AppSizes.p8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelectable ? Colors.white : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: CheckboxListTile(
                  title: Row(
                    children: [
                      Text(
                        member.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelectable
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                      if (!isSelectable) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ON VOYAGE',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text('Age: ${member.age} | Location: ${member.location}'),
                  value: isChecked,
                  onChanged: isSelectable
                      ? (val) {
                          setState(() {
                            if (val == true) {
                              _selectedCrew.add(member);
                            } else {
                              _selectedCrew.removeWhere((c) => c.id == member.id);
                            }
                          });
                        }
                      : null,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            },
          ),
      ],
    );
  }

  // ── STEP 5: Supplies ─────────────────────────────────────────────────────────
  Widget _buildStep5Supplies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voyage Fuel & Supplies',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.p16),

        // Fuel
        Text(
          'DIESEL (Liters)',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: AppSizes.p8),
        AppTextField(
          label: 'Diesel Required (Est.) *',
          controller: _fuelReqCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.local_gas_station_outlined,
        ),
        const SizedBox(height: AppSizes.p12),
        AppTextField(
          label: 'Diesel Already in Tank *',
          controller: _fuelTankCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.opacity,
        ),
        const SizedBox(height: AppSizes.p12),
        AppTextField(
          label: 'Additional Diesel to Carry (Auto)',
          controller: TextEditingController(text: '${_fuelToCarry.toStringAsFixed(1)} Liters'),
          readOnly: true,
          prefixIcon: Icons.assignment_turned_in,
        ),
        const Divider(height: AppSizes.p32),

        // Ice
        Text(
          'ICE (Kg)',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: AppSizes.p8),
        AppTextField(
          label: 'Ice Required (Est.) *',
          controller: _iceReqCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.ac_unit,
        ),
        const SizedBox(height: AppSizes.p12),
        AppTextField(
          label: 'Ice Already in Stock *',
          controller: _iceStockCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.kitchen,
        ),
        const SizedBox(height: AppSizes.p12),
        AppTextField(
          label: 'Additional Ice to Carry (Auto)',
          controller: TextEditingController(text: '${_iceToCarry.toStringAsFixed(1)} Kg'),
          readOnly: true,
          prefixIcon: Icons.assignment_turned_in,
        ),
        const Divider(height: AppSizes.p32),

        // Other Supplies
        Text(
          'OTHER SUPPLIES',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: AppSizes.p8),
        AppTextField(
          label: 'Fresh Water (Liters) *',
          controller: _waterCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.water,
        ),
        const SizedBox(height: AppSizes.p12),
        AppTextField(
          label: 'Food Supplies description',
          controller: _foodSuppliesCtrl,
          prefixIcon: Icons.restaurant,
          maxLines: 2,
        ),
        const SizedBox(height: AppSizes.p12),
        AppTextField(
          label: 'Other Supplies details',
          controller: _otherSuppliesCtrl,
          prefixIcon: Icons.category,
          maxLines: 2,
        ),
      ],
    );
  }

  // ── STEP 6: Review ──────────────────────────────────────────────────────────
  Widget _buildStep6Review() {
    final formattedDate = _selectedDate != null
        ? DateFormat('dd-MMM-yyyy').format(_selectedDate!)
        : 'Not Set';
    final formattedTime = _selectedTime != null ? _selectedTime!.format(context) : 'Not Set';
    final voyageTypeLabel = _voyageType == 'DEEP_SEA' ? 'Deep Sea' : 'Underdeep';
    final durationLabel = _expectedDuration.replaceAll('_', ' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Voyage Details',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.p16),

        _reviewItem('Boat', '${_selectedBoat?.boatName} (${_selectedBoat?.boatNumber})'),
        _reviewItem('Departure Harbour', _selectedHarbourName ?? 'Not Set'),
        _reviewItem('Departure Time & Date', '$formattedTime, $formattedDate'),
        _reviewItem('Voyage Type', voyageTypeLabel),
        _reviewItem('Expected Duration', durationLabel),
        _reviewItem('Target Species', _selectedTargetSpeciesNames.isEmpty ? 'None Selected' : _selectedTargetSpeciesNames.join(', ')),
        const Divider(height: AppSizes.p24),
        _reviewItem('Captain', _selectedCaptain?.name ?? 'Not Selected'),
        _reviewItem('Crew count', '${_selectedCrew.length} members'),
        _reviewItem('Crew members', _selectedCrew.map((c) => c.name).join(', ')),
        const Divider(height: AppSizes.p24),
        _reviewItem('Additional Diesel to Carry', '${_fuelToCarry.toStringAsFixed(1)} Liters'),
        _reviewItem('Additional Ice to Carry', '${_iceToCarry.toStringAsFixed(1)} Kg'),
        _reviewItem('Fresh Water', '${_waterCtrl.text} Liters'),
        if (_foodSuppliesCtrl.text.isNotEmpty)
          _reviewItem('Food Supplies', _foodSuppliesCtrl.text.trim()),
        if (_otherSuppliesCtrl.text.isNotEmpty)
          _reviewItem('Other Supplies', _otherSuppliesCtrl.text.trim()),
        if (_notesCtrl.text.isNotEmpty)
          _reviewItem('Notes', _notesCtrl.text.trim()),
      ],
    );
  }

  Widget _reviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}