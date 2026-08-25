import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/boat_owner_api_service.dart';
import '../../domain/entities/crew_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final boatOwnerApiProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return BoatOwnerApiService(dioClient);
});

class CrewState {
  final bool isLoading;
  final String? error;
  final List<CrewEntity> crewMembers;
  final List<CrewEntity> availableCaptains;
  final List<CrewEntity> availableCrew;

  CrewState({
    this.isLoading = false,
    this.error,
    this.crewMembers = const [],
    this.availableCaptains = const [],
    this.availableCrew = const [],
  });

  CrewState copyWith({
    bool? isLoading,
    String? error,
    List<CrewEntity>? crewMembers,
    List<CrewEntity>? availableCaptains,
    List<CrewEntity>? availableCrew,
  }) {
    return CrewState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // overwrite with null or value
      crewMembers: crewMembers ?? this.crewMembers,
      availableCaptains: availableCaptains ?? this.availableCaptains,
      availableCrew: availableCrew ?? this.availableCrew,
    );
  }
}

class CrewNotifier extends StateNotifier<CrewState> {
  final BoatOwnerApiService _apiService;

  BoatOwnerApiService get apiService => _apiService;

  CrewNotifier(this._apiService) : super(CrewState());

  Future<void> fetchCrew({String? role, bool? isAvailable, String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getCrew(role: role, isAvailable: isAvailable, search: search);
      final crewList = res.map((e) => CrewEntity.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, crewMembers: crewList);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchAvailableCaptains() async {
    try {
      final res = await _apiService.getAvailableCaptains();
      final list = res.map((e) => CrewEntity.fromJson(e)).toList();
      state = state.copyWith(availableCaptains: list);
    } catch (e) {
      // Handle silently or update state error
    }
  }

  Future<void> fetchAvailableCrew() async {
    try {
      final res = await _apiService.getAvailableCrew();
      final list = res.map((e) => CrewEntity.fromJson(e)).toList();
      state = state.copyWith(availableCrew: list);
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> createCrew(CrewEntity crew) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createCrew(crew.toJson());
      await fetchCrew();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateCrew(String id, CrewEntity crew) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateCrew(id, crew.toJson());
      await fetchCrew();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> toggleAvailability(String id) async {
    try {
      await _apiService.toggleAvailability(id);
      await fetchCrew();
      await fetchAvailableCaptains();
      await fetchAvailableCrew();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> deleteCrew(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.deleteCrew(id);
      await fetchCrew();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final crewProvider = StateNotifierProvider<CrewNotifier, CrewState>((ref) {
  return CrewNotifier(ref.watch(boatOwnerApiProvider));
});
