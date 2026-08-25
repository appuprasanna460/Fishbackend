import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/location_model.dart';

abstract class LocationRemoteDataSource {
  Future<List<LocationModel>> getLocations();
  Future<LocationModel> createLocation(Map<String, dynamic> data);
  Future<LocationModel> updateLocation(String id, Map<String, dynamic> data);
  Future<void> deleteLocation(String id);
  Future<SubLocationModel> createSubLocation(Map<String, dynamic> data);
  Future<SubLocationModel> updateSubLocation(String id, Map<String, dynamic> data);
  Future<void> deleteSubLocation(String id);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final Dio _dio;
  LocationRemoteDataSourceImpl(DioClient client) : _dio = client.dio;

  List<LocationModel> _parseList(dynamic data) {
    final list = data['data'] ?? data;
    return (list as List).map((e) => LocationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<LocationModel>> getLocations() async {
    final res = await _dio.get(ApiConstants.locations);
    return _parseList(res.data);
  }

  @override
  Future<LocationModel> createLocation(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.locations, data: data);
    return LocationModel.fromJson((res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  @override
  Future<LocationModel> updateLocation(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.locations}/$id', data: data);
    return LocationModel.fromJson((res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteLocation(String id) async {
    await _dio.delete('${ApiConstants.locations}/$id');
  }

  @override
  Future<SubLocationModel> createSubLocation(Map<String, dynamic> data) async {
    final res = await _dio.post('${ApiConstants.locations}/sub-locations', data: data);
    return SubLocationModel.fromJson((res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  @override
  Future<SubLocationModel> updateSubLocation(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.locations}/sub-locations/$id', data: data);
    return SubLocationModel.fromJson((res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  @override
Future<void> deleteSubLocation(String id) async {
    await _dio.delete('${ApiConstants.locations}/sub-locations/$id');
  }
}
