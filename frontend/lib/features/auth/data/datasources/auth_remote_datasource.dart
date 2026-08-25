import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
  Future<void> logout();
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword);
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile(Map<String, dynamic> data);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(DioClient client) : _dio = client.dio;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      print('📡 Making login request to: ${ApiConstants.baseUrl}${ApiConstants.login}');
      print('📦 Request body: ${request.toJson()}');
      
      final response = await _dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');
      
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Server returned ${response.statusCode}',
        );
      }
      
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status: ${e.response?.statusCode}');
      
      // If there's a response with data, try to extract the error message
      if (e.response?.data != null) {
        final data = e.response?.data as Map<String, dynamic>;
        final message = data['message'] ?? 'Unknown error';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          error: message,
        );
      }
      rethrow;
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {
      // Best-effort: always clear local session even if server call fails
    }
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    await _dio.post(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiConstants.profile);
    final data = (response.data['data'] ?? response.data) as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put(
      ApiConstants.profile,
      data: data,
    );
    final responseData = (response.data['data'] ?? response.data) as Map<String, dynamic>;
    return UserModel.fromJson(responseData);
  }
}