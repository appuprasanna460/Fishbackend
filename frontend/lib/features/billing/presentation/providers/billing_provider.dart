// lib/features/billing/presentation/providers/billing_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/bill_entity.dart';
import '../../data/datasources/billing_remote_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BillingRepositoryImpl {
  final BillingRemoteDataSource _remote;

  BillingRepositoryImpl(DioClient client)
    : _remote = BillingRemoteDataSourceImpl(client);

  //  THESE MUST RETURN BillEntity
  Future<List<BillEntity>> getBills({String? boatId, String? status}) =>
      _remote.getBills(boatId: boatId, status: status);
  Future<BillEntity> getBillById(String id) => _remote.getBillById(id);
  Future<BillEntity> createBill(Map<String, dynamic> d) =>
      _remote.createBill(d);
  Future<BillEntity> updateBill(String id, Map<String, dynamic> d) =>
      _remote.updateBill(id, d);
  Future<void> deleteBill(String id) => _remote.deleteBill(id);
}

final billingRepositoryProvider = Provider<BillingRepositoryImpl>(
  (ref) => BillingRepositoryImpl(ref.watch(dioClientProvider)),
);

class BillingState {
  final List<BillEntity> bills;
  final BillEntity? selected;
  final bool isLoading;
  final String? error;

  const BillingState({
    this.bills = const <BillEntity>[],
    this.selected,
    this.isLoading = false,
    this.error,
  });

  BillingState copyWith({
    List<BillEntity>? bills,
    BillEntity? selected,
    bool? isLoading,
    String? error,
  }) => BillingState(
    bills: bills ?? this.bills,
    selected: selected ?? this.selected,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class BillingNotifier extends StateNotifier<BillingState> {
  final BillingRepositoryImpl _repo;

  BillingNotifier(this._repo) : super(const BillingState());

  Future<void> load({String? boatId, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final List<BillEntity> bills = await _repo.getBills(
        boatId: boatId,
        status: status,
      );
      state = state.copyWith(bills: bills, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> loadById(String id) async {
    try {
      state = state.copyWith(selected: await _repo.getBillById(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<BillEntity?> createBill(Map<String, dynamic> data) async {
    try {
      print('🟢 [PROVIDER] createBill called with: $data');
      final bill = await _repo.createBill(data);
      print('🟢 [PROVIDER] Bill created: ${bill.billNumber}');
      print('🟢 [PROVIDER] Bill agentName: ${bill.agentName}');
      state = state.copyWith(bills: [bill, ...state.bills]);
      return bill;
    } catch (e) {
      print('🔴 [PROVIDER] createBill error: $e');
      return null;
    }
  }

  Future<bool> updateBill(String id, Map<String, dynamic> data) async {
    try {
      await _repo.updateBill(id, data);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _repo.updateBill(id, {'status': status});
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
        bills: state.bills.where((b) => b.id != id).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final billingProvider = StateNotifierProvider<BillingNotifier, BillingState>(
  (ref) => BillingNotifier(ref.watch(billingRepositoryProvider)),
);
