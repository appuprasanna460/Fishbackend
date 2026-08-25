import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/fish_entity.dart';
import '../../data/datasources/fish_remote_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FishRepositoryImpl {
  final FishRemoteDataSource _remote;
  FishRepositoryImpl(DioClient client)
    : _remote = FishRemoteDataSourceImpl(client);

  Future<List<FishEntity>> getFish({String? search}) =>
      _remote.getFish(search: search);
  Future<FishEntity> createFish(Map<String, dynamic> d) =>
      _remote.createFish(d);
  Future<FishEntity> updateFish(String id, Map<String, dynamic> d) =>
      _remote.updateFish(id, d);
  Future<void> deleteFish(String id) => _remote.deleteFish(id);
  Future<List<FishEntity>> getFishByAgent(String agentId) =>
      _remote.getFishByAgent(agentId);
}

final fishRepositoryProvider = Provider<FishRepositoryImpl>(
  (ref) => FishRepositoryImpl(ref.watch(dioClientProvider)),
);

class FishState {
  final List<FishEntity> fish;
  final bool isLoading;
  final String? error;
  const FishState({this.fish = const [], this.isLoading = false, this.error});
  FishState copyWith({
    List<FishEntity>? fish,
    bool? isLoading,
    String? error,
  }) => FishState(
    fish: fish ?? this.fish,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class FishNotifier extends StateNotifier<FishState> {
  final FishRepositoryImpl _repo;
  FishNotifier(this._repo) : super(const FishState());

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      state = state.copyWith(
        fish: await _repo.getFish(search: search),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createFish(Map<String, dynamic> data) async {
    try {
      final f = await _repo.createFish(data);
      state = state.copyWith(fish: [f, ...state.fish]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateFish(String id, Map<String, dynamic> data) async {
    try {
      await _repo.updateFish(id, data);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteFish(String id) async {
    try {
      await _repo.deleteFish(id);
      state = state.copyWith(
        fish: state.fish.where((f) => f.id != id).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final fishProvider = StateNotifierProvider<FishNotifier, FishState>(
  (ref) => FishNotifier(ref.watch(fishRepositoryProvider)),
);
