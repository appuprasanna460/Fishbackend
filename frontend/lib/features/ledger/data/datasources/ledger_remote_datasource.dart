import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/ledger_model.dart';

abstract class LedgerRemoteDataSource {
  Future<List<LedgerModel>> getLedgerEntries({String? boatId, String? startDate, String? endDate, int page = 1});
  Future<BoatBalanceModel> getBoatBalance(String boatId);
  Future<List<BoatBalanceModel>> getAllBoatBalances();
}

class LedgerRemoteDataSourceImpl implements LedgerRemoteDataSource {
  final Dio _dio;
  LedgerRemoteDataSourceImpl(DioClient client) : _dio = client.dio;

  @override
  Future<List<LedgerModel>> getLedgerEntries({String? boatId, String? startDate, String? endDate, int page = 1}) async {
    final res = await _dio.get(ApiConstants.ledger, queryParameters: {
      'page': page,
      if (boatId != null) 'boatId': boatId,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    });
    final list = res.data['data'] ?? res.data;
    final items = list is Map ? list['entries'] ?? list['items'] ?? [] : list;
    return (items as List).map((e) => LedgerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<BoatBalanceModel> getBoatBalance(String boatId) async {
    final res = await _dio.get('${ApiConstants.ledger}/boat/$boatId/balance');
    return BoatBalanceModel.fromJson((res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  @override
Future<List<BoatBalanceModel>> getAllBoatBalances() async {
    final res = await _dio.get('${ApiConstants.ledger}/balances');
    final list = res.data['data'] ?? res.data;
    return (list as List).map((e) => BoatBalanceModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
