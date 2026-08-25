// lib/features/boat_owner/presentation/providers/fishing_location_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/boat_owner_api_service.dart';

// ── Model ──────────────────────────────────────────────────────────────────────
class FishingLocation {
  final String id;
  final String boatId;
  final String boatName;
  final DateTime date;
  final double latitude;
  final double longitude;

  FishingLocation({
    required this.id,
    required this.boatId,
    required this.boatName,
    required this.date,
    required this.latitude,
    required this.longitude,
  });

  factory FishingLocation.fromJson(Map<String, dynamic> json) {
    final boatData = json['boatId'];
    String boatId = '';
    String boatName = '';
    if (boatData is Map<String, dynamic>) {
      boatId = boatData['_id'] ?? '';
      boatName = '${boatData['boatNumber'] ?? ''} - ${boatData['boatName'] ?? ''}'.trim();
    } else {
      boatId = boatData?.toString() ?? '';
    }

    return FishingLocation(
      id: json['_id'] ?? '',
      boatId: boatId,
      boatName: boatName,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}

// ── State ──────────────────────────────────────────────────────────────────────
class FishingLocationState {
  final List<FishingLocation> locations;
  final bool isLoading;
  final String? error;

  FishingLocationState({
    this.locations = const [],
    this.isLoading = false,
    this.error,
  });

  FishingLocationState copyWith({
    List<FishingLocation>? locations,
    bool? isLoading,
    String? error,
  }) {
    return FishingLocationState(
      locations: locations ?? this.locations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────
class FishingLocationNotifier extends StateNotifier<FishingLocationState> {
  final BoatOwnerApiService _api;

  FishingLocationNotifier(this._api) : super(FishingLocationState()) {
    loadLocations();
  }

  Future<void> loadLocations({String? boatId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getFishingLocations(boatId: boatId, limit: 100);
      final List data = res['data'] ?? [];
      state = state.copyWith(
        locations: data.map((e) => FishingLocation.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Upsert — backend handles "one per boat per day" rule automatically.
  Future<bool> saveLocation({
    required String boatId,
    required DateTime date,
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final saved = await _api.saveFishingLocation({
        'boatId': boatId,
        'date': date.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      });
      final newLoc = FishingLocation.fromJson(saved);

      // Update local list: replace if same boatId+date, else prepend
      final updated = List<FishingLocation>.from(state.locations);
      final idx = updated.indexWhere((l) =>
          l.boatId == newLoc.boatId &&
          l.date.year == newLoc.date.year &&
          l.date.month == newLoc.date.month &&
          l.date.day == newLoc.date.day);
      if (idx >= 0) {
        updated[idx] = newLoc;
      } else {
        updated.insert(0, newLoc);
      }

      state = state.copyWith(locations: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteLocation(String id) async {
    try {
      await _api.deleteFishingLocation(id);
      state = state.copyWith(
        locations: state.locations.where((l) => l.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
final fishingLocationProvider =
    StateNotifierProvider<FishingLocationNotifier, FishingLocationState>((ref) {
  final api = BoatOwnerApiService(ref.watch(dioClientProvider));
  return FishingLocationNotifier(api);
});
