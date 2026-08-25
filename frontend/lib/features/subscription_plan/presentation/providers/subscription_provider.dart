// lib/features/subscription_plan/presentation/providers/subscription_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/subscription_plan_repository.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/entities/renewal_request_entity.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final subscriptionProvider =
    StateNotifierProvider.autoDispose<SubscriptionNotifier, SubscriptionState>(
        (ref) => SubscriptionNotifier());

// ─── State ────────────────────────────────────────────────────────────────────

class SubscriptionState {
  final SubscriptionEntity? subscription;
  final List<SubscriptionPlanEntity> activePlans;
  final List<RenewalRequestEntity> renewalRequests; // Super Admin view
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? successMessage;

  const SubscriptionState({
    this.subscription,
    this.activePlans = const [],
    this.renewalRequests = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.successMessage,
  });

  SubscriptionState copyWith({
    SubscriptionEntity? subscription,
    List<SubscriptionPlanEntity>? activePlans,
    List<RenewalRequestEntity>? renewalRequests,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SubscriptionState(
      subscription: subscription ?? this.subscription,
      activePlans: activePlans ?? this.activePlans,
      renewalRequests: renewalRequests ?? this.renewalRequests,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionPlanRepository _repo = SubscriptionPlanRepository();

  SubscriptionNotifier() : super(const SubscriptionState());

  /// Load current user's subscription details
  Future<void> loadMySubscription() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sub = await _repo.getMySubscription();
      state = state.copyWith(subscription: sub, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load active plans (for plan selection during renewal)
  Future<void> loadActivePlans() async {
    try {
      final plans = await _repo.getActivePlansForRenewal();
      state = state.copyWith(activePlans: plans);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Submit a renewal request
  Future<bool> submitRenewalRequest(String planId) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _repo.createRenewalRequest(planId);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Renewal request submitted! Awaiting admin approval.',
      );
      // Refresh subscription to show pending state
      await loadMySubscription();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Load all pending renewal requests (Super Admin)
  Future<void> loadRenewalRequests() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final requests = await _repo.getRenewalRequests();
      state = state.copyWith(renewalRequests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Approve a renewal request (Super Admin)
  Future<bool> approveRenewal(String requestId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.approveRenewal(requestId);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Renewal approved successfully.',
      );
      await loadRenewalRequests();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Reject a renewal request (Super Admin)
  Future<bool> rejectRenewal(String requestId, {String? reason}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.rejectRenewal(requestId, reason: reason);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Renewal request rejected.',
      );
      await loadRenewalRequests();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
