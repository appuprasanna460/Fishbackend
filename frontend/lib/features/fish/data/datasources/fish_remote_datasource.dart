import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/fish_model.dart';

abstract class FishRemoteDataSource {
  Future<List<FishModel>> getFish({String? search});
  Future<FishModel> createFish(Map<String, dynamic> data);
  Future<FishModel> updateFish(String id, Map<String, dynamic> data);
  Future<void> deleteFish(String id);
  Future<List<FishModel>> getFishByAgent(String agentId);
}

class FishRemoteDataSourceImpl implements FishRemoteDataSource {
  final Dio _dio;
  FishRemoteDataSourceImpl(DioClient client) : _dio = client.dio;

  List<FishModel> _parse(dynamic data) {
    final list = data['data'] ?? data;
    if (list == null) return [];
    if (list is List) {
      return list
          .map((e) => FishModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<FishModel>> getFish({String? search}) async {
    final res = await _dio.get(
      ApiConstants.fish,
      queryParameters: {if (search != null) 'search': search},
    );
    return _parse(res.data);
  }

  @override
  Future<FishModel> createFish(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.fish, data: data);
    return FishModel.fromJson(
      (res.data['data'] ?? res.data) as Map<String, dynamic>,
    );
  }

  @override
  Future<FishModel> updateFish(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.fish}/$id', data: data);
    return FishModel.fromJson(
      (res.data['data'] ?? res.data) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<FishModel>> getFishByAgent(String agentId) async {
    final res = await _dio.get('${ApiConstants.fish}/agent/$agentId');
    return _parse(res.data);
  }

  @override
  Future<void> deleteFish(String id) async =>
      await _dio.delete('${ApiConstants.fish}/$id');
}
