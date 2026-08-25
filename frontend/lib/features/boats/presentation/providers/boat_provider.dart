import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/boat_entity.dart';
import '../../data/datasources/boat_remote_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BoatRepositoryImpl {
  final BoatRemoteDataSource _remote;
  BoatRepositoryImpl(DioClient client)
    : _remote = BoatRemoteDataSourceImpl(client);

  Future<List<BoatEntity>> getBoats({String? search, String? ownerId}) =>
      _remote.getBoats(search: search, ownerId: ownerId);
  Future<BoatEntity> getBoatById(String id) => _remote.getBoatById(id);
  Future<BoatEntity> createBoat(Map<String, dynamic> d) =>
      _remote.createBoat(d);
  Future<BoatEntity> updateBoat(String id, Map<String, dynamic> d) =>
      _remote.updateBoat(id, d);
  Future<void> deleteBoat(String id) => _remote.deleteBoat(id);
  Future<List<BoatEntity>> getBoatsByAgent(String agentId) =>
      _remote.getBoatsByAgent(agentId);
}

final boatRepositoryProvider = Provider<BoatRepositoryImpl>(
  (ref) => BoatRepositoryImpl(ref.watch(dioClientProvider)),
);

class BoatState {
  final List<BoatEntity> boats;
  final BoatEntity? selected;
  final bool isLoading;
  final String? error;
  const BoatState({
    this.boats = const [],
    this.selected,
    this.isLoading = false,
    this.error,
  });
  BoatState copyWith({
    List<BoatEntity>? boats,
    BoatEntity? selected,
    bool? isLoading,
    String? error,
  }) => BoatState(
    boats: boats ?? this.boats,
    selected: selected ?? this.selected,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class BoatNotifier extends StateNotifier<BoatState> {
  final BoatRepositoryImpl _repo;
  BoatNotifier(this._repo) : super(const BoatState());

  Future<void> load({String? search, String? ownerId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      state = state.copyWith(
        boats: await _repo.getBoats(search: search, ownerId: ownerId),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> loadById(String id) async {
    try {
      state = state.copyWith(selected: await _repo.getBoatById(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createBoat(Map<String, dynamic> data) async {
    try {
      final boat = await _repo.createBoat(data);
      state = state.copyWith(boats: [boat, ...state.boats]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateBoat(String id, Map<String, dynamic> data) async {
    try {
      await _repo.updateBoat(id, data);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBoat(String id) async {
    try {
      await _repo.deleteBoat(id);
      state = state.copyWith(
        boats: state.boats.where((b) => b.id != id).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final boatProvider = StateNotifierProvider<BoatNotifier, BoatState>(
  (ref) => BoatNotifier(ref.watch(boatRepositoryProvider)),
);

final selectedBoatFilterProvider = StateProvider<BoatEntity?>((ref) => null);
