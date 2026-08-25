import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/bill_model.dart';
import '../../domain/entities/bill_entity.dart';

abstract class BillingRemoteDataSource {
  // ✅ THIS MUST RETURN List<BillEntity>
  Future<List<BillEntity>> getBills({
    int page = 1,
    int limit = 20,
    String? boatId,
    String? status,
    String? startDate,
    String? endDate,
  });
  Future<BillEntity> getBillById(String id);
  Future<BillEntity> createBill(Map<String, dynamic> data);
  Future<BillEntity> updateBill(String id, Map<String, dynamic> data);
  Future<void> deleteBill(String id);
}

class BillingRemoteDataSourceImpl implements BillingRemoteDataSource {
  final Dio _dio;
  BillingRemoteDataSourceImpl(DioClient client) : _dio = client.dio;

  // ✅ THIS MUST RETURN List<BillEntity>
  List<BillEntity> _parseList(dynamic data) {
    final list = data['data'] ?? data;
    if (list == null) return <BillEntity>[];
    if (list is List) {
      return list.map((e) {
        final model = BillModel.fromJson(e as Map<String, dynamic>);
        return model.toEntity();
      }).toList();
    }
    if (list is Map) {
      final items = list['bills'] ?? list['items'] ?? [];
      if (items == null) return <BillEntity>[];
      return (items as List).map((e) {
        final model = BillModel.fromJson(e as Map<String, dynamic>);
        return model.toEntity();
      }).toList();
    }
    return <BillEntity>[];
  }

  @override
  Future<List<BillEntity>> getBills({
    int page = 1,
    int limit = 20,
    String? boatId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final res = await _dio.get(
      ApiConstants.bills,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (boatId != null) 'boatId': boatId,
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    return _parseList(res.data);
  }

  @override
  Future<BillEntity> getBillById(String id) async {
    final res = await _dio.get('${ApiConstants.bills}/$id');
    return BillModel.fromJson(
      (res.data['data'] ?? res.data) as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<BillEntity> createBill(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(ApiConstants.bills, data: data);
      print('🟢 [API] createBill response status: ${res.statusCode}');
      print('🟢 [API] createBill response data: ${res.data}');

      // ✅ Extract the bill data from the response
      final billData = res.data['data'] ?? res.data;
      print('🟢 [API] billData: $billData');

      final model = BillModel.fromJson(billData as Map<String, dynamic>);
      print('🟢 [API] BillModel created: ${model.billNumber}');

      return model.toEntity();
    } catch (e) {
      print('🔴 [API] createBill error: $e');
      rethrow;
    }
  }

  @override
  Future<BillEntity> updateBill(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.bills}/$id', data: data);
    return BillModel.fromJson(
      (res.data['data'] ?? res.data) as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<void> deleteBill(String id) async {
    await _dio.delete('${ApiConstants.bills}/$id');
  }
}
