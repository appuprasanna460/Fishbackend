import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/boat_owner_api_service.dart';
import '../../domain/entities/fishing_ground_entity.dart';
import 'crew_provider.dart';

class FishingGroundState {
  final bool isLoading;
  final String? error;
  final List<FishingGroundEntity> fishingGrounds;
  final List<FishingGroundEntity> favouriteGrounds;
  final List<FishingGroundEntity> history;

  FishingGroundState({
    this.isLoading = false,
    this.error,
    this.fishingGrounds = const [],
    this.favouriteGrounds = const [],
    this.history = const [],
  });

  FishingGroundState copyWith({
    bool? isLoading,
    String? error,
    List<FishingGroundEntity>? fishingGrounds,
    List<FishingGroundEntity>? favouriteGrounds,
    List<FishingGroundEntity>? history,
  }) {
    return FishingGroundState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      fishingGrounds: fishingGrounds ?? this.fishingGrounds,
      favouriteGrounds: favouriteGrounds ?? this.favouriteGrounds,
      history: history ?? this.history,
    );
  }
}

class FishingGroundNotifier extends StateNotifier<FishingGroundState> {
  final BoatOwnerApiService _apiService;

  FishingGroundNotifier(this._apiService) : super(FishingGroundState());

  Future<void> fetchFishingGrounds() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getFishingGrounds();
      final list = res.map((e) => FishingGroundEntity.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, fishingGrounds: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchFavouriteGrounds() async {
    try {
      final res = await _apiService.getFavouriteGrounds();
      final list = res.map((e) => FishingGroundEntity.fromJson(e)).toList();
      state = state.copyWith(favouriteGrounds: list);
    } catch (e) {
      // Background update
    }
  }

  Future<void> toggleFavourite(String id) async {
    try {
      await _apiService.toggleFavouriteGround(id);
      await fetchFishingGrounds();
      await fetchFavouriteGrounds();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> fetchGroundHistory({String? search, String? dateRange}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getGroundHistory(search: search, dateRange: dateRange);
      final list = res.map((e) => FishingGroundEntity.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, history: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final fishingGroundProvider = StateNotifierProvider<FishingGroundNotifier, FishingGroundState>((ref) {
  return FishingGroundNotifier(ref.watch(boatOwnerApiProvider));
});
