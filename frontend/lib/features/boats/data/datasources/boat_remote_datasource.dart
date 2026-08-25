import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/boat_model.dart';

abstract class BoatRemoteDataSource {
  Future<List<BoatModel>> getBoats({
    int page = 1,
    int limit = 20,
    String? search,
    String? ownerId,
  });
  Future<BoatModel> getBoatById(String id);
  Future<BoatModel> createBoat(Map<String, dynamic> data);
  Future<BoatModel> updateBoat(String id, Map<String, dynamic> data);
  Future<void> deleteBoat(String id);
  Future<List<BoatModel>> getBoatsByAgent(String agentId);
}

class BoatRemoteDataSourceImpl implements BoatRemoteDataSource {
  final Dio _dio;
  BoatRemoteDataSourceImpl(DioClient client) : _dio = client.dio;

  List<BoatModel> _parseList(dynamic data) {
    final list = data['data'] ?? data;
    if (list == null) return [];
    if (list is List) {
      return list
          .map((e) => BoatModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (list is Map) {
      final items = list['boats'] ?? list['items'] ?? [];
      if (items == null) return [];
      return (items as List)
          .map((e) => BoatModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  // In boat_remote_datasource.dart
  Future<List<BoatModel>> getBoats({
    int page = 1,
    int limit = 20,
    String? search,
    String? ownerId,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};

    // ✅ Only add search if it's not empty
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    if (ownerId != null && ownerId.isNotEmpty) {
      params['ownerId'] = ownerId;
    }

    final res = await _dio.get(ApiConstants.boats, queryParameters: params);
    return _parseList(res.data);
  }

  @override
  Future<BoatModel> getBoatById(String id) async {
    final res = await _dio.get('${ApiConstants.boats}/$id');
    return BoatModel.fromJson(
      (res.data['data'] ?? res.data) as Map<String, dynamic>,
    );
  }

  @override
  Future<BoatModel> createBoat(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.boats, data: data);
    return BoatModel.fromJson(
      (res.data['data'] ?? res.data) as Map<String, dynamic>,
    );
  }

  @override
  Future<BoatModel> updateBoat(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.boats}/$id', data: data);
    return BoatModel.fromJson(
      (res.data['data'] ?? res.data) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<BoatModel>> getBoatsByAgent(String agentId) async {
    final res = await _dio.get('${ApiConstants.boats}/agent/$agentId');
    return _parseList(res.data);
  }

  @override
  Future<void> deleteBoat(String id) async =>
      await _dio.delete('${ApiConstants.boats}/$id');
}
