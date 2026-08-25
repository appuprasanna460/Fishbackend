import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserRepositoryImpl {
  final UserRemoteDataSource _remote;
  UserRepositoryImpl(DioClient client)
    : _remote = UserRemoteDataSourceImpl(client);

  Future<List<UserEntity>> getUsers(
          {String? role, String? search, String? harbourId}) =>
      _remote.getUsers(role: role, search: search, harbourId: harbourId);

  Future<UserEntity> getUserById(String id) => _remote.getUserById(id);
  Future<UserEntity> createUser(Map<String, dynamic> data) =>
      _remote.createUser(data);
  Future<UserEntity> updateUser(String id, Map<String, dynamic> data) =>
      _remote.updateUser(id, data);
  Future<void> toggleUserStatus(String id) => _remote.toggleUserStatus(id);
  Future<void> deleteUser(String id) => _remote.deleteUser(id);

  // Commission agent staff management
  Future<List<UserEntity>> getMyStaff() => _remote.getMyStaff();
  Future<UserEntity> createMyStaff(Map<String, dynamic> data) =>
      _remote.createMyStaff(data);
  Future<UserEntity> updateMyStaff(String id, Map<String, dynamic> data) =>
      _remote.updateMyStaff(id, data);
  Future<void> deleteMyStaff(String id) => _remote.deleteMyStaff(id);
}

final userRepositoryProvider = Provider<UserRepositoryImpl>(
  (ref) => UserRepositoryImpl(ref.watch(dioClientProvider)),
);

class UserState {
  final List<UserEntity> users;
  final List<UserEntity> agents;
  final List<UserEntity> boatOwners;
  final UserEntity? selected;
  final bool isLoading;
  final String? error;
  const UserState({
    this.users = const [],
    this.agents = const [],
    this.boatOwners = const [],
    this.selected,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    List<UserEntity>? users,
    List<UserEntity>? agents,
    List<UserEntity>? boatOwners,
    UserEntity? selected,
    bool? isLoading,
    String? error,
  }) => UserState(
    users: users ?? this.users,
    agents: agents ?? this.agents,
    boatOwners: boatOwners ?? this.boatOwners,
    selected: selected ?? this.selected,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class UserNotifier extends StateNotifier<UserState> {
  final UserRepositoryImpl _repo;
  UserNotifier(this._repo) : super(const UserState()) {
    load();
  }

  Future<void> load({String? role, String? search, String? harbourId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repo.getUsers(
          role: role, search: search, harbourId: harbourId);
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAgents() async {
    try {
      final agents = await _repo.getUsers(role: 'COMMISSION_AGENT');
      state = state.copyWith(agents: agents);
    } catch (_) {}
  }

  Future<void> loadBoatOwners() async {
    try {
      final owners = await _repo.getUsers(role: 'BOAT_OWNER');
      state = state.copyWith(boatOwners: owners);
    } catch (_) {}
  }

  Future<bool> loadById(String id) async {
    try {
      state = state.copyWith(selected: await _repo.getUserById(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createUser(Map<String, dynamic> data) async {
    try {
      final user = await _repo.createUser(data);
      state = state.copyWith(users: [user, ...state.users], error: null);
      return true;
    } catch (e) {
      // ✅ Extract just the error message
      final errorMessage = _extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    try {
      await _repo.updateUser(id, data);
      await load();
      state = state.copyWith(error: null);
      return true;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> toggleUserStatus(String id) async {
    try {
      await _repo.toggleUserStatus(id);
      await load();
      state = state.copyWith(error: null);
      return true;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _repo.deleteUser(id);
      state = state.copyWith(
        users: state.users.where((u) => u.id != id).toList(),
        error: null,
      );
      return true;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  // ── Commission Agent Staff Management ────────────────────────────────

  List<UserEntity> _myStaffCache = [];

  List<UserEntity> get myStaff => _myStaffCache;

  Future<void> loadMyStaff() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final staff = await _repo.getMyStaff();
      _myStaffCache = staff;
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<bool> createMyStaff(Map<String, dynamic> data) async {
    try {
      final staff = await _repo.createMyStaff(data);
      _myStaffCache = [staff, ..._myStaffCache];
      state = state.copyWith(error: null);
      return true;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> updateMyStaff(String id, Map<String, dynamic> data) async {
    try {
      await _repo.updateMyStaff(id, data);
      await loadMyStaff();
      state = state.copyWith(error: null);
      return true;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> deleteMyStaff(String id) async {
    try {
      await _repo.deleteMyStaff(id);
      _myStaffCache = _myStaffCache.where((u) => u.id != id).toList();
      state = state.copyWith(error: null);
      return true;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  // ── Helper to extract clean error message ──────────────────────────────

  String _extractErrorMessage(dynamic error) {
    // If it's a Dio exception, try to get the response data
    if (error is DioException) {
      try {
        // Check if there's a response with data
        if (error.response != null && error.response!.data != null) {
          final responseData = error.response!.data;
          
          // If response is a Map, try to get the message field
          if (responseData is Map<String, dynamic>) {
            final message = responseData['message'];
            if (message != null && message is String && message.isNotEmpty) {
              return message; // This will be "Email already registered"
            }
          }
          
          // If response is a String, return it directly
          if (responseData is String) {
            return responseData;
          }
        }
      } catch (_) {}
      
      // If we can't extract from response, check the error message
      final errorMsg = error.toString();
      
      // Look for "Email already registered" in the error string
      if (errorMsg.contains('Email already registered')) {
        return 'Email already registered';
      }
      
      // Look for other common error patterns
      final patterns = [
        r'message[:\s]+([^,}]+)',
        r'"message"\s*:\s*"([^"]+)"',
        r'message\s*=\s*([^\n]+)',
      ];
      
      for (final pattern in patterns) {
        final match = RegExp(pattern).firstMatch(errorMsg);
        if (match != null) {
          final msg = match.group(1)?.trim().replaceAll('"', '') ?? '';
          if (msg.isNotEmpty && msg != 'null') {
            return msg;
          }
        }
      }
    }
    
    // If it's a general Exception
    if (error is Exception) {
      final msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        return msg.substring(10);
      }
      return msg;
    }
    
    // Default fallback - try to clean up the error
    String errorStr = error.toString();
    
    // Remove stack trace if present
    if (errorStr.contains('Stack trace:')) {
      errorStr = errorStr.split('Stack trace:').first.trim();
    }
    
    // Remove "Exception: " prefix
    if (errorStr.startsWith('Exception: ')) {
      errorStr = errorStr.substring(10);
    }
    
    return errorStr.isNotEmpty ? errorStr : 'Operation failed';
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.read(userRepositoryProvider));
});