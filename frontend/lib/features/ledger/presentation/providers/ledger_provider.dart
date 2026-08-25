import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/ledger_entity.dart';
import '../../data/models/ledger_model.dart';
import '../../data/datasources/ledger_remote_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';


class LedgerRepositoryImpl {
  final LedgerRemoteDataSource _remote;
  LedgerRepositoryImpl(DioClient client) : _remote = LedgerRemoteDataSourceImpl(client);

  Future<List<LedgerEntity>> getLedger({String? boatId}) => _remote.getLedgerEntries(boatId: boatId);
  Future<BoatBalanceModel> getBoatBalance(String boatId) => _remote.getBoatBalance(boatId);
  Future<List<BoatBalanceModel>> getAllBalances() => _remote.getAllBoatBalances();
}

final ledgerRepositoryProvider = Provider<LedgerRepositoryImpl>((ref) => LedgerRepositoryImpl(ref.watch(dioClientProvider)));

class LedgerState {
  final List<LedgerEntity> entries;
  final List<BoatBalanceModel> balances;
  final BoatBalanceModel? selectedBalance;
  final bool isLoading;
  final String? error;
  const LedgerState({this.entries = const [], this.balances = const [], this.selectedBalance, this.isLoading = false, this.error});
  LedgerState copyWith({List<LedgerEntity>? entries, List<BoatBalanceModel>? balances, BoatBalanceModel? selectedBalance, bool? isLoading, String? error}) =>
      LedgerState(entries: entries ?? this.entries, balances: balances ?? this.balances, selectedBalance: selectedBalance ?? this.selectedBalance, isLoading: isLoading ?? this.isLoading, error: error);
}

class LedgerNotifier extends StateNotifier<LedgerState> {
  final LedgerRepositoryImpl _repo;
  LedgerNotifier(this._repo) : super(const LedgerState()) { load(); }

  Future<void> load({String? boatId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final entries = await _repo.getLedger(boatId: boatId);
      final balances = await _repo.getAllBalances();
      state = state.copyWith(entries: entries, balances: balances, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  Future<void> loadBoatBalance(String boatId) async {
    try { state = state.copyWith(selectedBalance: await _repo.getBoatBalance(boatId)); } catch (_) {}
  }
}

final ledgerProvider = StateNotifierProvider<LedgerNotifier, LedgerState>((ref) => LedgerNotifier(ref.watch(ledgerRepositoryProvider)));
