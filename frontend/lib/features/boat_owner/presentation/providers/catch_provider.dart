import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/boat_owner_api_service.dart';
import '../../domain/entities/catch_entity.dart';
import 'crew_provider.dart';

class CatchState {
  final bool isLoading;
  final String? error;
  final List<CatchEntity> catchesForHaul;
  final bool hasPendingCatch;

  CatchState({
    this.isLoading = false,
    this.error,
    this.catchesForHaul = const [],
    this.hasPendingCatch = false,
  });

  CatchState copyWith({
    bool? isLoading,
    String? error,
    List<CatchEntity>? catchesForHaul,
    bool? hasPendingCatch,
  }) {
    return CatchState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      catchesForHaul: catchesForHaul ?? this.catchesForHaul,
      hasPendingCatch: hasPendingCatch ?? this.hasPendingCatch,
    );
  }
}

class CatchNotifier extends StateNotifier<CatchState> {
  final BoatOwnerApiService _apiService;

  CatchNotifier(this._apiService) : super(CatchState());

  Future<void> fetchCatchesByHaul(String haulId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getCatchesByHaul(haulId);
      final list = res.map((e) => CatchEntity.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, catchesForHaul: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> checkPendingCatch(String haulId) async {
    try {
      final isPending = await _apiService.hasPendingCatch(haulId);
      state = state.copyWith(hasPendingCatch: isPending);
    } catch (e) {
      state = state.copyWith(hasPendingCatch: false);
    }
  }

  Future<void> createCatch(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createCatch(data);
      if (data['haulId'] != null) {
        await fetchCatchesByHaul(data['haulId']);
        await checkPendingCatch(data['haulId']);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateCatch(String id, Map<String, dynamic> data, String haulId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateCatch(id, data);
      await fetchCatchesByHaul(haulId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteCatch(String id, String haulId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.deleteCatch(id);
      await fetchCatchesByHaul(haulId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final catchProvider = StateNotifierProvider<CatchNotifier, CatchState>((ref) {
  return CatchNotifier(ref.watch(boatOwnerApiProvider));
});
