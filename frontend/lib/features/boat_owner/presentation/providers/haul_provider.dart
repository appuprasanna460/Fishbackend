import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/boat_owner_api_service.dart';
import '../../domain/entities/haul_entity.dart';
import 'crew_provider.dart'; // To get boatOwnerApiProvider

class HaulState {
  final bool isLoading;
  final String? error;
  final List<HaulEntity> hauls;
  final List<HaulEntity> recentHauls;
  final HaulEntity? activeHaul;

  HaulState({
    this.isLoading = false,
    this.error,
    this.hauls = const [],
    this.recentHauls = const [],
    this.activeHaul,
  });

  HaulState copyWith({
    bool? isLoading,
    String? error,
    List<HaulEntity>? hauls,
    List<HaulEntity>? recentHauls,
    HaulEntity? activeHaul,
    bool clearActiveHaul = false,
  }) {
    return HaulState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hauls: hauls ?? this.hauls,
      recentHauls: recentHauls ?? this.recentHauls,
      activeHaul: clearActiveHaul ? null : (activeHaul ?? this.activeHaul),
    );
  }
}

class HaulNotifier extends StateNotifier<HaulState> {
  final BoatOwnerApiService _apiService;

  HaulNotifier(this._apiService) : super(HaulState());

  Future<void> fetchHauls({String? voyageId, String? status, String? fishingGround, String? dateRange}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getHauls(
        voyageId: voyageId,
        status: status,
        fishingGround: fishingGround,
        dateRange: dateRange,
      );
      final list = res.map((e) => HaulEntity.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, hauls: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchRecentHauls({int limit = 5}) async {
    try {
      final res = await _apiService.getRecentHauls(limit: limit);
      final list = res.map((e) => HaulEntity.fromJson(e)).toList();
      state = state.copyWith(recentHauls: list);
    } catch (e) {
      // Silently fail for dashboard widgets
    }
  }

  Future<void> fetchActiveHaul(String voyageId) async {
    try {
      final res = await _apiService.getActiveHaul(voyageId);
      if (res != null) {
        state = state.copyWith(activeHaul: HaulEntity.fromJson(res));
      } else {
        state = state.copyWith(clearActiveHaul: true);
      }
    } catch (e) {
      state = state.copyWith(clearActiveHaul: true);
    }
  }

  Future<void> startHaul(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.startHaul(data);
      if (data['voyageId'] != null) {
        await fetchActiveHaul(data['voyageId']);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> stopHaul(String haulId, String voyageId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.stopHaul(haulId);
      // Clear active haul since it's now STOPPED
      await fetchActiveHaul(voyageId);
      // Fetch the hauls list to get the STOPPED haul
      await fetchHauls(voyageId: voyageId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateGpsTrack(String haulId, double lat, double lng) async {
    try {
      await _apiService.updateGpsTrack(haulId, {'latitude': lat, 'longitude': lng});
      // Optional: refresh active haul if needed
    } catch (e) {
      // Background update, fail silently
    }
  }
}

final haulProvider = StateNotifierProvider<HaulNotifier, HaulState>((ref) {
  return HaulNotifier(ref.watch(boatOwnerApiProvider));
});
