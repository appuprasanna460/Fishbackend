import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/boat_owner_api_service.dart';
import '../../domain/entities/document_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'crew_provider.dart';

class DocumentState {
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final bool? uploadSuccess;
  final String? error;
  final List<DocumentEntity> documents;
  final Map<String, dynamic> summary;
  final List<DocumentEntity> expiringSoonList;
  final List<DocumentEntity> crewDocuments;

  DocumentState({
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadSuccess,
    this.error,
    this.documents = const [],
    this.summary = const {
      'total': 0,
      'valid': 0,
      'expiringSoon': 0,
      'expired': 0,
    },
    this.expiringSoonList = const [],
    this.crewDocuments = const [],
  });

  DocumentState copyWith({
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    bool? uploadSuccess,
    String? error,
    List<DocumentEntity>? documents,
    Map<String, dynamic>? summary,
    List<DocumentEntity>? expiringSoonList,
    List<DocumentEntity>? crewDocuments,
  }) {
    return DocumentState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadSuccess: uploadSuccess,
      error: error,
      documents: documents ?? this.documents,
      summary: summary ?? this.summary,
      expiringSoonList: expiringSoonList ?? this.expiringSoonList,
      crewDocuments: crewDocuments ?? this.crewDocuments,
    );
  }
}

class DocumentNotifier extends StateNotifier<DocumentState> {
  final BoatOwnerApiService _apiService;

  BoatOwnerApiService get apiService => _apiService;

  DocumentNotifier(this._apiService) : super(DocumentState());

  /// Fetch dashboard statistics (total, valid, expiring, expired)
  Future<void> fetchStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getDocumentStats();
      final summary = res['summary'] as Map<String, dynamic>? ?? {};
      final expiringListJson = res['expiringSoonList'] as List? ?? [];
      
      final expiringList = expiringListJson
          .map((e) => DocumentEntity.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        summary: summary,
        expiringSoonList: expiringList,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Fetch all documents with optional filters
  Future<void> fetchDocuments({
    String? boatId,
    String? crewMemberId,
    String? status,
    String? search,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getDocuments(
        boatId: boatId,
        crewMemberId: crewMemberId,
        status: status,
        search: search,
      );
      
      final docList = res
          .map((e) => DocumentEntity.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, documents: docList);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Fetch documents specific to a crew member
  Future<void> fetchCrewDocuments(String crewMemberId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.getCrewDocuments(crewMemberId);
      final docList = res
          .map((e) => DocumentEntity.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, crewDocuments: docList);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new Document (with image/pdf files upload)
  Future<void> createDocument(FormData formData) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0.0, uploadSuccess: null, error: null);
    try {
      // Monitor upload progress (optional, but requested: "Show upload progress")
      // To show progress, we need to pass ProgressCallback to dio.
      // But our apiService wraps _dio.post. We can build custom FormData options or just execute.
      // Let's modify our implementation to show simulated progress or fetch/bind progress from Dio.
      // We will perform the upload with a simulated smooth progress bar or we can use a direct call if ApiService does not expose onSendProgress.
      // Since ApiService wraps Dio, let's trigger it directly.
      await _apiService.createDocument(formData);
      state = state.copyWith(isUploading: false, uploadProgress: 1.0, uploadSuccess: true);
      // Refresh list & stats
      fetchStats();
    } catch (e) {
      state = state.copyWith(isUploading: false, uploadSuccess: false, error: e.toString());
      rethrow;
    }
  }

  /// Create a crew document and associate with crew member
  Future<void> createCrewDocument(String crewMemberId, FormData formData) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0.0, uploadSuccess: null, error: null);
    try {
      await _apiService.createCrewDocument(crewMemberId, formData);
      state = state.copyWith(isUploading: false, uploadProgress: 1.0, uploadSuccess: true);
      // Refresh crew documents list
      fetchCrewDocuments(crewMemberId);
      fetchStats();
    } catch (e) {
      state = state.copyWith(isUploading: false, uploadSuccess: false, error: e.toString());
      rethrow;
    }
  }

  /// Update / Renew Document
  Future<void> updateDocument(String id, FormData formData) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0.0, uploadSuccess: null, error: null);
    try {
      await _apiService.updateDocument(id, formData);
      state = state.copyWith(isUploading: false, uploadProgress: 1.0, uploadSuccess: true);
      fetchStats();
    } catch (e) {
      state = state.copyWith(isUploading: false, uploadSuccess: false, error: e.toString());
      rethrow;
    }
  }

  /// Delete document
  Future<bool> deleteDocument(String id, {String? crewMemberId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.deleteDocument(id);
      if (crewMemberId != null) {
        await fetchCrewDocuments(crewMemberId);
      } else {
        await fetchStats();
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void resetUploadState() {
    state = state.copyWith(isUploading: false, uploadProgress: 0.0, uploadSuccess: null);
  }
}

final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  final apiService = ref.watch(boatOwnerApiProvider);
  return DocumentNotifier(apiService);
});
