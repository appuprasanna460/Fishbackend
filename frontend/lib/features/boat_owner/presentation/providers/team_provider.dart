import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/boat_owner_api_service.dart';
import '../../domain/entities/crew_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'crew_provider.dart';

class TeamState {
  final bool isLoading;
  final String? error;
  final List<UserEntity> teamMembers;

  TeamState({
    this.isLoading = false,
    this.error,
    this.teamMembers = const [],
  });

  TeamState copyWith({
    bool? isLoading,
    String? error,
    List<UserEntity>? teamMembers,
  }) {
    return TeamState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      teamMembers: teamMembers ?? this.teamMembers,
    );
  }
}

class TeamNotifier extends StateNotifier<TeamState> {
  final BoatOwnerApiService _apiService;

  TeamNotifier(this._apiService) : super(TeamState());

  Future<void> fetchTeam() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getTeam();
      final list = res.map<UserEntity>((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, teamMembers: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTeamMember(Map<String, dynamic> body) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createTeamMember(body);
      await fetchTeam();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateTeamMember(String id, Map<String, dynamic> body) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateTeamMember(id, body);
      await fetchTeam();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> toggleTeamMemberStatus(String id) async {
    try {
      await _apiService.toggleTeamMemberStatus(id);
      await fetchTeam();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTeamMember(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.deleteTeamMember(id);
      await fetchTeam();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final teamProvider = StateNotifierProvider.autoDispose<TeamNotifier, TeamState>((ref) {
  final api = ref.watch(boatOwnerApiProvider);
  return TeamNotifier(api);
});
