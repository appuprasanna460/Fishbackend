import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ─── Providers ────────────────────────────────────────────────────────────────

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return AuthRepositoryImpl(client);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkStoredSession();
  }

  Future<void> _checkStoredSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.getStoredUser();
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.login(email, password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.changePassword(
        currentPassword,
        newPassword,
        confirmPassword,
      );
      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.updateProfile(data);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      errorMessage: null,
    );
  }

  // ── Route helper ────────────────────────────────────────────────────────────

  /// Returns the correct dashboard route for a given role.
  static String dashboardRouteFor(String role) {
    return switch (role) {
      'SUPER_ADMIN' => '/admin/dashboard',
      'COMMISSION_AGENT' => '/agent/dashboard',
      'BOAT_OWNER' => '/owner/dashboard',
      'STAFF' => '/staff/dashboard',
      'FISH_BUYER' => '/buyer/dashboard',
      _ => '/agent/dashboard',
    };
  }

  // ── Error parsing ────────────────────────────────────────────────────────────

  String _parseError(Object e) {
    // DioException — extract the actual server message first
    if (e is DioException) {
      final response = e.response;
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        final serverMsg = data['message']?.toString();
        if (serverMsg != null && serverMsg.isNotEmpty) {
          return serverMsg;
        }
      }
      // No server message — fall through to status-code / network handling
      final status = response?.statusCode;
      if (status == 401) {
        return 'Incorrect email or password. Please try again.';
      }
      if (status == 403) {
        return 'Your account does not have permission to log in.';
      }
      if (status == 404) {
        return 'Login endpoint not found. Please contact support.';
      }
      if (status != null && status >= 500) {
        return 'Server error. Please try again later.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Connection timed out. Check your network and try again.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Cannot reach the server. Check your network connection and ensure the backend is running.';
      }
      if (e.type == DioExceptionType.badCertificate) {
        return 'SSL/TLS error. Check your server certificate configuration.';
      }
    }

    final s = e.toString();

    // Network / connectivity
    if (s.contains('SocketException') ||
        s.contains('Connection refused') ||
        s.contains('Network is unreachable')) {
      return 'Cannot reach the server. Check your network connection and ensure the backend is running.';
    }
    if (s.contains('timeout') || s.contains('TimeoutException')) {
      return 'Connection timed out. Check your network and try again.';
    }
    if (s.contains('HandshakeException') || s.contains('CERTIFICATE')) {
      return 'SSL/TLS error. Check your server certificate configuration.';
    }

    // Token / format issues
    if (s.contains('token is empty') || s.contains('FormatException')) {
      return 'Unexpected response from server. Please contact support.';
    }

    return 'Something went wrong. Please try again.';
  }
}
