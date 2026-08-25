import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/boat_owner_api_service.dart';
import 'crew_provider.dart';
import '../../domain/entities/haul_entity.dart';

class GpsTrackState {
  final bool isLoading;
  final String? error;
  final List<dynamic> voyageTracks; // haul-level gps tracks for one voyage
  final List<GpsPoint> haulTrack;
  final Map<String, dynamic>? trackSummary;

  // ── Track History ─────────────────────────────────────────────────────────
  final bool isLoadingHistory;
  final String? historyError;
  final List<dynamic> trackHistory;  // voyage summary cards
  final String historyPeriod;        // 'all' | 'today' | 'week' | 'month'

  // ── Voyage Detail (full GPS for map view) ─────────────────────────────────
  final bool isLoadingDetail;
  final String? detailError;
  final Map<String, dynamic>? voyageDetail;

  GpsTrackState({
    this.isLoading = false,
    this.error,
    this.voyageTracks = const [],
    this.haulTrack = const [],
    this.trackSummary,
    this.isLoadingHistory = false,
    this.historyError,
    this.trackHistory = const [],
    this.historyPeriod = 'all',
    this.isLoadingDetail = false,
    this.detailError,
    this.voyageDetail,
  });

  GpsTrackState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? voyageTracks,
    List<GpsPoint>? haulTrack,
    Map<String, dynamic>? trackSummary,
    bool? isLoadingHistory,
    String? historyError,
    bool clearHistoryError = false,
    List<dynamic>? trackHistory,
    String? historyPeriod,
    bool? isLoadingDetail,
    String? detailError,
    bool clearDetailError = false,
    Map<String, dynamic>? voyageDetail,
    bool clearVoyageDetail = false,
  }) {
    return GpsTrackState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      voyageTracks: voyageTracks ?? this.voyageTracks,
      haulTrack: haulTrack ?? this.haulTrack,
      trackSummary: trackSummary ?? this.trackSummary,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      historyError: clearHistoryError ? null : (historyError ?? this.historyError),
      trackHistory: trackHistory ?? this.trackHistory,
      historyPeriod: historyPeriod ?? this.historyPeriod,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      detailError: clearDetailError ? null : (detailError ?? this.detailError),
      voyageDetail: clearVoyageDetail ? null : (voyageDetail ?? this.voyageDetail),
    );
  }
}

class GpsTrackNotifier extends StateNotifier<GpsTrackState> {
  final BoatOwnerApiService _apiService;

  GpsTrackNotifier(this._apiService) : super(GpsTrackState());

  // ── Existing methods (unchanged) ──────────────────────────────────────────

  Future<void> fetchTracksByVoyage(String voyageId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getTracksByVoyage(voyageId);
      state = state.copyWith(isLoading: false, voyageTracks: res);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchTracksByHaul(String haulId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getTracksByHaul(haulId);
      final list = res.map((e) => GpsPoint.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, haulTrack: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchTrackSummary(String voyageId) async {
    try {
      final res = await _apiService.getTrackSummary(voyageId);
      state = state.copyWith(trackSummary: res);
    } catch (e) {
      // background — don't fail loudly
    }
  }

  // ── Track History ─────────────────────────────────────────────────────────

  /// Fetches voyage history list. [period]: 'all', 'today', 'week', 'month'.
  Future<void> fetchTrackHistory({String period = 'all', String? boatId}) async {
    state = state.copyWith(
      isLoadingHistory: true,
      clearHistoryError: true,
      historyPeriod: period,
    );
    try {
      final res = await _apiService.getGpsTrackHistory(
        period: period,
        boatId: boatId,
      );
      state = state.copyWith(isLoadingHistory: false, trackHistory: res);
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        historyError: e.toString(),
      );
    }
  }

  // ── Voyage Detail (full GPS track for map view) ───────────────────────────

  Future<void> fetchVoyageDetail(String voyageId) async {
    state = state.copyWith(
      isLoadingDetail: true,
      clearDetailError: true,
      clearVoyageDetail: true,
    );
    try {
      final res = await _apiService.getVoyageTrackDetail(voyageId);
      state = state.copyWith(isLoadingDetail: false, voyageDetail: res);
    } catch (e) {
      state = state.copyWith(
        isLoadingDetail: false,
        detailError: e.toString(),
      );
    }
  }
}

final gpsTrackProvider =
    StateNotifierProvider<GpsTrackNotifier, GpsTrackState>((ref) {
  return GpsTrackNotifier(ref.watch(boatOwnerApiProvider));
});
