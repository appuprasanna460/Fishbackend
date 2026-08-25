import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/tracking_entity.dart';
import '../../data/datasources/tracking_remote_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class TrackingRepositoryImpl {
  final TrackingRemoteDataSource _remote;
  TrackingRepositoryImpl(DioClient client) : _remote = TrackingRemoteDataSourceImpl(client);

  Future<List<TrackingEntity>> getAllBoatLocations() => _remote.getAllBoatLocations();
  Future<TrackingHistoryEntity> getHistory(String boatId, {int hours = 24}) => _remote.getCoordinatesHistory(boatId, hours: hours);
  Future<void> submitCoordinates(String boatId, double lat, double lng, {double? speed, double? heading}) =>
      _remote.submitCoordinates(boatId, {'latitude': lat, 'longitude': lng, if (speed != null) 'speed': speed, if (heading != null) 'heading': heading, 'recordedAt': DateTime.now().toIso8601String()});
}

final trackingRepositoryProvider = Provider<TrackingRepositoryImpl>((ref) => TrackingRepositoryImpl(ref.watch(dioClientProvider)));

class TrackingState {
  final List<TrackingEntity> boatLocations;
  final TrackingHistoryEntity? history;
  final TrackingEntity? selected;
  final bool isLoading;
  final String? errorMessage;
  const TrackingState({this.boatLocations = const [], this.history, this.selected, this.isLoading = false, this.errorMessage});
  TrackingState copyWith({List<TrackingEntity>? boatLocations, TrackingHistoryEntity? history, TrackingEntity? selected, bool? isLoading, String? errorMessage}) =>
      TrackingState(boatLocations: boatLocations ?? this.boatLocations, history: history ?? this.history, selected: selected ?? this.selected, isLoading: isLoading ?? this.isLoading, errorMessage: errorMessage);
}

class TrackingNotifier extends Notifier<TrackingState> {
  @override
  TrackingState build() {
    Future.microtask(() => loadAll());
    return const TrackingState();
  }

  TrackingRepositoryImpl get _repo => ref.read(trackingRepositoryProvider);

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try { state = state.copyWith(boatLocations: await _repo.getAllBoatLocations(), isLoading: false); }
    catch (e) { state = state.copyWith(isLoading: false, errorMessage: e.toString()); }
  }

  Future<void> loadHistory(String boatId, {int hours = 24}) async {
    try { state = state.copyWith(history: await _repo.getHistory(boatId, hours: hours)); } catch (_) {}
  }

  void selectBoat(TrackingEntity entity) => state = state.copyWith(selected: entity);

  Future<bool> submitCoordinates(String boatId, double lat, double lng, {double? speed, double? heading}) async {
    try { await _repo.submitCoordinates(boatId, lat, lng, speed: speed, heading: heading); return true; } catch (_) { return false; }
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(() => TrackingNotifier());
