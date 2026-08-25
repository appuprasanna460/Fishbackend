import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

class FishBuyerBillRemoteDataSource {
  final Dio _dio;
  FishBuyerBillRemoteDataSource(DioClient client) : _dio = client.dio;

  Future<List<Map<String, dynamic>>> getBills() async {
    final res = await _dio.get(ApiConstants.fishBuyerBills);
    final list = res.data['data'] ?? res.data ?? [];
    if (list is List) {
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createBill(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.fishBuyerBills, data: data);
    return (res.data['data'] ?? res.data) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getBillsByAgent(String agentId) async {
    final res = await _dio.get(
      '${ApiConstants.fishBuyerBillsByAgent}/$agentId',
    );
    final list = res.data['data'] ?? res.data ?? [];
    if (list is List) {
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  Future<void> cancelBill(String id) async {
    await _dio.put('${ApiConstants.fishBuyerBills}/$id/cancel');
  }

  Future<void> deleteBill(String id) async {
    await _dio.delete('${ApiConstants.fishBuyerBills}/$id');
  }
}
