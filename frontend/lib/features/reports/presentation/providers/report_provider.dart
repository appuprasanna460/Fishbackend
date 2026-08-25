// lib/features/reports/presentation/providers/report_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─── Report Models ────────────────────────────────────────────────────────────

class RevenuePoint {
  final DateTime date;
  final double revenue;
  final int count;
  const RevenuePoint({
    required this.date,
    required this.revenue,
    this.count = 0,
  });
}

class FishRevenueItem {
  final String fishName;
  final String category;
  final double totalWeight;
  final double totalRevenue;
  final double averagePrice;
  final double lowestPrice; // ✅ new
  final double highestPrice; // ✅ new
  final double? priceChangePercent; // ✅ new, null if no comparison data
  final bool? isRising; // ✅ new, null if no comparison data
  final int count;

  const FishRevenueItem({
    required this.fishName,
    this.category = 'General',
    this.totalWeight = 0,
    this.totalRevenue = 0,
    this.averagePrice = 0,
    this.lowestPrice = 0,
    this.highestPrice = 0,
    this.priceChangePercent,
    this.isRising,
    this.count = 0,
  });
}

class LocationRevenueItem {
  final String location;
  final String subLocation;
  final int billCount;
  final double revenue;
  final double totalWeight;
  const LocationRevenueItem({
    required this.location,
    required this.subLocation,
    required this.billCount,
    required this.revenue,
    this.totalWeight = 0,
  });
}

class BillsSummary {
  final int total;
  final int confirmed;
  final int paid;
  final int cancelled;
  final int draft;
  final double totalWeight;
  final double totalAmount;
  final double averageBillValue;
  final double totalCommission;
  const BillsSummary({
    this.total = 0,
    this.confirmed = 0,
    this.paid = 0,
    this.cancelled = 0,
    this.draft = 0,
    this.totalWeight = 0,
    this.totalAmount = 0,
    this.averageBillValue = 0,
    this.totalCommission = 0,
  });
}

class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String userName;
  final String action;
  final String resource;
  final String? ipAddress;
  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.userName,
    required this.action,
    required this.resource,
    this.ipAddress,
  });
}

// ─── Report State ─────────────────────────────────────────────────────────────

class ReportState {
  final List<RevenuePoint> revenueTrend;
  final List<FishRevenueItem> fishRevenue;
  final List<LocationRevenueItem> locationRevenue;
  final BillsSummary billsSummary;
  final List<AuditLogEntry> auditLogs;
  final bool isLoading;
  final String? error;
  final DateTime fromDate;
  final DateTime toDate;

  const ReportState({
    this.revenueTrend = const [],
    this.fishRevenue = const [],
    this.locationRevenue = const [],
    this.billsSummary = const BillsSummary(),
    this.auditLogs = const [],
    this.isLoading = false,
    this.error,
    required this.fromDate,
    required this.toDate,
  });

  ReportState copyWith({
    List<RevenuePoint>? revenueTrend,
    List<FishRevenueItem>? fishRevenue,
    List<LocationRevenueItem>? locationRevenue,
    BillsSummary? billsSummary,
    List<AuditLogEntry>? auditLogs,
    bool? isLoading,
    String? error,
    DateTime? fromDate,
    DateTime? toDate,
  }) => ReportState(
    revenueTrend: revenueTrend ?? this.revenueTrend,
    fishRevenue: fishRevenue ?? this.fishRevenue,
    locationRevenue: locationRevenue ?? this.locationRevenue,
    billsSummary: billsSummary ?? this.billsSummary,
    auditLogs: auditLogs ?? this.auditLogs,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    fromDate: fromDate ?? this.fromDate,
    toDate: toDate ?? this.toDate,
  );

  bool get hasData {
    // ✅ Check ALL data sources properly
    final hasRevenue = revenueTrend.isNotEmpty;
    final hasFish = fishRevenue.isNotEmpty;
    final hasLocation = locationRevenue.isNotEmpty;
    final hasBills = billsSummary.total > 0;

    print(
      '📊 [hasData] revenue: $hasRevenue, fish: $hasFish, location: $hasLocation, bills: $hasBills',
    );

    return hasRevenue || hasFish || hasLocation || hasBills;
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ReportNotifier extends StateNotifier<ReportState> {
  final DioClient _client;

  ReportNotifier(this._client)
    : super(
        ReportState(
          fromDate: DateTime.now().subtract(const Duration(days: 29)),
          toDate: DateTime.now(),
        ),
      ) {
    loadAll();
  }

  String get _from => state.fromDate.toIso8601String().split('T').first;
  String get _to => state.toDate.toIso8601String().split('T').first;

  Future<void> setDateRange(DateTime from, DateTime to) async {
    state = state.copyWith(fromDate: from, toDate: to);
    await loadAll();
  }

  /// Loads all report data in parallel
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    final errors = <String>[];

    try {
      // Load all in parallel
      await Future.wait([
        _loadRevenueTrend().catchError((e) {
          errors.add('Revenue: ${e.toString()}');
          return null;
        }),
        _loadFishRevenue().catchError((e) {
          errors.add('Fish: ${e.toString()}');
          return null;
        }),
        _loadLocationRevenue().catchError((e) {
          errors.add('Location: ${e.toString()}');
          return null;
        }),
        _loadBillsSummary().catchError((e) {
          errors.add('Bills: ${e.toString()}');
          return null;
        }),
      ]);
    } catch (e) {
      errors.add('General: ${e.toString()}');
    }

    state = state.copyWith(
      isLoading: false,
      error: errors.isNotEmpty ? errors.join('\n') : null,
    );
  }

  // ── Revenue Trend ──────────────────────────────────────────────────────────

  Future<void> _loadRevenueTrend() async {
    try {
      print('🟡 [REPORT] Loading revenue trend from: $_from to $_to');

      final res = await _client.dio.get(
        ApiConstants.revenueReport,
        queryParameters: {'fromDate': _from, 'toDate': _to},
      );

      print('🟡 [REPORT] Revenue status: ${res.statusCode}');
      print('🟡 [REPORT] Revenue data: ${res.data}');

      Map<String, dynamic> responseData = {};
      if (res.data is Map<String, dynamic>) {
        responseData = res.data as Map<String, dynamic>;
      }

      // ✅ Check if response has data
      if (responseData.containsKey('data')) {
        final data = responseData['data'] as Map<String, dynamic>;

        // ✅ Try to get daily data
        List<dynamic> raw = [];
        if (data['daily'] is List) {
          raw = data['daily'] as List<dynamic>;
          print('🟡 [REPORT] Found daily data: ${raw.length} points');
        } else if (data['data'] is List) {
          raw = data['data'] as List<dynamic>;
        }

        // ✅ Also check if there's a summary
        if (data['summary'] is Map<String, dynamic>) {
          final summary = data['summary'] as Map<String, dynamic>;
          print('🟡 [REPORT] Revenue summary: ${summary['totalRevenue']}');
        }

        final points = raw.map((e) {
          final dateStr = e['date']?.toString() ?? '';
          final date = DateTime.tryParse(dateStr) ?? DateTime.now();
          final revenue = (e['revenue'] as num?)?.toDouble() ?? 0.0;
          final count = (e['count'] as num?)?.toInt() ?? 0;
          return RevenuePoint(date: date, revenue: revenue, count: count);
        }).toList();

        state = state.copyWith(revenueTrend: points);
        print('🟡 [REPORT] Revenue trend loaded: ${points.length} points');
      } else {
        print('🟡 [REPORT] No revenue data found');
        state = state.copyWith(revenueTrend: []);
      }
    } catch (e) {
      print('🔴 [REPORT] Error loading revenue: $e');
      state = state.copyWith(revenueTrend: []);
    }
  }

  // ── Fish Revenue ───────────────────────────────────────────────────────────

  Future<void> _loadFishRevenue() async {
    try {
      print('🟡 [REPORT] Loading fish revenue');

      final res = await _client.dio.get(
        ApiConstants.revenueByFish,
        queryParameters: {'fromDate': _from, 'toDate': _to},
      );

      print('🟡 [REPORT] Fish response: ${res.statusCode}');

      // ✅ Parse response
      Map<String, dynamic> responseData = {};
      if (res.data is Map<String, dynamic>) {
        responseData = res.data as Map<String, dynamic>;
      }

      List<dynamic> raw = [];
      if (responseData['data'] is List) {
        raw = responseData['data'] as List<dynamic>;
      } else if (responseData is List) {
        raw = responseData as List<dynamic>; // ✅ FIX: Cast to List<dynamic>
      }

      print('🟡 [REPORT] Found ${raw.length} fish revenue items');

      final items = raw
          .map(
            (e) => FishRevenueItem(
              fishName: e['fishName']?.toString() ?? 'Unknown',
              category: e['category']?.toString() ?? 'General',
              totalWeight: (e['totalWeight'] as num?)?.toDouble() ?? 0.0,
              totalRevenue: (e['totalRevenue'] as num?)?.toDouble() ?? 0.0,
              averagePrice: (e['averagePrice'] as num?)?.toDouble() ?? 0.0,
              lowestPrice:
                  (e['lowestPrice'] as num?)?.toDouble() ?? 0.0, // ✅ new
              highestPrice:
                  (e['highestPrice'] as num?)?.toDouble() ?? 0.0, // ✅ new
              priceChangePercent: (e['priceChangePercent'] as num?)
                  ?.toDouble(), // ✅ new (nullable)
              isRising: e['isRising'] as bool?, // ✅ new (nullable)
              count: (e['count'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList();

      state = state.copyWith(fishRevenue: items);
    } catch (e) {
      print('🔴 [REPORT] Error loading fish revenue: $e');
      rethrow;
    }
  }

  // ── Location Revenue ───────────────────────────────────────────────────────

  Future<void> _loadLocationRevenue() async {
    try {
      print('🟡 [REPORT] Loading location revenue');

      final res = await _client.dio.get(
        ApiConstants.revenueByLocation,
        queryParameters: {'fromDate': _from, 'toDate': _to},
      );

      print('🟡 [REPORT] Location response: ${res.statusCode}');

      Map<String, dynamic> responseData = {};
      if (res.data is Map<String, dynamic>) {
        responseData = res.data as Map<String, dynamic>;
      }

      List<dynamic> raw = [];
      if (responseData['data'] is List) {
        raw = responseData['data'] as List<dynamic>;
      } else if (responseData is List) {
        raw = responseData as List<dynamic>; // ✅ FIX: Cast to List<dynamic>
      }

      print('🟡 [REPORT] Found ${raw.length} location revenue items');

      final items = raw
          .map(
            (e) => LocationRevenueItem(
              location: e['locationName']?.toString() ?? 'Unknown',
              subLocation: e['subLocationName']?.toString() ?? '',
              billCount: (e['totalBills'] as num?)?.toInt() ?? 0,
              revenue: (e['totalRevenue'] as num?)?.toDouble() ?? 0.0,
              totalWeight: (e['totalWeight'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList();

      state = state.copyWith(locationRevenue: items);
    } catch (e) {
      print('🔴 [REPORT] Error loading location revenue: $e');
      rethrow;
    }
  }
  // ── Bills Summary ──────────────────────────────────────────────────────────

  Future<void> _loadBillsSummary() async {
    try {
      print('🟡 [REPORT] Loading bills summary');

      final res = await _client.dio.get(
        ApiConstants.billsSummary,
        queryParameters: {'fromDate': _from, 'toDate': _to},
      );

      print('🟡 [REPORT] Bills summary response: ${res.statusCode}');

      // ✅ Parse response - backend returns { success, data: { summary: {...}, period: {...} } }
      Map<String, dynamic> responseData = {};
      if (res.data is Map<String, dynamic>) {
        responseData = res.data as Map<String, dynamic>;
      }

      // ✅ Get the 'data' object from the response
      Map<String, dynamic> data = {};
      if (responseData['data'] is Map<String, dynamic>) {
        data = responseData['data'] as Map<String, dynamic>;
      }

      // ✅ Get the 'summary' object from data
      Map<String, dynamic> summary = {};
      if (data['summary'] is Map<String, dynamic>) {
        summary = data['summary'] as Map<String, dynamic>;
      }

      // ✅ Get the 'total' object from summary
      Map<String, dynamic> total = {};
      if (summary['total'] is Map<String, dynamic>) {
        total = summary['total'] as Map<String, dynamic>;
      }

      // ✅ Get byStatus list
      List<dynamic> byStatus = [];
      if (summary['byStatus'] is List) {
        byStatus = summary['byStatus'] as List<dynamic>;
      }

      print('🟡 [REPORT] byStatus: $byStatus');
      print('🟡 [REPORT] total: $total');

      int confirmed = 0, paid = 0, cancelled = 0, draft = 0;
      for (final s in byStatus) {
        final st = s['status']?.toString()?.toUpperCase() ?? '';
        final count = (s['count'] as num?)?.toInt() ?? 0;
        if (st == 'CONFIRMED')
          confirmed = count;
        else if (st == 'PAID')
          paid = count;
        else if (st == 'CANCELLED')
          cancelled = count;
        else if (st == 'DRAFT')
          draft = count;
      }

      final totalBills = (total['totalBills'] as num?)?.toInt() ?? 0;
      final totalRevenue = (total['totalRevenue'] as num?)?.toDouble() ?? 0.0;
      final totalWeight = (total['totalWeight'] as num?)?.toDouble() ?? 0.0;
      final totalCommission =
          (total['totalCommission'] as num?)?.toDouble() ?? 0.0;

      print(
        '🟡 [REPORT] Bills: total=$totalBills, revenue=$totalRevenue, weight=$totalWeight',
      );

      state = state.copyWith(
        billsSummary: BillsSummary(
          total: totalBills,
          confirmed: confirmed,
          paid: paid,
          cancelled: cancelled,
          draft: draft,
          totalWeight: totalWeight,
          totalAmount: totalRevenue,
          totalCommission: totalCommission,
          averageBillValue: totalBills > 0 ? totalRevenue / totalBills : 0,
        ),
      );
    } catch (e) {
      print('🔴 [REPORT] Error loading bills summary: $e');
      rethrow;
    }
  }

  // ── Audit Logs ─────────────────────────────────────────────────────────────

  // ── Audit Logs ─────────────────────────────────────────────────────────────

  Future<void> loadAuditLogs({
    String? action,
    String? userId,
    int page = 1,
  }) async {
    try {
      final res = await _client.dio.get(
        ApiConstants.auditLogs,
        queryParameters: {
          'page': page,
          'limit': 20,
          if (action != null && action != 'ALL') 'action': action,
          if (userId != null) 'userId': userId,
        },
      );

      // ✅ FIX: Properly handle the response data
      List<dynamic> raw = [];

      if (res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        // Check if data contains a 'data' key with a list
        if (data['data'] is List) {
          raw = data['data'] as List<dynamic>;
        } else if (data['logs'] is List) {
          raw = data['logs'] as List<dynamic>;
        } else if (data['items'] is List) {
          raw = data['items'] as List<dynamic>;
        }
        // If data itself is a list (unlikely, but handle it)
      } else if (res.data is List) {
        raw = res.data as List<dynamic>;
      }

      final logs = raw
          .map(
            (e) => AuditLogEntry(
              id: e['_id']?.toString() ?? '',
              timestamp:
                  DateTime.tryParse(e['createdAt']?.toString() ?? '') ??
                  DateTime.now(),
              userName:
                  (e['userId'] is Map ? e['userId']['name'] : null)
                      ?.toString() ??
                  'Unknown',
              action: e['action']?.toString() ?? '',
              resource: e['resource']?.toString() ?? '',
              ipAddress: e['ip']?.toString(),
            ),
          )
          .toList();

      state = state.copyWith(auditLogs: logs);
    } catch (e) {
      state = state.copyWith(
        auditLogs: [],
        error: 'Failed to load audit logs: $e',
      );
    }
  }
}
// ─── Provider ─────────────────────────────────────────────────────────────────

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>(
  (ref) => ReportNotifier(ref.watch(dioClientProvider)),
);
