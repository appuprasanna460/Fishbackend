// lib/features/boat_owner/data/boat_owner_api_service.dart
//
// Central Dio wrapper for every /api/boat-owner endpoint.
// All methods throw on non-2xx so callers can catch a single exception type.

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class BoatOwnerApiService {
  final Dio _dio;

  BoatOwnerApiService(DioClient client) : _dio = client.dio;

  // ── Dashboard ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _dio.get(ApiConstants.boatOwnerDashboard);
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Bills ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getBills({
    String? boatId,
    String? fromDate,
    String? toDate,
    String? createdBy,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerBills,
      queryParameters: {
        if (boatId != null) 'boatId': boatId,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        if (createdBy != null) 'createdBy': createdBy,
        'page': page,
        'limit': limit,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBillById(String id) async {
    final res = await _dio.get('${ApiConstants.boatOwnerBills}/$id');
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Manual Ledger ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getLedgerSummary({
    String? boatId,
    String? fromDate,
    String? toDate,
  }) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerLedgerSummary,
      queryParameters: {
        if (boatId != null) 'boatId': boatId,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
      },
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLedgerEntries({
    String? boatId,
    String? type,
    String? category,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerLedger,
      queryParameters: {
        if (boatId != null) 'boatId': boatId,
        if (type != null) 'type': type,
        if (category != null) 'category': category,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        'page': page,
        'limit': limit,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createLedgerEntry(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.boatOwnerLedger, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLedgerEntry(
      String id, Map<String, dynamic> body) async {
    final res =
        await _dio.put('${ApiConstants.boatOwnerLedger}/$id', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteLedgerEntry(String id) async {
    await _dio.delete('${ApiConstants.boatOwnerLedger}/$id');
  }

  // ── Fishing Locations ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> saveFishingLocation(
      Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.boatOwnerFishingLocations, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFishingLocations({
    String? boatId,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerFishingLocations,
      queryParameters: {
        if (boatId != null) 'boatId': boatId,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        'page': page,
        'limit': limit,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteFishingLocation(String id) async {
    await _dio.delete('${ApiConstants.boatOwnerFishingLocations}/$id');
  }

  // ── Profile ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get(ApiConstants.boatOwnerProfile);
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Crew Management ────────────────────────────────────────────────────────
  Future<List<dynamic>> getCrew({
    String? role,
    bool? isAvailable,
    String? search,
  }) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerCrew,
      queryParameters: {
        if (role != null) 'role': role,
        if (isAvailable != null) 'isAvailable': isAvailable,
        if (search != null) 'search': search,
      },
    );
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getCrewById(String id) async {
    final res = await _dio.get('${ApiConstants.boatOwnerCrew}/$id');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createCrew(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.boatOwnerCrew, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCrew(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConstants.boatOwnerCrew}/$id', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleAvailability(String id) async {
    final res = await _dio.put('${ApiConstants.boatOwnerCrew}/$id/availability');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteCrew(String id) async {
    await _dio.delete('${ApiConstants.boatOwnerCrew}/$id');
  }

  Future<List<dynamic>> getAvailableCaptains() async {
    final res = await _dio.get(ApiConstants.boatOwnerCaptains);
    return res.data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getAvailableCrew() async {
    final res = await _dio.get(ApiConstants.boatOwnerAvailableCrew);
    return res.data['data'] as List<dynamic>;
  }

  // ── Voyage Management ──────────────────────────────────────────────────────
  Future<List<dynamic>> getVoyages({
    String? status,
    String? boatId,
    String? dateRange,
    String? search,
  }) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerVoyages,
      queryParameters: {
        if (status != null) 'status': status,
        if (boatId != null) 'boatId': boatId,
        if (dateRange != null) 'dateRange': dateRange,
        if (search != null) 'search': search,
      },
    );
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getVoyageById(String id) async {
    final res = await _dio.get('${ApiConstants.boatOwnerVoyages}/$id');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createVoyage(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.boatOwnerVoyages, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVoyage(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConstants.boatOwnerVoyages}/$id', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVoyageStatus(String id, String status) async {
    final res = await _dio.put(
      '${ApiConstants.boatOwnerVoyages}/$id/status',
      data: {'status': status},
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteVoyage(String id) async {
    await _dio.delete('${ApiConstants.boatOwnerVoyages}/$id');
  }

  Future<Map<String, dynamic>> getVoyageStats() async {
    final res = await _dio.get(ApiConstants.boatOwnerVoyageStats);
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Haul Management ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> startHaul(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.boatOwnerHauls, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getHauls({
    String? voyageId,
    String? status,
    String? fishingGround,
    String? dateRange,
  }) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerHauls,
      queryParameters: {
        if (voyageId != null) 'voyageId': voyageId,
        if (status != null) 'status': status,
        if (fishingGround != null) 'fishingGround': fishingGround,
        if (dateRange != null) 'dateRange': dateRange,
      },
    );
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>?> getActiveHaul(String voyageId) async {
    try {
      final res = await _dio.get(
        ApiConstants.boatOwnerActiveHaul,
        queryParameters: {'voyageId': voyageId},
      );
      return res.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getHaulById(String id) async {
    final res = await _dio.get('${ApiConstants.boatOwnerHauls}/$id');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> stopHaul(String id) async {
    final res = await _dio.put('${ApiConstants.boatOwnerHauls}/$id/stop');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateGpsTrack(String haulId, Map<String, dynamic> location) async {
    final res = await _dio.put('${ApiConstants.boatOwnerHauls}/$haulId/gps', data: location);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getRecentHauls({int limit = 5}) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerRecentHauls,
      queryParameters: {'limit': limit},
    );
    return res.data['data'] as List<dynamic>;
  }

  // ── Catch Management ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createCatch(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.boatOwnerCatches, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCatchesByHaul(String haulId) async {
    final res = await _dio.get('${ApiConstants.boatOwnerCatchesByHaul}/$haulId');
    return res.data['data'] as List<dynamic>;
  }

  Future<bool> hasPendingCatch(String haulId) async {
    try {
      final res = await _dio.get('${ApiConstants.boatOwnerPendingCatch}/$haulId');
      return (res.data['data']?['hasPendingCatch'] ?? false) as bool;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getCatchById(String id) async {
    final res = await _dio.get('${ApiConstants.boatOwnerCatches}/$id');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCatch(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConstants.boatOwnerCatches}/$id', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteCatch(String id) async {
    await _dio.delete('${ApiConstants.boatOwnerCatches}/$id');
  }

  // ── Fishing Grounds ────────────────────────────────────────────────────────
  Future<List<dynamic>> getFishingGrounds() async {
    final res = await _dio.get(ApiConstants.boatOwnerFishingGrounds);
    return res.data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getFavouriteGrounds() async {
    final res = await _dio.get(ApiConstants.boatOwnerFavouriteGrounds);
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> toggleFavouriteGround(String id) async {
    final res = await _dio.put('${ApiConstants.boatOwnerFishingGrounds}/$id/favourite');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getGroundHistory({
    String? search,
    String? dateRange,
  }) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerGroundHistory,
      queryParameters: {
        if (search != null) 'search': search,
        if (dateRange != null) 'dateRange': dateRange,
      },
    );
    return res.data['data'] as List<dynamic>;
  }

  // ── GPS Tracks ─────────────────────────────────────────────────────────────
  Future<List<dynamic>> getGpsTracks({
    String? voyageId,
    String? dateRange,
  }) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerGpsTracks,
      queryParameters: {
        if (voyageId != null) 'voyageId': voyageId,
        if (dateRange != null) 'dateRange': dateRange,
      },
    );
    return res.data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getTracksByVoyage(String voyageId) async {
    final res = await _dio.get('${ApiConstants.boatOwnerGpsTracksByVoyage}/$voyageId');
    return res.data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getTracksByHaul(String haulId) async {
    final res = await _dio.get('${ApiConstants.boatOwnerGpsTracksByHaul}/$haulId');
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getTrackSummary(String voyageId) async {
    final res = await _dio.get('${ApiConstants.boatOwnerGpsTrackSummary}/$voyageId');
    return res.data['data'] as Map<String, dynamic>;
  }

  /// Returns list of voyage history summaries with trackPreview points.
  /// [period] can be 'all', 'today', 'week', or 'month'.
  Future<List<dynamic>> getGpsTrackHistory({
    String period = 'all',
    String? boatId,
  }) async {
    final res = await _dio.get(
      ApiConstants.boatOwnerGpsTrackHistory,
      queryParameters: {
        if (period != 'all') 'period': period,
        if (boatId != null) 'boatId': boatId,
      },
    );
    return res.data['data'] as List<dynamic>;
  }

  /// Returns full voyage detail including complete GPS track array for map view.
  Future<Map<String, dynamic>> getVoyageTrackDetail(String voyageId) async {
    final res = await _dio.get(
      '${ApiConstants.boatOwnerGpsVoyageDetail}/$voyageId/detail',
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Voyage Dashboard ───────────────────────────────────────────────────────
  /// Returns catch summary for a voyage: totalWeight, bySpecies[], byHaul[].
  Future<Map<String, dynamic>> getCatchSummaryByVoyage(String voyageId) async {
    final res = await _dio.get('${ApiConstants.boatOwnerVoyageCatchSummary}/$voyageId/catch-summary');
    return res.data['data'] as Map<String, dynamic>;
  }

  /// Returns all daily expense records for a voyage plus totals.
  Future<Map<String, dynamic>> getVoyageExpenses(String voyageId) async {
    final res = await _dio.get('${ApiConstants.boatOwnerVoyageExpenses}/$voyageId');
    return res.data['data'] as Map<String, dynamic>;
  }

  /// Creates or updates the expense record for a specific voyage date (upsert).
  Future<Map<String, dynamic>> saveVoyageExpenses(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.boatOwnerVoyageExpenses, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Return Entry ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getReturnEntry(String voyageId) async {
    try {
      final res = await _dio.get('${ApiConstants.boatOwnerReturnEntry}/$voyageId/return-entry');
      return res.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> saveReturnEntry(String voyageId, Map<String, dynamic> body) async {
    final res = await _dio.post('${ApiConstants.boatOwnerReturnEntry}/$voyageId/return-entry', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Landing Entry ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getLandingEntry(String voyageId) async {
    try {
      final res = await _dio.get('${ApiConstants.boatOwnerLandingEntry}/$voyageId/landing-entry');
      return res.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> saveLandingEntry(String voyageId, Map<String, dynamic> body) async {
    final res = await _dio.post('${ApiConstants.boatOwnerLandingEntry}/$voyageId/landing-entry', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Voyage Checklist Details ───────────────────────────────────────────────
  Future<Map<String, dynamic>?> getChecklistDetails(String voyageId) async {
    try {
      final res = await _dio.get('${ApiConstants.boatOwnerChecklistDetails}/$voyageId/checklist-details');
      return res.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> saveChecklistDetails(String voyageId, Map<String, dynamic> body) async {
    final res = await _dio.post('${ApiConstants.boatOwnerChecklistDetails}/$voyageId/checklist-details', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Document Management Module ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getDocumentStats() async {
    final res = await _dio.get(ApiConstants.documentsStats);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getDocuments({
    String? boatId,
    String? crewMemberId,
    String? status,
    String? search,
  }) async {
    final res = await _dio.get(
      ApiConstants.documents,
      queryParameters: {
        if (boatId != null) 'boatId': boatId,
        if (crewMemberId != null) 'crewMemberId': crewMemberId,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
      },
    );
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getDocumentById(String id) async {
    final res = await _dio.get('${ApiConstants.documents}/$id');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createDocument(FormData body) async {
    final res = await _dio.post(ApiConstants.documents, data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDocument(String id, FormData body) async {
    final res = await _dio.put('${ApiConstants.documents}/$id', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteDocument(String id) async {
    await _dio.delete('${ApiConstants.documents}/$id');
  }

  Future<List<dynamic>> getCrewDocuments(String crewMemberId) async {
    final res = await _dio.get('${ApiConstants.documents}/crew/$crewMemberId/documents');
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createCrewDocument(String crewMemberId, FormData body) async {
    final res = await _dio.post('${ApiConstants.documents}/crew/$crewMemberId/documents', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Financial Management ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getFinancialDashboard({
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    final res = await _dio.get(
      ApiConstants.financialDashboard,
      queryParameters: {
        if (period != null) 'period': period,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getFinancialVoyages() async {
    final res = await _dio.get(ApiConstants.financialVoyages);
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getVoyageFinancialSummary(String voyageId) async {
    final res = await _dio.get('${ApiConstants.financialVoyages}/$voyageId');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> updateCatchRates(String voyageId, List<Map<String, dynamic>> rates) async {
    await _dio.put('${ApiConstants.financialVoyages}/$voyageId/income', data: {'rates': rates});
  }

  Future<Map<String, dynamic>> addOtherIncome(String voyageId, String name, double amount) async {
    final res = await _dio.post(
      '${ApiConstants.financialVoyages}/$voyageId/other-income',
      data: {'incomeName': name, 'amount': amount},
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteOtherIncome(String voyageId, String id) async {
    await _dio.delete('${ApiConstants.financialVoyages}/$voyageId/other-income/$id');
  }

  Future<void> updateExpenses(String voyageId, List<Map<String, dynamic>> expenses) async {
    await _dio.put('${ApiConstants.financialVoyages}/$voyageId/expenses', data: {'expenses': expenses});
  }

  Future<Map<String, dynamic>> addCustomExpense(String voyageId, Map<String, dynamic> body) async {
    final res = await _dio.post('${ApiConstants.financialVoyages}/$voyageId/custom-expenses', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteCustomExpense(String voyageId, String id) async {
    await _dio.delete('${ApiConstants.financialVoyages}/$voyageId/custom-expenses/$id');
  }

  Future<void> updateCrewSettlement(String voyageId, List<Map<String, dynamic>> settlements) async {
    await _dio.put('${ApiConstants.financialVoyages}/$voyageId/crew-settlement', data: {'settlements': settlements});
  }

  // ── Team / Company Users ───────────────────────────────────────────────────
  Future<List<dynamic>> getTeam() async {
    final res = await _dio.get('/api/boat-owner/team');
    return res.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTeamMember(Map<String, dynamic> body) async {
    final res = await _dio.post('/api/boat-owner/team', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTeamMember(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('/api/boat-owner/team/$id', data: body);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteTeamMember(String id) async {
    await _dio.delete('/api/boat-owner/team/$id');
  }

  Future<Map<String, dynamic>> toggleTeamMemberStatus(String id) async {
    final res = await _dio.patch('/api/boat-owner/team/$id/toggle-status');
    return res.data['data'] as Map<String, dynamic>;
  }
}
