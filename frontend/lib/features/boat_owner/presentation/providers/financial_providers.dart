import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/boat_owner_api_service.dart';
import '../../domain/entities/financial_models.dart';
import 'document_providers.dart'; // To get the apiServiceRef or authRef

// States definition
class FinancialDashboardState {
  final bool isLoading;
  final String? error;
  final FinancialDashboardData? data;
  final String selectedPeriod;
  final DateTimeRange? dateRange;

  FinancialDashboardState({
    this.isLoading = false,
    this.error,
    this.data,
    this.selectedPeriod = 'This Month',
    this.dateRange,
  });

  FinancialDashboardState copyWith({
    bool? isLoading,
    String? error,
    FinancialDashboardData? data,
    String? selectedPeriod,
    DateTimeRange? dateRange,
  }) {
    return FinancialDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      data: data ?? this.data,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

class FinancialVoyagesState {
  final bool isLoading;
  final String? error;
  final List<VoyagePLListItem> voyages;

  FinancialVoyagesState({
    this.isLoading = false,
    this.error,
    this.voyages = const [],
  });

  FinancialVoyagesState copyWith({
    bool? isLoading,
    String? error,
    List<VoyagePLListItem>? voyages,
  }) {
    return FinancialVoyagesState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      voyages: voyages ?? this.voyages,
    );
  }
}

class VoyagePLSummaryState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final VoyagePLSummaryData? data;

  VoyagePLSummaryState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.data,
  });

  VoyagePLSummaryState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    VoyagePLSummaryData? data,
  }) {
    return VoyagePLSummaryState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
      data: data ?? this.data,
    );
  }
}

// Providers definition
final financialDashboardProvider =
    StateNotifierProvider<FinancialDashboardNotifier, FinancialDashboardState>((ref) {
  // Leverage apiService ref exposed from document_providers
  final apiService = ref.watch(documentProvider.notifier).apiService;
  return FinancialDashboardNotifier(apiService);
});

final financialVoyagesProvider =
    StateNotifierProvider<FinancialVoyagesNotifier, FinancialVoyagesState>((ref) {
  final apiService = ref.watch(documentProvider.notifier).apiService;
  return FinancialVoyagesNotifier(apiService);
});

final voyagePLSummaryProvider = StateNotifierProvider.family<
    VoyagePLSummaryNotifier, VoyagePLSummaryState, String>((ref, voyageId) {
  final apiService = ref.watch(documentProvider.notifier).apiService;
  return VoyagePLSummaryNotifier(apiService, voyageId);
});

// Notifiers
class FinancialDashboardNotifier extends StateNotifier<FinancialDashboardState> {
  final BoatOwnerApiService _apiService;

  FinancialDashboardNotifier(this._apiService) : super(FinancialDashboardState());

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      String? startDate;
      String? endDate;

      if (state.selectedPeriod == 'Custom' && state.dateRange != null) {
        startDate = state.dateRange!.start.toIso8601String();
        endDate = state.dateRange!.end.toIso8601String();
      }

      final res = await _apiService.getFinancialDashboard(
        period: state.selectedPeriod,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        isLoading: false,
        data: FinancialDashboardData.fromJson(res),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updatePeriod(String period, {DateTimeRange? range}) {
    state = state.copyWith(selectedPeriod: period, dateRange: range);
    fetchDashboard();
  }
}

class FinancialVoyagesNotifier extends StateNotifier<FinancialVoyagesState> {
  final BoatOwnerApiService _apiService;

  FinancialVoyagesNotifier(this._apiService) : super(FinancialVoyagesState());

  Future<void> fetchVoyages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getFinancialVoyages();
      final list = res.map((e) => VoyagePLListItem.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, voyages: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class VoyagePLSummaryNotifier extends StateNotifier<VoyagePLSummaryState> {
  final BoatOwnerApiService _apiService;
  final String _voyageId;

  VoyagePLSummaryNotifier(this._apiService, this._voyageId)
      : super(VoyagePLSummaryState());

  Future<void> fetchSummary() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getVoyageFinancialSummary(_voyageId);
      state = state.copyWith(
        isLoading: false,
        data: VoyagePLSummaryData.fromJson(res),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateRates(List<Map<String, dynamic>> rates) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _apiService.updateCatchRates(_voyageId, rates);
      state = state.copyWith(isSaving: false);
      fetchSummary();
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  Future<void> addOtherIncome(String name, double amount) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _apiService.addOtherIncome(_voyageId, name, amount);
      state = state.copyWith(isSaving: false);
      fetchSummary();
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  Future<void> deleteOtherIncome(String id) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _apiService.deleteOtherIncome(_voyageId, id);
      state = state.copyWith(isSaving: false);
      fetchSummary();
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  Future<void> updateExpenses(List<Map<String, dynamic>> expenses) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _apiService.updateExpenses(_voyageId, expenses);
      state = state.copyWith(isSaving: false);
      fetchSummary();
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  Future<void> addCustomExpense(String name, double qty, String unit, double rate) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _apiService.addCustomExpense(_voyageId, {
        'expenseName': name,
        'quantity': qty,
        'unit': unit,
        'rate': rate,
      });
      state = state.copyWith(isSaving: false);
      fetchSummary();
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  Future<void> deleteCustomExpense(String id) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _apiService.deleteCustomExpense(_voyageId, id);
      state = state.copyWith(isSaving: false);
      fetchSummary();
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  Future<void> updateCrewSettlement(List<Map<String, dynamic>> settlements) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _apiService.updateCrewSettlement(_voyageId, settlements);
      state = state.copyWith(isSaving: false);
      fetchSummary();
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }
}
