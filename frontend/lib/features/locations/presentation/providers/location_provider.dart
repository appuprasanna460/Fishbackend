import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/location_entity.dart';
import '../../data/datasources/location_remote_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LocationRepositoryImpl {
  final LocationRemoteDataSource _remote;
  LocationRepositoryImpl(DioClient client) : _remote = LocationRemoteDataSourceImpl(client);

  Future<List<LocationEntity>> getLocations() => _remote.getLocations();
  Future<LocationEntity> createLocation(Map<String, dynamic> d) => _remote.createLocation(d);
  Future<LocationEntity> updateLocation(String id, Map<String, dynamic> d) => _remote.updateLocation(id, d);
  Future<void> deleteLocation(String id) => _remote.deleteLocation(id);
  Future<SubLocationEntity> createSubLocation(Map<String, dynamic> d) => _remote.createSubLocation(d);
  Future<SubLocationEntity> updateSubLocation(String id, Map<String, dynamic> d) => _remote.updateSubLocation(id, d);
  Future<void> deleteSubLocation(String id) => _remote.deleteSubLocation(id);
}

final locationRepositoryProvider = Provider<LocationRepositoryImpl>((ref) {
  return LocationRepositoryImpl(ref.watch(dioClientProvider));
});

class LocationState {
  final List<LocationEntity> locations;
  final bool isLoading;
  final String? error;
  const LocationState({this.locations = const [], this.isLoading = false, this.error});
  LocationState copyWith({List<LocationEntity>? locations, bool? isLoading, String? error}) =>
      LocationState(locations: locations ?? this.locations, isLoading: isLoading ?? this.isLoading, error: error);
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationRepositoryImpl _repo;
  LocationNotifier(this._repo) : super(const LocationState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final locs = await _repo.getLocations();
      state = state.copyWith(locations: locs, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  Future<bool> createLocation(String name, {String? state_, String? district}) async {
    try {
      await _repo.createLocation({'name': name, if (state_ != null) 'state': state_, if (district != null) 'district': district});
      await load(); return true;
    } catch (_) { return false; }
  }

  Future<bool> updateLocation(String id, String name) async {
    try { await _repo.updateLocation(id, {'name': name}); await load(); return true; } catch (_) { return false; }
  }

  Future<bool> deleteLocation(String id) async {
    try { await _repo.deleteLocation(id); await load(); return true; } catch (_) { return false; }
  }

  Future<bool> createSubLocation(String name, String locationId) async {
    try { await _repo.createSubLocation({'name': name, 'locationId': locationId}); await load(); return true; } catch (_) { return false; }
  }

  Future<bool> deleteSubLocation(String id) async {
    try { await _repo.deleteSubLocation(id); await load(); return true; } catch (_) { return false; }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier(ref.watch(locationRepositoryProvider));
});