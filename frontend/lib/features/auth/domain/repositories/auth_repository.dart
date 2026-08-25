import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<void> logout();
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword);
  Future<UserEntity?> getStoredUser();
  Future<UserEntity> updateProfile(Map<String, dynamic> data);
}
