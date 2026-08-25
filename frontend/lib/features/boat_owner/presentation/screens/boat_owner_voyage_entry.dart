import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/crew_provider.dart';
import '../providers/voyage_provider.dart';

// Providers for loading harbours and species in entry screen
final _harboursProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final res = await dio.get(ApiConstants.harbours);
  return List<Map<String, dynamic>>.from(res.data['data']);
});

final _speciesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioClientProvider).dio;
  final res = await dio.get(ApiConstants.fish);
  return List<Map<String, dynamic>>.from(res.data['data']);
});

class BoatOwnerVoyageEntryScreen extends ConsumerStatefulWidget {
  final String voyageId;
  const BoatOwnerVoyageEntryScreen({super.key, required this.voyageId});

  @override
  ConsumerState<BoatOwnerVoyageEntryScreen> createState() => _BoatOwnerVoyageEntryScreenState();
}

class _BoatOwnerVoyageEntryScreenState extends ConsumerState<BoatOwnerVoyageEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Return Entry Fields
  String? _returnHarbourId;
  DateTime _returnDate = DateTime.now();
  TimeOfDay _returnTime = TimeOfDay.now();
  String _seaCondition = 'Moderate';
  final _distanceCtrl = TextEditingController();
  final _fuelCtrl = TextEditingController();
  final _iceCtrl = TextEditingController();
  final _returnNotesCtrl = TextEditingController();

  // Landing Entry Fields
  String? _landingHarbourId;
  DateTime _landingDate = DateTime.now();
  TimeOfDay _landingTime = TimeOfDay.now();
  final List<Map<String, dynamic>> _dbCatches = [];
  final _landingNotesCtrl = TextEditingController();

  bool _loading = false;
  bool _returnSubmitted = false;
  bool _landingSubmitted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(voyageProvider.notifier).loadVoyageById(widget.voyageId);
      _loadExistingData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _distanceCtrl.dispose();
    _fuelCtrl.dispose();
    _iceCtrl.dispose();
    _returnNotesCtrl.dispose();
    _landingNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(boatOwnerApiProvider);
      
      // Load Return Entry
      final returnData = await api.getReturnEntry(widget.voyageId);
      if (returnData != null) {
        _returnSubmitted = true;
        _returnHarbourId = returnData['returningToHarbour'] is Map
            ? returnData['returningToHarbour']['_id']
            : returnData['returningToHarbour'];
        if (returnData['returnDate'] != null) {
          _returnDate = DateTime.parse(returnData['returnDate']).toLocal();
        }
        if (returnData['returnTime'] != null) {
          _returnTime = _parseTimeOfDay(returnData['returnTime']);
        }
        _seaCondition = returnData['seaCondition'] ?? 'Moderate';
        _distanceCtrl.text = (returnData['distanceFromHarbour'] ?? 0).toString();
        _fuelCtrl.text = (returnData['fuelInTank'] ?? 0).toString();
        _iceCtrl.text = (returnData['iceInStock'] ?? 0).toString();
        _returnNotesCtrl.text = returnData['notes'] ?? '';
      } else {
        _returnSubmitted = false;
      }

      // Load Landing Entry details
      final landingData = await api.getLandingEntry(widget.voyageId);
      if (landingData != null) {
        _landingSubmitted = true;
        _landingHarbourId = landingData['landingHarbour'] is Map
            ? landingData['landingHarbour']['_id']
            : landingData['landingHarbour'];
        if (landingData['landingDate'] != null) {
          _landingDate = DateTime.parse(landingData['landingDate']).toLocal();
        }
        if (landingData['landingTime'] != null) {
          _landingTime = _parseTimeOfDay(landingData['landingTime']);
        }
        _landingNotesCtrl.text = landingData['notes'] ?? '';
      } else {
        _landingSubmitted = false;
      }

      // Fetch aggregated catches under the voyage from DB
      final catchSummary = await api.getCatchSummaryByVoyage(widget.voyageId);
      final dbCatches = catchSummary['bySpecies'] as List? ?? [];
      _dbCatches.clear();
      for (final c in dbCatches) {
        _dbCatches.add({
          'species': c['species']?.toString() ?? '',
          'weight': (c['weight'] ?? 0).toDouble(),
          'boxes': (c['boxes'] ?? 0).toInt(),
        });
      }
    } catch (e) {
      // Quietly log or ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.replaceAll(RegExp(r'[a-zA-Z\s]'), '');
      final parts = clean.split(':');
      int hour = int.parse(parts[0]);
      final min = int.parse(parts[1]);
      if (timeStr.toLowerCase().contains('pm') && hour < 12) hour += 12;
      if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: min);
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  String _fmtTimeOfDay(TimeOfDay tod) {
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _fmtDate(DateTime dt) => DateFormat('dd-MMM-yyyy').format(dt);

  Future<void> _saveReturnEntry() async {
    final voyage = ref.read(voyageProvider).currentVoyage;
    if (voyage == null) return;

    if (_returnHarbourId == null) {
      AppErrorBanner.show(context, 'Please select returning harbour');
      return;
    }

    setState(() => _loading = true);
    try {
      final combinedDateTime = DateTime(
        _returnDate.year,
        _returnDate.month,
        _returnDate.day,
        _returnTime.hour,
        _returnTime.minute,
      );

      final api = ref.read(boatOwnerApiProvider);
      await api.saveReturnEntry(widget.voyageId, {
        'boatId': voyage.boatId,
        'returningToHarbour': _returnHarbourId,
        'returnDate': combinedDateTime.toIso8601String(),
        'returnTime': _fmtTimeOfDay(_returnTime),
        'seaCondition': _seaCondition,
        'distanceFromHarbour': double.tryParse(_distanceCtrl.text) ?? 0,
        'fuelInTank': double.tryParse(_fuelCtrl.text) ?? 0,
        'iceInStock': double.tryParse(_iceCtrl.text) ?? 0,
        'notes': _returnNotesCtrl.text,
      });

      setState(() => _returnSubmitted = true);
      if (mounted) AppErrorBanner.showSuccess(context, 'Return entry saved successfully');
    } catch (e) {
      if (mounted) AppErrorBanner.show(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveLandingEntry() async {
    final voyage = ref.read(voyageProvider).currentVoyage;
    if (voyage == null) return;

    if (_landingHarbourId == null) {
      AppErrorBanner.show(context, 'Please select landing harbour');
      return;
    }

    double totalWeight = 0;
    for (final c in _dbCatches) {
      totalWeight += (c['weight'] ?? 0) as double;
    }

    setState(() => _loading = true);
    try {
      final combinedDateTime = DateTime(
        _landingDate.year,
        _landingDate.month,
        _landingDate.day,
        _landingTime.hour,
        _landingTime.minute,
      );

      final api = ref.read(boatOwnerApiProvider);
      await api.saveLandingEntry(widget.voyageId, {
        'boatId': voyage.boatId,
        'landingHarbour': _landingHarbourId,
        'landingDate': combinedDateTime.toIso8601String(),
        'landingTime': _fmtTimeOfDay(_landingTime),
        'totalCatch': totalWeight,
        'catchBySpecies': _dbCatches,
        'notes': _landingNotesCtrl.text,
      });

      setState(() => _landingSubmitted = true);
      if (mounted) AppErrorBanner.showSuccess(context, 'Landing entry saved successfully');
    } catch (e) {
      if (mounted) AppErrorBanner.show(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voyage = ref.watch(voyageProvider).currentVoyage;
    final harboursAsync = ref.watch(_harboursProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/owner/voyages/${widget.voyageId}'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entry', style: AppTextStyles.titleSmall.copyWith(color: Colors.white)),
            if (voyage != null)
              Text('${voyage.boatName ?? ''} | ${voyage.boatNumber ?? ''}',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '🚢 Return Entry'),
            Tab(text: '🏠 Landing Entry'),
          ],
        ),
      ),
      body: _loading && voyage == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReturnEntryTab(harboursAsync),
                _buildLandingEntryTab(harboursAsync),
              ],
            ),
    );
  }

  // ── Tab 1: Return Entry View ───────────────────────────────────────────────

  Widget _buildReturnEntryTab(AsyncValue<List<Map<String, dynamic>>> harboursAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_returnSubmitted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Return Entry Submitted ✓',
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Returning To Harbour Dropdown
                harboursAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading harbours: $e'),
                  data: (harbours) => DropdownButtonFormField<String>(
                    value: _returnHarbourId,
                    hint: const Text('Select Returning Harbour *'),
                    decoration: InputDecoration(
                      labelText: 'Returning To Harbour',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: harbours.map((h) {
                      return DropdownMenuItem<String>(
                        value: h['_id'],
                        child: Text(h['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: _returnSubmitted ? null : (val) => setState(() => _returnHarbourId = val),
                  ),
                ),
                const SizedBox(height: 16),

                // Return Date Picker
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _returnSubmitted ? null : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _returnDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2028),
                          );
                          if (picked != null) setState(() => _returnDate = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Return Date',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmtDate(_returnDate)),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Return Time Picker
                    Expanded(
                      child: InkWell(
                        onTap: _returnSubmitted ? null : () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _returnTime,
                          );
                          if (picked != null) setState(() => _returnTime = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Return Time',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmtTimeOfDay(_returnTime)),
                              const Icon(Icons.access_time, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sea Condition Dropdown
                DropdownButtonFormField<String>(
                  value: _seaCondition,
                  decoration: InputDecoration(
                    labelText: 'Sea Condition',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['Calm', 'Moderate', 'Rough'].map((c) {
                    return DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    );
                  }).toList(),
                  onChanged: _returnSubmitted ? null : (val) => setState(() => _seaCondition = val ?? 'Moderate'),
                ),
                const SizedBox(height: 16),

                // Distance, Fuel and Ice input
                TextField(
                  controller: _distanceCtrl,
                  enabled: !_returnSubmitted,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Distance From Harbour (NM)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fuelCtrl,
                        enabled: !_returnSubmitted,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Fuel In Tank (Est. Ltrs)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _iceCtrl,
                        enabled: !_returnSubmitted,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Ice In Stock (Est. Kg)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: _returnNotesCtrl,
                  enabled: !_returnSubmitted,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _returnSubmitted
                  ? const SizedBox.shrink()
                  : AppButton(
                      text: 'Save Return Entry',
                      onPressed: _saveReturnEntry,
                      backgroundColor: AppColors.primary,
                      leadingIcon: Icons.save_outlined,
                    ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Tab 2: Landing Entry View ──────────────────────────────────────────────

  Widget _buildLandingEntryTab(AsyncValue<List<Map<String, dynamic>>> harboursAsync) {
    // Compute total catch from db catches
    double totalWeight = 0;
    int totalBoxes = 0;
    for (final c in _dbCatches) {
      totalWeight += (c['weight'] ?? 0) as double;
      totalBoxes += (c['boxes'] ?? 0) as int;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_landingSubmitted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Landing Entry Submitted ✓',
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Landing Harbour Dropdown
                harboursAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading harbours: $e'),
                  data: (harbours) => DropdownButtonFormField<String>(
                    value: _landingHarbourId,
                    hint: const Text('Select Landing Harbour *'),
                    decoration: InputDecoration(
                      labelText: 'Landing Harbour',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: harbours.map((h) {
                      return DropdownMenuItem<String>(
                        value: h['_id'],
                        child: Text(h['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: _landingSubmitted ? null : (val) => setState(() => _landingHarbourId = val),
                  ),
                ),
                const SizedBox(height: 16),

                // Landing Date Picker
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _landingSubmitted ? null : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _landingDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2028),
                          );
                          if (picked != null) setState(() => _landingDate = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Landing Date',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmtDate(_landingDate)),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Landing Time Picker
                    Expanded(
                      child: InkWell(
                        onTap: _landingSubmitted ? null : () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _landingTime,
                          );
                          if (picked != null) setState(() => _landingTime = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Landing Time',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmtTimeOfDay(_landingTime)),
                              const Icon(Icons.access_time, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Read-only Table for Catch by Species
                Text(
                  '─── CATCH BY MAJOR SPECIES ───',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                if (_dbCatches.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'No catches recorded under this voyage.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Header Row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: const BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                          ),
                          child: Row(
                            children: const [
                              Expanded(flex: 3, child: Text('Species', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary))),
                              Expanded(flex: 2, child: Text('Estimated Catch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary), textAlign: TextAlign.right)),
                              Expanded(flex: 2, child: Text('Boxes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary), textAlign: TextAlign.right)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // List Rows
                        ..._dbCatches.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          final isLast = i == _dbCatches.length - 1;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3, child: Text(item['species'] ?? '', style: AppTextStyles.bodyMedium)),
                                    Expanded(flex: 2, child: Text('${(item['weight'] ?? 0).toStringAsFixed(0)} Kg', style: AppTextStyles.bodyMedium, textAlign: TextAlign.right)),
                                    Expanded(flex: 2, child: Text('${item['boxes'] ?? 0}', style: AppTextStyles.bodyMedium, textAlign: TextAlign.right)),
                                  ],
                                ),
                              ),
                              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
                            ],
                          );
                        }),
                        const Divider(height: 1),

                        // Total Row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: const BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(9)),
                          ),
                          child: Row(
                            children: [
                              const Expanded(flex: 3, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              Expanded(flex: 2, child: Text('${totalWeight.toStringAsFixed(0)} Kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.right)),
                              Expanded(flex: 2, child: Text('$totalBoxes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.right)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: _landingNotesCtrl,
                  enabled: !_landingSubmitted,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Landing Notes',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _landingSubmitted
                  ? const SizedBox.shrink()
                  : AppButton(
                      text: 'Save Landing Entry',
                      onPressed: _saveLandingEntry,
                      backgroundColor: AppColors.success,
                      leadingIcon: Icons.save_outlined,
                    ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
