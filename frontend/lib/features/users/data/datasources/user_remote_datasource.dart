import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<List<UserModel>> getUsers({
    String? role,
    String? search,
    String? harbourId,
    int page = 1,
    int limit = 20,
  });
  Future<UserModel> getUserById(String id);
  Future<UserModel> createUser(Map<String, dynamic> data);
  Future<UserModel> updateUser(String id, Map<String, dynamic> data);
  Future<void> toggleUserStatus(String id);
  Future<void> deleteUser(String id);

  // Commission agent staff management
  Future<List<UserModel>> getMyStaff();
  Future<UserModel> createMyStaff(Map<String, dynamic> data);
  Future<UserModel> updateMyStaff(String id, Map<String, dynamic> data);
  Future<void> deleteMyStaff(String id);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final Dio _dio;
  UserRemoteDataSourceImpl(DioClient client) : _dio = client.dio;

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
  }

  void _handleError(dynamic data) {
    final msg = _extractMessage(data);
    if (msg != null) throw Exception(msg);
  }

  @override
  Future<List<UserModel>> getUsers({
    String? role,
    String? search,
    String? harbourId,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      ApiConstants.users,
      queryParameters: {
        if (role != null && role != 'ALL') 'role': role,
        if (search != null && search.trim().isNotEmpty) 'search': search,
        if (harbourId != null && harbourId.isNotEmpty) 'harbourId': harbourId,
        'page': page,
        'limit': limit,
      },
    );
    final body = res.data;
    if (body is Map<String, dynamic> && body['success'] == false) {
      _handleError(body);
    }
    final list = body['data'] ?? body;
    final items = list is Map ? list['users'] ?? list['items'] ?? [] : list;
    if (items is! List)
      throw Exception('Invalid response format: expected list of users');
    return items.map((e) {
      if (e is! Map<String, dynamic>)
        throw Exception('Invalid user format in response');
      return UserModel.fromJson(e);
    }).toList();
  }

  @override
  Future<UserModel> getUserById(String id) async {
    final res = await _dio.get('${ApiConstants.users}/$id');
    final body = res.data;
    if (body is Map<String, dynamic> && body['success'] == false) {
      _handleError(body);
    }
    final data = body['data'] ?? body;
    if (data is! Map<String, dynamic>)
      throw Exception('Invalid response format');
    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.users, data: data);
    final body = res.data;
    if (body is Map<String, dynamic> && body['success'] == false) {
      _handleError(body);
    }
    final data_ = body['data'] ?? body;
    if (data_ is! Map<String, dynamic>)
      throw Exception('Invalid response format');
    return UserModel.fromJson(data_);
  }

  @override
  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.users}/$id', data: data);
    final body = res.data;
    if (body is Map<String, dynamic> && body['success'] == false) {
      _handleError(body);
    }
    final data_ = body['data'] ?? body;
    if (data_ is! Map<String, dynamic>)
      throw Exception('Invalid response format');
    return UserModel.fromJson(data_);
  }

  @override
  Future<void> toggleUserStatus(String id) async {
    await _dio.patch('${ApiConstants.users}/$id/toggle-status');
  }

  @override
  Future<void> deleteUser(String id) async {
    await _dio.delete('${ApiConstants.users}/$id');
  }

  @override
  Future<List<UserModel>> getMyStaff() async {
    final res = await _dio.get('${ApiConstants.users}/my-staff');
    final body = res.data;
    if (body is Map<String, dynamic> && body['success'] == false) {
      _handleError(body);
    }
    final list = body['data'] ?? body;
    final items = list is Map ? list['users'] ?? list['items'] ?? [] : list;
    if (items is! List)
      throw Exception('Invalid response format: expected list of staff');
    return items.map((e) {
      if (e is! Map<String, dynamic>)
        throw Exception('Invalid staff format in response');
      return UserModel.fromJson(e);
    }).toList();
  }

  @override
  Future<UserModel> createMyStaff(Map<String, dynamic> data) async {
    final res = await _dio.post('${ApiConstants.users}/my-staff', data: data);
    final body = res.data;
    if (body is Map<String, dynamic> && body['success'] == false) {
      _handleError(body);
    }
    final data_ = body['data'] ?? body;
    if (data_ is! Map<String, dynamic>)
      throw Exception('Invalid response format');
    return UserModel.fromJson(data_);
  }

  @override
  Future<UserModel> updateMyStaff(String id, Map<String, dynamic> data) async {
    final res = await _dio.put(
      '${ApiConstants.users}/my-staff/$id',
      data: data,
    );
    final body = res.data;
    if (body is Map<String, dynamic> && body['success'] == false) {
      _handleError(body);
    }
    final data_ = body['data'] ?? body;
    if (data_ is! Map<String, dynamic>)
      throw Exception('Invalid response format');
    return UserModel.fromJson(data_);
  }

  @override
  Future<void> deleteMyStaff(String id) async {
    await _dio.delete('${ApiConstants.users}/my-staff/$id');
  }
}
