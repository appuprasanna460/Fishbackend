// lib/features/subscription_plan/data/repositories/subscription_plan_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/renewal_request_entity.dart';

class SubscriptionPlanRepository {
  final Dio _dio;

  SubscriptionPlanRepository() : _dio = DioClient().dio;

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<SubscriptionPlanEntity> _parsePlanList(dynamic responseData) {
    final List<dynamic> dataList = responseData is List
        ? responseData
        : responseData is Map<String, dynamic>
            ? [responseData]
            : [];
    return dataList
        .map((e) => SubscriptionPlanEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Subscription Plans (CRUD for Super Admin) ─────────────────────────────

  Future<List<SubscriptionPlanEntity>> getActivePlans() async {
    try {
      final response = await _dio.get(ApiConstants.subscriptionPlansActive);
      return _parsePlanList(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load active plans');
    }
  }

  Future<List<SubscriptionPlanEntity>> getAllPlans() async {
    try {
      final response = await _dio.get(ApiConstants.subscriptionPlansAll);
      return _parsePlanList(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load plans');
    }
  }

  Future<SubscriptionPlanEntity> createPlan(
      SubscriptionPlanEntity plan) async {
    try {
      final response = await _dio.post(
        ApiConstants.subscriptionPlans,
        data: plan.toJson(),
      );
      return SubscriptionPlanEntity.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create plan');
    }
  }

  Future<SubscriptionPlanEntity> updatePlan(
      SubscriptionPlanEntity plan) async {
    try {
      final url =
          ApiConstants.subscriptionPlanById.replaceAll('{id}', plan.id ?? '');
      final response = await _dio.put(url, data: plan.toJson());
      return SubscriptionPlanEntity.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update plan');
    }
  }

  Future<void> togglePlanStatus(String id) async {
    try {
      final url = ApiConstants.subscriptionPlanToggle.replaceAll('{id}', id);
      await _dio.patch(url);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to toggle status');
    }
  }

  Future<void> deletePlan(String id) async {
    try {
      final url =
          ApiConstants.subscriptionPlanById.replaceAll('{id}', id);
      await _dio.delete(url);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete plan');
    }
  }

  // ── Subscription Lifecycle ────────────────────────────────────────────────

  /// GET /api/subscription/my — current user's subscription + pending renewal
  Future<SubscriptionEntity> getMySubscription() async {
    try {
      final response = await _dio.get(ApiConstants.mySubscription);
      return SubscriptionEntity.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load subscription');
    }
  }

  /// GET /api/subscription/plans — active plans for renewal selection
  Future<List<SubscriptionPlanEntity>> getActivePlansForRenewal() async {
    try {
      final response = await _dio.get(ApiConstants.subscriptionActivePlans);
      return _parsePlanList(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load plans for renewal');
    }
  }

  /// POST /api/subscription/renewal — create a renewal request
  Future<void> createRenewalRequest(String planId) async {
    try {
      await _dio.post(ApiConstants.createRenewalRequest,
          data: {'planId': planId});
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to submit renewal request');
    }
  }

  /// GET /api/subscription/renewal/status — user's latest renewal request status
  Future<RenewalRequestEntity?> getMyRenewalStatus() async {
    try {
      final response = await _dio.get(ApiConstants.renewalRequestStatus);
      final data = response.data['data'];
      if (data == null) return null;
      return RenewalRequestEntity.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load renewal status');
    }
  }

  /// GET /api/subscription/renewals — Super Admin: all pending renewal requests
  Future<List<RenewalRequestEntity>> getRenewalRequests() async {
    try {
      final response = await _dio.get(ApiConstants.adminRenewalRequests);
      final List<dynamic> data =
          response.data['data'] as List<dynamic>? ?? [];
      return data
          .map((e) =>
              RenewalRequestEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load renewal requests');
    }
  }

  /// POST /api/subscription/renewals/:id/approve
  Future<void> approveRenewal(String requestId) async {
    try {
      final url = ApiConstants.approveRenewalRequest
          .replaceAll('{id}', requestId);
      await _dio.post(url);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to approve renewal');
    }
  }

  /// POST /api/subscription/renewals/:id/reject
  Future<void> rejectRenewal(String requestId, {String? reason}) async {
    try {
      final url =
          ApiConstants.rejectRenewalRequest.replaceAll('{id}', requestId);
      await _dio.post(url, data: {'reason': reason ?? ''});
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to reject renewal');
    }
  }
}