// lib/features/subscription_plan/presentation/providers/subscription_plan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/subscription_plan_repository.dart';
import '../../domain/entities/subscription_plan_entity.dart';

final subscriptionPlanProvider =
    StateNotifierProvider<SubscriptionPlanNotifier, SubscriptionPlanState>((ref) {
      return SubscriptionPlanNotifier(ref);
    });

class SubscriptionPlanState {
  final List<SubscriptionPlanEntity>? plans;
  final List<SubscriptionPlanEntity>? activePlans;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  SubscriptionPlanState({
    this.plans,
    this.activePlans,
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  SubscriptionPlanState copyWith({
    List<SubscriptionPlanEntity>? plans,
    List<SubscriptionPlanEntity>? activePlans,
    bool? isLoading,
    String? error,
    bool? isSaving,
  }) {
    return SubscriptionPlanState(
      plans: plans ?? this.plans,
      activePlans: activePlans ?? this.activePlans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class SubscriptionPlanNotifier extends StateNotifier<SubscriptionPlanState> {
  final Ref _ref;
  final SubscriptionPlanRepository _repository = SubscriptionPlanRepository();

  SubscriptionPlanNotifier(this._ref) : super(SubscriptionPlanState());

  // ✅ Get all plans (Super Admin - includes inactive)
  Future<void> loadAllPlans() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plans = await _repository.getAllPlans();
      state = state.copyWith(plans: plans, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ✅ Get active plans (public - for registration)
  Future<void> loadActivePlans() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plans = await _repository.getActivePlans();
      state = state.copyWith(activePlans: plans, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ✅ Create plan
  Future<bool> createPlan(SubscriptionPlanEntity plan) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final saved = await _repository.createPlan(plan);
      await loadAllPlans();
      await loadActivePlans();
      state = state.copyWith(isSaving: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  // ✅ Update plan
  Future<bool> updatePlan(SubscriptionPlanEntity plan) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final saved = await _repository.updatePlan(plan);
      await loadAllPlans();
      await loadActivePlans();
      state = state.copyWith(isSaving: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  // ✅ Toggle plan status
  Future<bool> togglePlanStatus(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.togglePlanStatus(id);
      await loadAllPlans();
      await loadActivePlans();
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ✅ Delete plan
  Future<bool> deletePlan(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deletePlan(id);
      await loadAllPlans();
      await loadActivePlans();
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}