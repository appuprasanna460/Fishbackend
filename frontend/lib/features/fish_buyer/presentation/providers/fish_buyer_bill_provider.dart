import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/fish_buyer_bill_datasource.dart';

class FishBuyerBillRepository {
  final FishBuyerBillRemoteDataSource _remote;
  FishBuyerBillRepository(DioClient client)
    : _remote = FishBuyerBillRemoteDataSource(client);

  Future<List<Map<String, dynamic>>> getBills() => _remote.getBills();
  Future<Map<String, dynamic>> createBill(Map<String, dynamic> data) =>
      _remote.createBill(data);
  Future<List<Map<String, dynamic>>> getBillsByAgent(String agentId) =>
      _remote.getBillsByAgent(agentId);
  Future<void> cancelBill(String id) => _remote.cancelBill(id);
  Future<void> deleteBill(String id) => _remote.deleteBill(id);
}

final fishBuyerBillRepositoryProvider = Provider<FishBuyerBillRepository>(
  (ref) => FishBuyerBillRepository(ref.watch(dioClientProvider)),
);

class FishBuyerBillState {
  final List<Map<String, dynamic>> bills;
  final bool isLoading;
  final String? error;

  const FishBuyerBillState({
    this.bills = const [],
    this.isLoading = false,
    this.error,
  });

  FishBuyerBillState copyWith({
    List<Map<String, dynamic>>? bills,
    bool? isLoading,
    String? error,
  }) => FishBuyerBillState(
    bills: bills ?? this.bills,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class FishBuyerBillNotifier extends StateNotifier<FishBuyerBillState> {
  final FishBuyerBillRepository _repo;

  FishBuyerBillNotifier(this._repo) : super(const FishBuyerBillState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bills = await _repo.getBills();
      state = state.copyWith(bills: bills, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> createBill(Map<String, dynamic> data) async {
    try {
      final bill = await _repo.createBill(data);
      state = state.copyWith(bills: [bill, ...state.bills]);
      return bill;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> cancelBill(String id) async {
    try {
      await _repo.cancelBill(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBill(String id) async {
    try {
      await _repo.deleteBill(id);
      state = state.copyWith(
        bills: state.bills.where((b) => b['_id'] != id).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final fishBuyerBillProvider =
    StateNotifierProvider<FishBuyerBillNotifier, FishBuyerBillState>(
      (ref) =>
          FishBuyerBillNotifier(ref.watch(fishBuyerBillRepositoryProvider)),
    );
