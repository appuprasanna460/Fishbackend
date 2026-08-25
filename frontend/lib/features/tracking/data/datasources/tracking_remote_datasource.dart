import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/tracking_model.dart';

abstract class TrackingRemoteDataSource {
  Future<List<TrackingModel>> getAllBoatLocations();
  Future<TrackingModel> getLatestCoordinates(String boatId);
  Future<TrackingHistoryModel> getCoordinatesHistory(String boatId, {int hours = 24});
  Future<void> submitCoordinates(String boatId, Map<String, dynamic> data);
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  final Dio _dio;
  TrackingRemoteDataSourceImpl(DioClient client) : _dio = client.dio;

  @override
  Future<List<TrackingModel>> getAllBoatLocations() async {
    final res = await _dio.get('${ApiConstants.tracking}/locations/all');
    final list = res.data['data'] ?? res.data;
    return (list as List).map((e) => TrackingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<TrackingModel> getLatestCoordinates(String boatId) async {
    final res = await _dio.get('${ApiConstants.tracking}/$boatId/latest');
    return TrackingModel.fromJson((res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  @override
  Future<TrackingHistoryModel> getCoordinatesHistory(String boatId, {int hours = 24}) async {
    final res = await _dio.get('${ApiConstants.tracking}/$boatId/history', queryParameters: {'hours': hours});
    return TrackingHistoryModel.fromJson((res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  @override
Future<void> submitCoordinates(String boatId, Map<String, dynamic> data) async {
    await _dio.post('${ApiConstants.tracking}/$boatId', data: data);
  }
}
