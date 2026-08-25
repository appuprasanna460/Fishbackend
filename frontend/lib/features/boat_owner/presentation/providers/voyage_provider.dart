import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/boat_owner_api_service.dart';
import '../../domain/entities/voyage_entity.dart';

class VoyageState {
  final List<VoyageEntity> voyages;
  final VoyageEntity? currentVoyage;
  final int activeVoyagesCount;
  final int boatsAtSeaCount;
  final double todaySales;
  final bool isLoading;
  final String? error;

  VoyageState({
    this.voyages = const [],
    this.currentVoyage,
    this.activeVoyagesCount = 0,
    this.boatsAtSeaCount = 0,
    this.todaySales = 0.0,
    this.isLoading = false,
    this.error,
  });

  VoyageState copyWith({
    List<VoyageEntity>? voyages,
    VoyageEntity? currentVoyage,
    int? activeVoyagesCount,
    int? boatsAtSeaCount,
    double? todaySales,
    bool? isLoading,
    String? error,
  }) {
    return VoyageState(
      voyages: voyages ?? this.voyages,
      currentVoyage: currentVoyage ?? this.currentVoyage,
      activeVoyagesCount: activeVoyagesCount ?? this.activeVoyagesCount,
      boatsAtSeaCount: boatsAtSeaCount ?? this.boatsAtSeaCount,
      todaySales: todaySales ?? this.todaySales,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VoyageNotifier extends StateNotifier<VoyageState> {
  final BoatOwnerApiService _api;

  VoyageNotifier(this._api) : super(VoyageState()) {
    loadVoyages();
    loadStats();
  }

  Future<void> loadVoyages({String? status, String? boatId, String? dateRange, String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final List rawVoyages = await _api.getVoyages(
        status: status,
        boatId: boatId,
        dateRange: dateRange,
        search: search,
      );
      final list = rawVoyages.map((e) => VoyageEntity.fromJson(e)).toList();
      state = state.copyWith(voyages: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _api.getVoyageStats();
      state = state.copyWith(
        activeVoyagesCount: stats['activeVoyages'] ?? 0,
        boatsAtSeaCount: stats['boatsAtSea'] ?? 0,
        todaySales: (stats['todaySales'] ?? 0).toDouble(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadVoyageById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getVoyageById(id);
      state = state.copyWith(
        currentVoyage: VoyageEntity.fromJson(res),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createVoyage(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.createVoyage(data);
      final newVoyage = VoyageEntity.fromJson(res);
      state = state.copyWith(
        voyages: List<VoyageEntity>.from(state.voyages)..insert(0, newVoyage),
        isLoading: false,
      );
      await loadStats();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateVoyage(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.updateVoyage(id, data);
      final updated = VoyageEntity.fromJson(res);
      state = state.copyWith(
        voyages: state.voyages.map((v) => v.id == id ? updated : v).toList(),
        currentVoyage: state.currentVoyage?.id == id ? updated : state.currentVoyage,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateVoyageStatus(String id, String status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.updateVoyageStatus(id, status);
      final updated = VoyageEntity.fromJson(res);
      state = state.copyWith(
        voyages: state.voyages.map((v) => v.id == id ? updated : v).toList(),
        currentVoyage: state.currentVoyage?.id == id ? updated : state.currentVoyage,
        isLoading: false,
      );
      await loadStats();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteVoyage(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.deleteVoyage(id);
      state = state.copyWith(
        voyages: state.voyages.where((v) => v.id != id).toList(),
        isLoading: false,
      );
      await loadStats();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final voyageProvider = StateNotifierProvider<VoyageNotifier, VoyageState>((ref) {
  final api = BoatOwnerApiService(ref.watch(dioClientProvider));
  return VoyageNotifier(api);
});
