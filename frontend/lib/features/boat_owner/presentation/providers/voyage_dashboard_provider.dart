import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/boat_owner_api_service.dart';
import '../../domain/entities/haul_entity.dart';
import 'crew_provider.dart';

/// Represents one activity event in the recent-activity feed.
class ActivityEvent {
  final String time;
  final String title;
  final String? subtitle;
  final ActivityEventType type;

  const ActivityEvent({
    required this.time,
    required this.title,
    this.subtitle,
    this.type = ActivityEventType.operation,
  });
}

enum ActivityEventType { operation, alert, system }

/// Aggregated state for the Voyage Dashboard screen.
class VoyageDashboardState {
  final bool isLoading;
  final String? error;

  // Hauls
  final List<HaulEntity> hauls;
  final int completedHauls;

  // Catch totals (for today & overall)
  final double totalCatchKg;

  // Expense totals today
  final double todayFuelUsed;
  final double todayIceUsed;
  final double todayWaterUsed;
  final double totalExpenseToday; // sum of fuel/ice/water costs (approximated)

  // Day counter
  final int currentDay;  // how many days since departure
  final int totalDays;   // expected duration in days

  // Total voyage hours
  final int totalHours;

  // Distance (NM) - sum of haul distances
  final double totalDistanceNm;

  // Recent activity
  final List<ActivityEvent> recentActivity;

  const VoyageDashboardState({
    this.isLoading = false,
    this.error,
    this.hauls = const [],
    this.completedHauls = 0,
    this.totalCatchKg = 0,
    this.todayFuelUsed = 0,
    this.todayIceUsed = 0,
    this.todayWaterUsed = 0,
    this.totalExpenseToday = 0,
    this.currentDay = 1,
    this.totalDays = 7,
    this.totalHours = 0,
    this.totalDistanceNm = 0,
    this.recentActivity = const [],
  });

  VoyageDashboardState copyWith({
    bool? isLoading,
    String? error,
    List<HaulEntity>? hauls,
    int? completedHauls,
    double? totalCatchKg,
    double? todayFuelUsed,
    double? todayIceUsed,
    double? todayWaterUsed,
    double? totalExpenseToday,
    int? currentDay,
    int? totalDays,
    int? totalHours,
    double? totalDistanceNm,
    List<ActivityEvent>? recentActivity,
  }) {
    return VoyageDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hauls: hauls ?? this.hauls,
      completedHauls: completedHauls ?? this.completedHauls,
      totalCatchKg: totalCatchKg ?? this.totalCatchKg,
      todayFuelUsed: todayFuelUsed ?? this.todayFuelUsed,
      todayIceUsed: todayIceUsed ?? this.todayIceUsed,
      todayWaterUsed: todayWaterUsed ?? this.todayWaterUsed,
      totalExpenseToday: totalExpenseToday ?? this.totalExpenseToday,
      currentDay: currentDay ?? this.currentDay,
      totalDays: totalDays ?? this.totalDays,
      totalHours: totalHours ?? this.totalHours,
      totalDistanceNm: totalDistanceNm ?? this.totalDistanceNm,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }
}

class VoyageDashboardNotifier extends StateNotifier<VoyageDashboardState> {
  final BoatOwnerApiService _api;

  VoyageDashboardNotifier(this._api) : super(const VoyageDashboardState());

  /// Load all dashboard data for the given voyage.
  /// [departureDate] and [expectedDuration] are used to compute day X/Y and total hours.
  Future<void> load(
    String voyageId, {
    required DateTime departureDate,
    required String expectedDuration,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Expected duration in days
      final totalDays = expectedDuration == '8-9_DAYS' ? 9 : 7;
      final currentDay = DateTime.now().difference(departureDate).inDays + 1;

      // Fetch hauls for this voyage
      final rawHauls = await _api.getHauls(voyageId: voyageId);
      final hauls = rawHauls.map((e) => HaulEntity.fromJson(e)).toList();

      final completedHauls = hauls.where((h) => h.status == 'COMPLETED').length;

      // Total hours: sum of all haul durations (minutes → hours)
      final totalMinutes = hauls.fold<int>(
        0,
        (sum, h) => sum + (h.duration ?? 0),
      );
      final totalHours = totalMinutes ~/ 60;

      // Total distance (haul km → NM; 1 km = 0.539957 NM)
      const kmToNm = 0.539957;
      final totalDistanceNm = hauls.fold<double>(
        0,
        (sum, h) => sum + ((h.distance ?? 0) * kmToNm),
      );

      // Catches (total weight for this voyage)
      double totalCatchKg = 0;
      try {
        final catchSummary = await _api.getCatchSummaryByVoyage(voyageId);
        totalCatchKg = (catchSummary['totalWeight'] ?? 0).toDouble();
      } catch (_) {}

      // Expenses for today
      double todayFuel = 0, todayIce = 0, todayWater = 0, expenseToday = 0;
      try {
        final expData = await _api.getVoyageExpenses(voyageId);
        final expenses = expData['expenses'] as List? ?? [];
        final todayStr = _dateKey(DateTime.now());
        for (final e in expenses) {
          if (_dateKey(DateTime.parse(e['date'])) == todayStr) {
            todayFuel = (e['fuelUsed'] ?? 0).toDouble();
            todayIce = (e['iceUsed'] ?? 0).toDouble();
            todayWater = (e['waterUsed'] ?? 0).toDouble();
            expenseToday = todayFuel + todayIce + todayWater; // units-based placeholder
          }
        }
      } catch (_) {}

      // Recent activity: build from haul start/end events (last 7 events)
      final events = <ActivityEvent>[];
      final sortedHauls = [...hauls]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      for (final h in sortedHauls) {
        if (h.endedAt != null) {
          events.add(ActivityEvent(
            time: _formatTime(h.endedAt!),
            title: 'Haul #${h.haulNumber} completed',
            subtitle: h.fishingGround,
            type: ActivityEventType.operation,
          ));
        }
        events.add(ActivityEvent(
          time: _formatTime(h.startedAt),
          title: 'Haul #${h.haulNumber} started',
          subtitle: h.fishingGround,
          type: ActivityEventType.operation,
        ));
        if (events.length >= 7) break;
      }

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        hauls: hauls,
        completedHauls: completedHauls,
        totalCatchKg: totalCatchKg,
        todayFuelUsed: todayFuel,
        todayIceUsed: todayIce,
        todayWaterUsed: todayWater,
        totalExpenseToday: expenseToday,
        currentDay: currentDay.clamp(1, totalDays + 5),
        totalDays: totalDays,
        totalHours: totalHours,
        totalDistanceNm: totalDistanceNm,
        recentActivity: events,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $period';
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

final voyageDashboardProvider =
    StateNotifierProvider.autoDispose<VoyageDashboardNotifier, VoyageDashboardState>((ref) {
  return VoyageDashboardNotifier(ref.watch(boatOwnerApiProvider));
});
