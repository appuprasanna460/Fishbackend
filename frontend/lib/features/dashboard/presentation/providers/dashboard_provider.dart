import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardSummary {
  final double totalRevenue;
  final int totalBills;
  final int activeBoats;
  final double totalWeight;
  final List<double> weeklyRevenue;
  final Map<String, double> revenueByLocation;
  final Map<String, double> revenueByFish;

  const DashboardSummary({
    this.totalRevenue = 0.0,
    this.totalBills = 0,
    this.activeBoats = 0,
    this.totalWeight = 0.0,
    this.weeklyRevenue = const [],
    this.revenueByLocation = const {},
    this.revenueByFish = const {},
  });
}

class DashboardState {
  final DashboardSummary summary;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.summary = const DashboardSummary(),
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardSummary? summary,
    bool? isLoading,
    String? error,
  }) =>
      DashboardState(
        summary: summary ?? this.summary,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DioClient _client;

  DashboardNotifier(this._client) : super(const DashboardState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 29)).toIso8601String().split('T').first;
      final toDate = now.toIso8601String().split('T').first;
      final res = await _client.dio.get(ApiConstants.dashboardSummary, queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
      });
      final data = res.data is Map<String, dynamic> ? res.data : {};
      
      // Parse weeklyRevenue with proper date field from API
      final weeklyRaw = (data['weeklyRevenue'] is List) ? (data['weeklyRevenue'] as List) : [];
      final weeklyRevenue = weeklyRaw.map((e) {
        final rev = (e['revenue'] as num?)?.toDouble() ?? 0.0;
        return rev;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        summary: DashboardSummary(
          totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
          totalBills: (data['totalBills'] as num?)?.toInt() ?? 0,
          activeBoats: (data['activeBoats'] as num?)?.toInt() ?? 0,
          totalWeight: (data['totalWeight'] as num?)?.toDouble() ?? 0.0,
          weeklyRevenue: weeklyRevenue,
          revenueByLocation: (data['revenueByLocation'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
              const {},
          revenueByFish: (data['revenueByFish'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
              const {},
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.watch(dioClientProvider));
});
