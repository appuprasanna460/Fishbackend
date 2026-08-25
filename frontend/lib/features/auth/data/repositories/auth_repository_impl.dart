import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  AuthRepositoryImpl(DioClient client)
    : _remote = AuthRemoteDataSourceImpl(client);

  @override
  Future<UserEntity> login(String email, String password) async {
    final req = LoginRequest(email: email, password: password);
    final res = await _remote.login(req);

    // Save token first so subsequent calls (like getProfile) are authenticated
    await SecureStorage.saveToken(res.token);

    final user = UserModel.fromJson(res.user);
    await SecureStorage.saveRole(user.role);
    await SecureStorage.saveUserId(user.id);
    await SecureStorage.saveUserName(user.name);
    await SecureStorage.saveUserEmail(user.email);

    // ✅ Save last login date for 30-day session expiry check
    await SecureStorage.saveLastLoginDate(DateTime.now().toIso8601String());

    return user;
  }

  @override
  Future<void> logout() async {
    await _remote.logout();
    await SecureStorage.deleteAll();
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    await _remote.changePassword(currentPassword, newPassword, confirmPassword);
  }

  @override
  Future<UserEntity?> getStoredUser() async {
    final token = await SecureStorage.getToken();
    if (token == null) return null;

    try {
      final user = await _remote.getProfile();
      await SecureStorage.saveRole(user.role);
      await SecureStorage.saveUserId(user.id);
      await SecureStorage.saveUserName(user.name);
      await SecureStorage.saveUserEmail(user.email);
      return user;
    } catch (_) {
      final id = await SecureStorage.getUserId();
      final role = await SecureStorage.getRole();
      final name = await SecureStorage.getUserName();
      final email = await SecureStorage.getUserEmail();
      if (id != null && role != null) {
        return UserModel(
          id: id,
          name: name ?? '',
          email: email ?? '',
          phone: '',
          role: role,
          isActive: true,
        );
      }
      return null;
    }
  }

  @override
  Future<UserEntity> updateProfile(Map<String, dynamic> data) async {
    final user = await _remote.updateProfile(data);
    await SecureStorage.saveUserName(user.name);
    await SecureStorage.saveUserEmail(user.email);
    return user;
  }
}
